-- WindowsNotification.livecodescript
-- Companion LiveCode Script handler for the WindowsNotification LCB extension.
-- Add this handler to your main stack script.
--
-- Called automatically by PostUserNotification when running on Windows 10/11.
-- Builds a PowerShell .ps1 script and executes it to display a toast notification
-- via the Windows Runtime (WinRT) Toast Notification API.
--
-- Parameters:
--   pTitle           - the bold heading line of the notification (required)
--   pSubTitle        - secondary heading below the title (empty to omit)
--   pInformativeText - body text of the notification (empty to omit)

on PostWindowsNotification pTitle, pSubTitle, pInformativeText
   -- xmlEscape
   -- Escapes the five XML special characters so text is safe to embed in the
   -- toast XML payload. & must be replaced first to avoid double-escaping.
   function xmlEscape pText
      replace "&"  with "&amp;"  in pText
      replace "<"  with "&lt;"   in pText
      replace ">"  with "&gt;"   in pText
      replace quote with "&quot;" in pText
      replace "'"  with "&apos;" in pText
      return pText
   end xmlEscape

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
   -- Single quotes are used for XML attribute values so no additional escaping
   -- is needed when the XML is passed to PowerShell's LoadXml() method.
   local tXml
   put "<toast><visual><binding template='ToastGeneric'>" & tTextNodes & "</binding></visual></toast>" into tXml

   -- Use the application name as the toast notifier ID so Windows associates
   -- the notification with this app in the Action Center.
   local tAppName
   put the cREVAppName of this stack into tAppName
   if tAppName is empty then
      put "LiveCode Application" into tAppName
   end if

   -- Build the PowerShell script content.
   -- Written to a .ps1 file rather than passed via -Command to avoid all
   -- command-line quoting issues. The file content is written verbatim.
   local tScript
   put "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime] | Out-Null" & cr into tScript
   put "[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType=WindowsRuntime] | Out-Null" & cr after tScript
   put "$xml = New-Object Windows.Data.Xml.Dom.XmlDocument" & cr after tScript
   put "$xml.LoadXml('" & tXml & "')" & cr after tScript
   put "$toast = [Windows.UI.Notifications.ToastNotification]::new($xml)" & cr after tScript
   put "[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('" & xmlEscape(tAppName) & "').Show($toast)" after tScript

   -- Write the script to the system temp folder and execute it.
   -- -WindowStyle Hidden suppresses the console window.
   -- -ExecutionPolicy Bypass allows unsigned temp scripts to always run.
   local tScriptPath
   put specialFolderPath("Temporary") & "\lcnotify.ps1" into tScriptPath
   put tScript into url ("file:" & tScriptPath)
   get shell("powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File " & quote & tScriptPath & quote)
end PostWindowsNotification
