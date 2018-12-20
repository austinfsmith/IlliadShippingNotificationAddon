-- Shipping Notification addon
-- Austin Smith
-- University of Maryland Libraries


luanet.load_assembly("System.Data");

local types = {};

types["SqlDbType"] = luanet.import_type("System.Data.SqlDbType");

local Settings = {};
Settings.Defer = GetSetting("DeferProcessing");
Settings.SendEmail = GetSetting("SendEmail");
Settings.EmailName = GetSetting("EmailName");
Settings.ItemField = GetSetting("ItemField");

local isCurrentlyProcessing = false;

function Init()
  LogDebug("Initializing Shipping Notification addon.");
	RegisterSystemEventHandler("SystemTimerElapsed", "CheckShippedItems");
end

function CheckShippedItems()
	t = os.date("*t");
	if t.hour ~= 23 and Settings.Defer == true then
		LogDebug("Deferring shipment notifications until 11PM. Current time: ".. t.hour..":"..t.min)
		return;
	end

	if isCurrentlyProcessing then
		return;
	end

	isCurrentlyProcessing = true;
	LogDebug("Checking for shipped loans.");

  local query = "SELECT t.TransactionNumber FROM Transactions t " ..
                "WHERE t.TransactionStatus = 'Request Sent' " ..
                "AND t.RequestType = 'Loan' " ..
				        "AND t.DueDate IS NOT NULL " ..
                "AND t." .. Settings.ItemField .. " IS NULL";

  local connection;
  connection = CreateManagedDatabaseConnection();
  connection.QueryString = query;
  local transactions = connection:Execute();

  for i = 0, transactions.Rows.Count - 1 do
    local tn = transactions.Rows:get_Item(i):get_Item(0)
    LogDebug("Setting Shipment Date for Transaction "..tn.." based on due date.");
    ProcessDataContexts("TransactionNumber", tn, "SetShippedDate")
    if Settings.SendEmail == true then
      LogDebug("Sending notification email for Transaction "..tn);
      ExecuteCommand("SendTransactionNotification", {tn, Settings.EmailName});
    end
  end
  connection:Dispose();
  isCurrentlyProcessing = false;
end

function SetShippedDate()
  local shipdate = "Shipped on " .. os.date("%m/%d/%Y");
  SetFieldValue("Transaction", Settings.ItemField, shipdate);
  SaveDataSource("Transaction");
end

function OnError(e)
    if e == nil then
        LogDebug("OnError supplied a nil error");
        return;
    end

    if not e.GetType then
        -- Not a .NET type
        -- Attempt to log value
        pcall(function ()
            LogDebug(e);
        end);
        return;
    else
        if not e.Message then
            LogDebug(e:ToString());
            return;
        end
    end

    local message = TraverseError(e);

    if message == nil then
        message = "Unspecified Error";
    end

	LogDebug("An error occurred in the Shipping Notification addon: " .. message);
end

-- Recursively logs exception messages and returns the innermost message to caller
function TraverseError(e)
    if not e.GetType then
        -- Not a .NET type
        return nil;
    else
        if not e.Message then
            -- Not a .NET exception
            LogDebug(e:ToString());
            return nil;
        end
    end

    LogDebug(e.Message);

    if e.InnerException then
        return TraverseError(e.InnerException);
    else
        return e.Message;
    end
end
