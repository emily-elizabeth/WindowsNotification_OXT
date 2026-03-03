# WindowsNotification

A LiveCode extension for posting toast notifications on Windows 10 and Windows 11 using the WinRT Toast Notification API.

---

## Requirements

- Windows 10 or Windows 11
- OpenXTalk 1.14/LiveCode 9.6 or later
- PowerShell (included with all Windows 10/11 installations)

---

## Installation

1. Copy `WindowsNotification.lcb` into your project and compile it using the LiveCode Extension Builder, or install the pre-built `.lce` file via the Extension Manager.
2. Copy the `PostWindowsNotification` handler from `WindowsNotification.livecodescript` into your **main stack script**. This is required — the LCB extension dispatches to this handler to perform the actual notification.

---

## Usage

No authorization request is needed. Simply call `PostUserNotification` directly.

```livecode
PostUserNotification "Backup Complete", "Your files have been saved", "3 files backed up to D:\Backup", ""
```

---

## API Reference

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

The app name shown in the notification is taken from the stack's `cREVAppName` custom property. If this is empty, it falls back to `"LiveCode Application"`.

**Examples:**
```livecode
PostUserNotification "Backup Complete", "Your files have been saved", "3 files backed up to D:\Backup", ""
```
```livecode
PostUserNotification "Hello", "", "", ""
```

---

## Stack Script Requirement

This extension dispatches a `PostWindowsNotification` message to your stack script to handle file I/O and shell execution, which are not available in LiveCode Builder. You must add the following handler to your **main stack script**, or notifications will silently fail.

The handler is provided in `WindowsNotification.livecodescript`. Copy its contents into your stack script.

---

## Notes

- Notifications are only shown when the app is in the **background**. Windows suppresses toast notifications from the currently focused app.
- The `pIdentifier` parameter is accepted for API compatibility with the macOS libraries but has no effect on Windows. The WinRT Toast API does not support notification replacement by identifier in this implementation.
- The temporary PowerShell script is written to `specialFolderPath("Temporary")` as `lcnotify.ps1` and is overwritten on each call.
- `-ExecutionPolicy Bypass` is passed to PowerShell to ensure the unsigned temporary script always runs regardless of the machine's execution policy setting.
- XML special characters (`&`, `<`, `>`, `"`, `'`) in notification text are automatically escaped before being embedded in the toast XML payload.

---

## Cross-Platform Usage

This library exposes the same handler names as the macOS `UNUserNotification` and `NSUserNotification` extensions. To target both platforms from a single call site, load the appropriate extension for the current platform and call `PostUserNotification` without any platform checks in your application code.

```livecode
on openStack
   -- Works on both macOS and Windows with no platform checks needed
   RequestNotificationAuthorization
end openStack

on notifyUser pMessage
   PostUserNotification "My App", pMessage, "", ""
end notifyUser
```