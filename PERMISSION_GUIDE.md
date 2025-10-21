# Permission Management Guide - Full-Screen Intent Notifications

## 🔒 Overview

This guide explains how the app requests and manages permissions for full-screen intent notifications with user-friendly dialogs and status cards.

## 📱 Permissions Required

### 1. **Notification Permission** (Android 13+)
- **What**: Basic permission to show notifications
- **When**: Required on Android 13 (API 33) and above
- **Why**: Allows the app to send reminders to the user

### 2. **Exact Alarm Permission** (Android 12+)
- **What**: Permission to schedule notifications at exact times
- **When**: Required on Android 12 (API 31) and above
- **Why**: Ensures reminders appear at the precise time you set

### 3. **Full-Screen Intent Permission** (All Android)
- **What**: Permission to show full-screen overlays
- **When**: Declared in manifest, auto-granted below Android 10
- **Why**: Allows the app to wake device and show full-screen alerts

## 🎯 User Experience Flow

### Initial Setup
```
User Opens Set Reminder Screen
    ↓
Permission Status Card Appears
    ↓
Shows Which Permissions Are Granted
    ↓
If Missing: "Enable Permissions" Button
```

### Permission Request Flow
```
User Clicks "Enable Permissions"
    ↓
1. Notification Permission Dialog
   "Enable Notifications"
   - Explains why needed
   - "Not Now" or "Enable" buttons
    ↓
2. Exact Alarm Permission Dialog
   "Enable Exact Alarms"
   - Explains precise timing
   - Opens system settings
    ↓
3. Full-Screen Intent Info Dialog
   "Enable Full-Screen Alerts"
   - Explains lock screen alerts
   - Acknowledges feature
    ↓
Permissions Updated → Card Shows Green ✅
```

## 🎨 UI Components

### Permission Status Card

**All Permissions Granted** (Green):
```
┌────────────────────────────────────┐
│ ✅  All Permissions Granted        │
│                                    │
│ 🔔 Notifications          ✅      │
│ ⏰ Exact Alarms           ✅      │
└────────────────────────────────────┘
```

**Permissions Required** (Orange):
```
┌────────────────────────────────────┐
│ ⚠️  Permissions Required           │
│                                    │
│ 🔔 Notifications          ❌      │
│ ⏰ Exact Alarms           ✅      │
│                                    │
│     [Enable Permissions]           │
└────────────────────────────────────┘
```

### Permission Dialogs

#### 1. Notification Permission
```
┌─────────────────────────────────────┐
│ 🔔 Enable Notifications             │
├─────────────────────────────────────┤
│                                     │
│ To receive important reminders for  │
│ your documents, please enable       │
│ notifications.                      │
│                                     │
│ This will allow the app to send you │
│ alerts about expiring documents     │
│ even when the app is closed.        │
│                                     │
│         [Not Now]    [Enable] →     │
└─────────────────────────────────────┘
```

#### 2. Exact Alarm Permission
```
┌─────────────────────────────────────┐
│ ⏰ Enable Exact Alarms              │
├─────────────────────────────────────┤
│                                     │
│ For precise reminder timing, this   │
│ app needs permission to schedule    │
│ exact alarms.                       │
│                                     │
│ This ensures your reminders appear  │
│ at the exact time you set them.     │
│                                     │
│ You will be taken to system         │
│ settings to enable this permission. │
│                                     │
│         [Skip]    [Open Settings] → │
└─────────────────────────────────────┘
```

#### 3. Full-Screen Intent Info
```
┌─────────────────────────────────────┐
│ 📱 Enable Full-Screen Alerts        │
├─────────────────────────────────────┤
│                                     │
│ To show important reminders even    │
│ when your device is locked, this    │
│ app needs permission to display     │
│ full-screen alerts.                 │
│                                     │
│ This ensures you never miss         │
│ critical document expiry reminders. │
│                                     │
│ The app will wake up your device    │
│ and show the reminder on the        │
│ entire screen.                      │
│                                     │
│         [Not Now]    [Enable] →     │
└─────────────────────────────────────┘
```

## 🔧 Implementation Details

### Files Modified

#### 1. **pubspec.yaml**
```yaml
dependencies:
  permission_handler: ^11.3.1  # Added for permission management
  timezone: ^0.10.1             # Updated for compatibility
```

#### 2. **lib/services/notification_permission_helper.dart**
**Key Methods**:
- `hasNotificationPermission()` - Check notification permission
- `requestNotificationPermission()` - Request notification permission
- `hasExactAlarmPermission()` - Check exact alarm permission
- `requestExactAlarmPermission()` - Opens system settings
- `requestAllPermissions(context)` - Request all with dialogs
- `buildPermissionStatusCard(context)` - Shows status widget

#### 3. **lib/presentation/setReminder.dart**
**Changes**:
- Added permission status card at top
- Check permissions before scheduling
- Auto-request if missing
- Show helpful error messages

### Permission Check Flow

```dart
// 1. Check on screen load
@override
void initState() {
  super.initState();
  _checkPermissions();
}

// 2. Request when needed
Future<void> _requestPermissions() async {
  await NotificationPermissionHelper.requestAllPermissions(context);
  await _checkPermissions();
}

// 3. Validate before action
if (!_permissionsGranted) {
  await _requestPermissions();
  if (!_permissionsGranted) {
    // Show error
    return;
  }
}
```

## 🚀 Usage Examples

### Display Permission Status
```dart
// In your widget
NotificationPermissionHelper.buildPermissionStatusCard(context)
```

### Request All Permissions
```dart
final results = await NotificationPermissionHelper.requestAllPermissions(context);
print('Notification: ${results['notification']}');
print('Exact Alarm: ${results['exactAlarm']}');
print('Full Screen: ${results['fullScreen']}');
```

### Check Individual Permissions
```dart
// Notification
bool hasNotif = await NotificationPermissionHelper.hasNotificationPermission();

// Exact Alarm
bool hasAlarm = await NotificationPermissionHelper.hasExactAlarmPermission();

// All
bool hasAll = await NotificationPermissionHelper.hasAllPermissions();
```

## 📋 Testing Checklist

### Permission Requests
- [ ] Open Set Reminder screen
- [ ] See permission status card
- [ ] Card shows which permissions are missing
- [ ] Click "Enable Permissions"
- [ ] Notification dialog appears with clear explanation
- [ ] Click "Enable" → Permission granted
- [ ] Exact alarm dialog appears
- [ ] Click "Open Settings" → System settings open
- [ ] Grant permission in settings
- [ ] Return to app → Card updates
- [ ] Full-screen dialog appears
- [ ] Click "Enable" → Acknowledged
- [ ] Card turns green with checkmarks

### Permission Validation
- [ ] Try to set reminder without permissions
- [ ] See error message
- [ ] Grant permissions
- [ ] Try again → Success
- [ ] Test reminder scheduled successfully

### Persistence
- [ ] Grant all permissions
- [ ] Close app
- [ ] Reopen app
- [ ] Permissions still granted (green card)

## ⚙️ Configuration

### Customize Dialog Text

**File**: `lib/services/notification_permission_helper.dart`

```dart
// Notification Dialog
static Future<bool> showNotificationPermissionDialog(BuildContext context) async {
  // Change dialog content here
  content: const Text(
    'Your custom message here...',
    style: TextStyle(fontSize: 16),
  ),
}
```

### Customize Card Colors

```dart
// Success color
color: allGranted ? Colors.green.shade50 : Colors.orange.shade50

// Icon color
color: allGranted ? Colors.green : Colors.orange

// Change to your app's theme colors
```

### Skip Specific Permissions

```dart
// In requestAllPermissions(), comment out sections you don't need

// Skip notification permission
// results['notification'] = true; // Force true

// Skip exact alarm
// results['exactAlarm'] = true; // Force true
```

## 🐛 Troubleshooting

### Issue: Permission Dialog Not Showing

**Check**:
1. Context is valid when calling
2. Dialog not already showing
3. No errors in console

**Solution**:
```dart
if (context.mounted) {
  await NotificationPermissionHelper.requestAllPermissions(context);
}
```

### Issue: Exact Alarm Settings Not Opening

**Check**:
1. Android version is 12+ (API 31+)
2. `SCHEDULE_EXACT_ALARM` in AndroidManifest.xml
3. Device allows app to open settings

**Solution**:
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
```

### Issue: Card Not Updating After Permission

**Solution**:
```dart
// Force refresh
setState(() {
  _checkPermissions();
});
```

### Issue: Permission Granted But Still Shows Red

**Check**:
```dart
// Debug permissions
final hasNotif = await NotificationPermissionHelper.hasNotificationPermission();
final hasAlarm = await NotificationPermissionHelper.hasExactAlarmPermission();
print('Notification: $hasNotif, Alarm: $hasAlarm');
```

## 📱 Platform-Specific Notes

### Android 13+ (API 33+)
- **Notification permission** is runtime permission
- Must be explicitly requested
- User can deny permanently

### Android 12+ (API 31+)
- **Exact alarm permission** required
- Opens system settings
- User must manually enable

### Android 10-11 (API 29-30)
- Exact alarm works without permission
- Full-screen intent auto-granted

### Android < 10 (API < 29)
- All permissions auto-granted
- No runtime requests needed

## ✅ Best Practices

### 1. **Request Contextually**
- Don't request on app launch
- Wait until user tries to set reminder
- Explain why it's needed

### 2. **Clear Explanations**
- Use simple language
- Explain benefits to user
- Show what features unlock

### 3. **Graceful Degradation**
- Allow app use without all permissions
- Show what features are disabled
- Offer easy re-request path

### 4. **Visual Feedback**
- Show permission status clearly
- Update UI immediately after grant
- Use colors (green = good, orange = action needed)

### 5. **Don't Spam**
- Request once per session
- Remember if user declined
- Offer settings shortcut instead

## 🎯 Summary

Your app now:
- ✅ Requests notification permission with clear dialog
- ✅ Requests exact alarm permission (opens settings)
- ✅ Shows full-screen intent info dialog
- ✅ Displays beautiful permission status card
- ✅ Validates permissions before actions
- ✅ Provides helpful error messages
- ✅ Updates UI in real-time
- ✅ Follows Android best practices

Users will understand exactly why each permission is needed and can easily grant them with confidence! 🎉

---

**Related Documentation**:
- `FULLSCREEN_OVERLAY_GUIDE.md` - Full-screen implementation
- `NOTIFICATION_SETUP.md` - Notification configuration
- `QUICK_START.md` - Quick reference guide
