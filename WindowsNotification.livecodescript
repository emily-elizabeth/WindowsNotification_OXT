script "WindowsNotification"

-- Standalone LiveCode Script library for posting toast notifications on Windows 10/11.
-- Add these handlers to your main stack script, or place them in a backscript.
--
-- API is intentionally identical to the macOS UNUserNotification and NSUserNotification
-- LCB extensions so that call sites require no platform checks.
--
-- Usage:
--   Call RequestNotificationAuthorization once at startup (no-op on Windows, provided
--   for cross-platform compatibility), then call PostUserNotification as needed.


-- xmlEscape
-- Escapes the five XML special characters in a string so it is safe to embed in the
-- toast XML payload. & must be replaced first to avoid double-escaping.
function xmlEscape pText
   replace "&"  with "&amp;"  in pText
   replace "<"  with "&lt;"   in pText
   replace ">"  with "&gt;"   in pText
   replace quote with "&quot;" in pText
   replace "'"  with "&apos;" in pText
   return pText
end xmlEscape


-- RequestNotificationAuthorization
-- No-op provided for call-site compatibility with the macOS UNUserNotification and
-- NSUserNotification extensions. Windows 10/11 allow toast notifications by default
-- without a runtime permission request. Users can disable them in:
-- Settings -> System -> Notifications
on RequestNotificationAuthorization
   -- no-op on Windows
end RequestNotificationAuthorization


-- PostUserNotification
-- Posts a toast notification on Windows 10/11 via the WinRT Toast Notification API.
-- Delegates to PostWindowsNotification which handles XML building and PowerShell execution.
--
-- pTitle           - the bold heading line of the notification (required)
-- pSubTitle        - secondary heading below the title (pass empty to omit)
-- pInformativeText - body text of the notification (pass empty to omit)
-- pIdentifier      - ignored on Windows, accepted for cross-platform API compatibility
on PostUserNotification pTitle, pSubTitle, pInformativeText, pIdentifier
   if the platform is "win32" then
      PostWindowsNotification pTitle, pSubTitle, pInformativeText
   end if
end PostUserNotification


-- PostWindowsNotification
-- Builds a PowerShell .ps1 script and executes it to display a Windows toast notification
-- via the WinRT Toast Notification API. Notifications are only shown when the app is
-- in the background -- Windows suppresses toasts from the currently focused application.
--
-- The script is written to the system temp folder as lcnotify.ps1 and overwritten on
-- each call. PowerShell is invoked with -WindowStyle Hidden to suppress the console
-- window and -ExecutionPolicy Bypass to ensure the unsigned script always runs.
--
-- pTitle           - the bold heading line of the notification (required)
-- pSubTitle        - secondary heading below the title (pass empty to omit)
-- pInformativeText - body text of the notification (pass empty to omit)
on PostWindowsNotification pTitle, pSubTitle, pInformativeText
   -- Build the XML text nodes, omitting subtitle and body if empty
   local tTextNodes
   put "<text>" & xmlEscape(pTitle) & "</text>" into tTextNodes
   if pSubTitle is not empty then
      put tTextNodes & "<text>" & xmlEscape(pSubTitle) & "</text>" into tTextNodes
   end if
   if pInformativeText is not empty then
      put tTextNodes & "<text>" & xmlEscape(pInformativeText) & "</text>" into tTextNodes
   end if
   
   -- Compose the full toast XML.
   -- The template attribute value uses the quote constant so no additional
   -- escaping is needed when the XML is passed to PowerShell's LoadXml() method.
   local tXml
   put "<toast><visual><binding template=" & quote & "ToastGeneric" & quote & ">" & tTextNodes & "</binding></visual></toast>" into tXml
   
   -- Use the app name as the toast notifier ID so Windows associates the notification
   -- with this app in the Action Center. Falls back to a generic name if not set.
   local tAppName
   put the cREVAppName of this stack into tAppName
   if tAppName is empty then
      put "OpenXTalk Application" into tAppName
   end if
   
   -- Build the PowerShell script content.
   -- Written to a .ps1 file rather than passed via -Command to avoid all
   -- command-line quoting issues. The file content is written verbatim.
   local tScript
   put "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime] | Out-Null" & cr into tScript
   put "[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType=WindowsRuntime] | Out-Null" & cr after tScript
   put "$xml = New-Object Windows.Data.Xml.Dom.XmlDocument" & cr after tScript
   put "$xml.LoadXml(" & quote & tXml & quote & ")" & cr after tScript
   put "$toast = [Windows.UI.Notifications.ToastNotification]::new($xml)" & cr after tScript
   --put "[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier(" & quote & tAppName & quote & ").Show($toast)" after tScript
   put "[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier(" & quote & "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe" & quote & ").Show($toast)" after tScript
   
   -- Write the script to the system temp folder and execute it
   local tScriptPath
   put specialFolderPath("Temporary") & "/lcnotify.ps1" into tScriptPath
   put tScript into url ("file:" & tScriptPath)
   get shell("powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File " & quote & tScriptPath & quote)
end PostWindowsNotification
