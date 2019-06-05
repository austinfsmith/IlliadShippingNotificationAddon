# IlliadShippingNotificationAddon

This is an ILLiad server addon which sends a notification email when a lender marks a loan request "shipped." Specifically, it looks for loan requests in a status of Request Sent which have a due date defined - this is as good a proxy for the OCLC status update as currently exists.

## Configuration

The addon has the following settings:

DeferProcessing - If set to True, the addon will not check any requests until 11PM local time. This should give some time for items mistakenly marked Shipped to be caught & corrected before an erroneous email is sent.

SendEmail - If set to False, no email will be sent (but the shipment date will still be added to the field defined in ItemField).

EmailName - Name of the email template to send. This must be defined in the Customization Manager. The same email will be sent for all requests (regardless of where they're coming from), so you'll want to be careful with the wording.

ItemField - Name of the field in the Transactions table to store the shipment date in. This exists so that these dates can be displayed in the Outstanding Requests table in the patron's ILL account, if desired.
