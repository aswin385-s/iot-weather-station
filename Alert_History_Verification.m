% Alert_History_Verification.m
% IoT-Based Weather Station Using ESP32 and Cloud Dashboard
%
% PURPOSE
%   Retrieves existing alert records from the ThingSpeak Alerts API
%   (GET https://api.thingspeak.com/alerts/history) and displays them.
%   This script only READS history. It does NOT send an alert email.
%
% SETUP
%   alertApiKey : your ThingSpeak Alerts API key (placeholder below). Get it at
%                 ThingSpeak > Account > My Profile > "Alerts API Key".
%                 Keep it private; never share or publish it.
%   Project reference: channel 3532891, Field 1 = temperature, Field 2 = humidity,
%   alert when temperature > 35 C (the channel itself is not needed for this call).
%
% IMPORTANT NOTE ABOUT THE "status" COLUMN
%   A status of "sent" means the alert system recorded the send operation.
%   It does NOT independently prove that the email arrived in the recipient's
%   inbox (it could still be filtered, delayed or rejected downstream).
%   Confirm delivery by checking the inbox.
%
%   This script has not been executed by the author of this file; test it with
%   your own key.

%% CONFIGURATION
alertApiKey = "YOUR_ALERTS_API_KEY";   % placeholder: replace with your own key
url = "https://api.thingspeak.com/alerts/history";

if strlength(alertApiKey) == 0 || alertApiKey == "YOUR_ALERTS_API_KEY"
    disp("Alerts API key is still the placeholder. Set alertApiKey and run again.");
    return;
end

%% 1. REQUEST THE HISTORY
options = weboptions( ...
    "HeaderFields", ["ThingSpeak-Alerts-API-Key", alertApiKey], ...
    "Timeout", 30);

try
    result = webread(url, options);
catch ME
    fprintf("Alert-history request FAILED: %s\n", ME.message);
    if contains(ME.message, "401") || contains(ME.identifier, "401")
        disp("Hint: the Alerts API key appears to be invalid.");
    end
    return;
end

%% 2. HANDLE EMPTY OR UNEXPECTED RESPONSES
if isempty(result)
    disp("The request succeeded but the alert history is empty (no alerts recorded).");
    return;
end
if ~isstruct(result)
    disp("Unexpected response format (not a structure). Raw response:");
    disp(result);
    return;
end

%% 3. CONVERT TO A TABLE
try
    history = struct2table(result);
catch ME
    fprintf("Could not convert the response to a table: %s\n", ME.message);
    disp("Raw response:");
    disp(result);
    return;
end

if height(history) == 0
    disp("The alert history is empty (no alerts recorded).");
    return;
end

%% 4. SHOW THE AVAILABLE COLUMNS (only those that exist in the response)
wanted    = ["requestedAt", "sentAt", "subject", "message", "body", "status"];
available = wanted(ismember(wanted, string(history.Properties.VariableNames)));

if isempty(available)
    disp("None of the expected columns were found. Columns returned:");
    disp(string(history.Properties.VariableNames));
    return;
end

fprintf("Alert history: %d record(s) returned.\n\n", height(history));
disp(history(:, cellstr(available)));

%% 5. SUMMARY OF STATUSES
if ismember("status", available)
    statuses = string(history.status);
    [names, ~, idx] = unique(statuses);
    counts = accumarray(idx, 1);
    disp("Summary by status:");
    for k = 1:numel(names)
        fprintf("  %s: %d\n", names(k), counts(k));
    end
    disp("Note: 'sent' means the send operation was recorded; it does not prove inbox delivery.");
else
    disp("No 'status' column was returned, so no status summary is available.");
end
