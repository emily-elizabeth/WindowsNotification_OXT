# WindowsNotification

A LiveCode Script library for posting toast notifications on Windows 10 and Windows 11 using the WinRT Toast Notification API. No LiveCode extension or compilation required.

---

## Requirements

- Windows 10 or Windows 11
- OpenXTalk 1.14/LiveCode 9.6 or later
- PowerShell (included with all Windows 10/11 installations)

---

## Installation

Start using the livecodescript.

---

## Usage

Call `RegisterNotificationAppID` once at startup to register your app with Windows, then call `PostUserNotification` as needed.

```livecode
on openStack
   if the platform is "win32" then
      RegisterNotificationAppID
   end if
end openStack
```

```livecode
PostUserNotification "Backup Complete", "Your files have been saved", "3 files backed up to D:\Backup", ""
```

The app name shown in the notification is taken from the stack's `cREVAppName` custom property. Make sure this is set, otherwise the registration and notifier ID will not match and notifications will not appear.

---

## API Reference

### `RegisterNotificationAppID`

**Type:** command

**Syntax:** `RegisterNotificationAppID`

**Summary:** Registers the application with Windows so that toast notifications display the correct app name.

**Description:**

Call this once at startup on Windows before posting any notifications. It writes an entry to the Windows registry under:

```
HKEY_CURRENT_USER\Software\Classes\AppUserModelId\<AppName>
```

This registration is required for the WinRT Toast Notification API to accept the app as a valid notifier. Without it, Windows will silently drop all toast notifications.

The app name is taken from the stack's `cREVAppName` custom property, falling back to `"OpenXTalk Application"` if not set.

**Example:**
```livecode
on openStack
   if the platform is "win32" then
      RegisterNotificationAppID
   end if
end openStack
```

---

### `RequestNotificationAuthorization`

**Type:** command

**Syntax:** `RequestNotificationAuthorization`

**Summary:** No-op stub provided for call-site compatibility with the macOS UNUserNotification library.

**Description:**

This command does nothing on Windows. It is provided so that call sites are drop-in compatible with the macOS `UNUserNotification` and `NSUserNotification` libraries.

Windows 10 and 11 allow toast notifications by default without a runtime permission request. Users can disable notifications for the app in **Settings → System → Notifications**.

**Example:**
```livecode
RequestNotificationAuthorization
```

---

### `PostUserNotification`

**Type:** command

**Syntax:** `PostUserNotification <pTitle>, <pSubTitle>, <pInformativeText>, <pIdentifier>`

**Summary:** Posts a toast notification to the Windows notification system.

**Parameters:**

| Parameter | Description |
|---|---|
| `pTitle` | The bold heading text displayed at the top of the notification. Required. |
| `pSubTitle` | A secondary heading displayed below the title. Pass empty to omit. |
| `pInformativeText` | The body text of the notification. Pass empty to omit. |
| `pIdentifier` | Ignored on Windows. Accepted for API compatibility with the macOS libraries. |

**Description:**

Use `PostUserNotification` to post a toast notification via the Windows Runtime Toast Notification API. The notification will appear in the Windows notification area and be stored in the Action Center.

The notification is delivered by writing a temporary PowerShell script to the system temp folder and executing it. The PowerShell process exits immediately after scheduling the toast, so this does not block the LiveCode engine for long.

The app name shown in the notification is taken from the stack's `cREVAppName` custom property. If this is empty, it falls back to `"OpenXTalk Application"`. Make sure `RegisterNotificationAppID` has been called at startup with the same app name, otherwise the notification will not appear.

**Examples:**
```livecode
PostUserNotification "Backup Complete", "Your files have been saved", "3 files backed up to D:\Backup", ""
```
```livecode
PostUserNotification "Hello", "", "", ""
```

---

## Notes

- `RegisterNotificationAppID` must be called once at startup before posting any notifications, otherwise Windows will silently drop them.
- Notifications are only shown when the app is in the **background**. Windows suppresses toast notifications from the currently focused app.
- The `pIdentifier` parameter is accepted for API compatibility with the macOS libraries but has no effect on Windows. The WinRT Toast API does not support notification replacement by identifier in this implementation.
- The temporary PowerShell script is written to `specialFolderPath("Temporary")` as `lcnotify.ps1` and is overwritten on each call.
- `-ExecutionPolicy Bypass` is passed to PowerShell to ensure the unsigned temporary script always runs regardless of the machine's execution policy setting.
- XML special characters (`&`, `<`, `>`, `"`, `'`) in notification text are automatically escaped before being embedded in the toast XML payload.

---

## Cross-Platform Usage

This library exposes the same handler names as the macOS `UNUserNotification` and `NSUserNotification` extensions. Add the appropriate handlers for each platform and call `PostUserNotification` without any platform checks in your application code.

```livecode
on openStack
   -- Works on both macOS and Windows with no platform checks needed
   RequestNotificationAuthorization
   if the platform is "win32" then
      RegisterNotificationAppID
   end if
end openStack

on notifyUser pMessage
   PostUserNotification "My App", pMessage, "", ""
end notifyUser
```
