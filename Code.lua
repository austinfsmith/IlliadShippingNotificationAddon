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
  if isCurrentlyProcessing then
    return;
  end

	t = os.date("*t");
	if t.hour ~= 23 and Settings.Defer == true then
		LogDebug("Deferring shipment notifications until 11PM.");
		return;
	end

	isCurrentlyProcessing = true;
	LogDebug("Checking for shipped loans.");

  local query = [[SELECT t.TransactionNumber FROM Transactions t
                WHERE t.TransactionStatus = 'Request Sent'
                AND t.RequestType = 'Loan'
				        AND t.DueDate IS NOT NULL
                AND t.%s IS NULL;]]

  local connection;
  connection = CreateManagedDatabaseConnection();
  connection.QueryString = string.format(query,Settings.ItemField);
  local transactions = connection:Execute();

  for i = 0, transactions.Rows.Count - 1 do
    local tn = transactions.Rows:get_Item(i):get_Item(0)
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
  LogDebug("Setting Shipment Date for Transaction "..tn.." based on due date.");
  local shipdate = "Shipped on " .. os.date("%m/%d/%Y");
  SetFieldValue("Transaction", Settings.ItemField, shipdate);
  SaveDataSource("Transaction");
end
