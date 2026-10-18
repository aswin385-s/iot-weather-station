% Alert_Trigger.m
% IoT-Based Weather Station Using ESP32 and Cloud Dashboard
%
% PURPOSE
%   Reads the latest temperature (Field 1) from ThingSpeak channel 3532891 and,
%   if it is greater than 35 C, asks the ThingSpeak Alerts API to send an email.
%
% SETUP (edit the values in the CONFIGURATION section)
%   1. channelID      : 3532891 (already set). Field 1 = temperature, Field 2 = humidity.
%   2. readApiKey     : NOT needed, because the channel is public. Leave it as "".
%                       Only if the channel is made private, paste its Read API key
%                       (ThingSpeak > Channels > My Channels > your channel > API Keys).
%   3. alertApiKey    : your ThingSpeak Alerts API key. Get it at
%                       ThingSpeak > Account > My Profile > "Alerts API Key".
%                       Keep it private; never share or publish it.
%   4. The alert email goes to the email address of the ThingSpeak account
%      that owns the Alerts API key.
%
% IMPORTANT NOTES
%   - The script checks ONCE each time it is run. It does not monitor continuously.
%     Run it again, or schedule it (e.g. MATLAB Online/ThingSpeak scheduled task).
%   - A successful alert request only means ThingSpeak accepted the request.
%     It does not prove the email reached the inbox. Check the inbox and use
%     Alert_History_Verification.m to see the recorded status.
%   - Duplicate-alert prevention: after an accepted alert, the time is saved in
%     a file (stateFile). Runs within cooldownMinutes of that time send no new alert.
%     Limitations: the file lives in the current MATLAB folder; if it is deleted,
%     the folder changes, or the script runs on another machine/session without
%     this file, the cooldown is lost and an alert may be sent again.
%   - This script has not been executed by the author of this file; test it with
%     your own keys before relying on it.

%% CONFIGURATION
channelID       = 3532891;                  % ThingSpeak channel ID
readApiKey      = "";                       % leave empty for a public channel
alertApiKey     = "YOUR_ALERTS_API_KEY";    % placeholder: replace with your own key
thresholdC      = 35;                       % alert when temperature > 35 C
cooldownMinutes = 15;                       % minimum gap between alerts
stateFile       = "last_alert_state.mat";   % stores the time of the last alert

alertUrl     = "https://api.thingspeak.com/alerts/send";
alertSubject = "Weather Station: High Temperature";

%% 1. READ THE LATEST TEMPERATURE FROM FIELD 1
try
    if strlength(readApiKey) > 0
        [temperature, readTime] = thingSpeakRead(channelID, ...
            'Fields', 1, 'NumPoints', 1, 'ReadKey', char(readApiKey));
    else
        [temperature, readTime] = thingSpeakRead(channelID, ...
            'Fields', 1, 'NumPoints', 1);
    end
catch ME
    fprintf("ERROR: could not read channel %d: %s\n", channelID, ME.message);
    return;
end

%% 2. CHECK THAT THE READING IS VALID
if isempty(temperature) || ~isnumeric(temperature) || ~isscalar(temperature) ...
        || isnan(temperature) || isinf(temperature)
    disp("No valid temperature reading available. No alert request sent.");
    return;
end

fprintf("Latest temperature (Field 1): %.2f C", temperature);
if ~isempty(readTime)
    fprintf("  (entry time: %s)", string(readTime));
end
fprintf("\n");

%% 3. COMPARE WITH THE THRESHOLD
if temperature <= thresholdC
    fprintf("Result: %.2f C is within the %g C limit. No alert request sent.\n", ...
        temperature, thresholdC);
    return;
end
fprintf("Result: %.2f C is above the %g C limit.\n", temperature, thresholdC);

%% 4. COOLDOWN CHECK (avoid repeated alerts on every run)
nowUtc = datetime("now", "TimeZone", "UTC");
if isfile(stateFile)
    try
        S = load(stateFile, "lastAlertTime");
        minutesSince = minutes(nowUtc - S.lastAlertTime);
        if minutesSince < cooldownMinutes
            fprintf("Cooldown active: last alert request was %.1f min ago (limit %d min). No new alert request sent.\n", ...
                minutesSince, cooldownMinutes);
            return;
        end
    catch
        disp("Warning: could not read the cooldown file. Continuing without cooldown.");
    end
end

%% 5. CHECK THAT THE ALERTS API KEY HAS BEEN SET
if strlength(alertApiKey) == 0 || alertApiKey == "YOUR_ALERTS_API_KEY"
    disp("Alerts API key is still the placeholder. Set alertApiKey and run again. No alert request sent.");
    return;
end

%% 6. SEND THE ALERT REQUEST (ThingSpeak Alerts API: POST /alerts/send)
alertBody = sprintf( ...
    "Warning! Temperature is %.2f C, above the %g C limit.", ...
    temperature, thresholdC);

options = weboptions( ...
    "HeaderFields", ["ThingSpeak-Alerts-API-Key", alertApiKey], ...
    "Timeout", 30);

try
    webwrite(alertUrl, "subject", alertSubject, "body", alertBody, options);
    lastAlertTime = nowUtc;
    save(stateFile, "lastAlertTime");
    disp("Alert request accepted by ThingSpeak.");
    disp("This does NOT prove the email was delivered. Check your inbox and run Alert_History_Verification.m.");
catch ME
    % webwrite throws an error for HTTP errors (e.g. 401 invalid key, 429 too many requests)
    fprintf("Alert request FAILED: %s\n", ME.message);
    if contains(ME.message, "401") || contains(ME.identifier, "401")
        disp("Hint: the Alerts API key appears to be invalid.");
    end
    disp("No alert is recorded as sent by this script.");
end
