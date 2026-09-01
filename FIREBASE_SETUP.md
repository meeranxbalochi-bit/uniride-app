# Firebase Setup Guide for UniRide

## Critical Issues Found & Fixed ✅

### Issue #1: APK Signing Certificate Mismatch (FIXED)
**Problem:** Release builds were signed with debug keys, causing Google OAuth certificate validation to fail.
**Status:** ✅ Fixed in `android/app/build.gradle.kts`

### Issue #2: Missing Firestore Security Rules (FIXED)
**Problem:** No firestore.rules file existed, which defaults to DENY ALL after 30 days.
**Status:** ✅ Created `firestore.rules` with proper role-based access control

---

## Required Firebase Console Configuration

### Step 1: Verify APK Signing Certificate ⚠️

Get your debug keystore SHA-1 fingerprint (used during development):

```bash
# On Windows (PowerShell)
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# On macOS/Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Look for:**
- `SHA1:` fingerprint (e.g., `XX:XX:XX:XX:...`)
- `SHA-256:` fingerprint

### Step 2: Register Certificates in Firebase Console

1. Go to **Firebase Console** → **Project Settings** → **Your Apps** → **Android App**
2. Scroll down to **SHA certificate fingerprints**
3. Add BOTH SHA1 and SHA-256 from your debug keystore
4. Click **Save**

**Expected fingerprints for default debug keystore:**
- SHA1: `52:1E:21:60:37:E3:6D:08:FF:38:84:C6:A8:37:FB:7B:DA:64:19:4D`
- SHA-256: `E8:94:89:36:422F:CFE2:77:85:AB:0D:E6:24:06:D1:9E:4D:0B:48:D6:A4:98:FA:34:05:E8:7E:87:2D:37:7A:36`

**Note:** If your fingerprints differ, your Firebase Console may already have different ones registered. That's OK - the important thing is consistency.

### Step 3: Deploy Firestore Security Rules

1. **Option A: Using Firebase CLI**
   ```bash
   npm install -g firebase-tools
   firebase login
   firebase deploy --only firestore:rules
   ```

2. **Option B: Manual via Firebase Console**
   - Go to **Firestore Database** → **Rules** tab
   - Replace the entire ruleset with the contents of `firestore.rules`
   - Click **Publish**

### Step 4: Verify Custom Firestore Database

1. Go to **Firestore Database** in Firebase Console
2. Check that a database with ID `ai-studio-dbc3b6d6-5228-498a-814c-23dc87d38fa1` exists
3. If NOT present:
   - Option A: Create it as a "Named Database" with that exact ID
   - Option B: Update `lib/core/constants/app_constants.dart`:
     ```dart
     static const String firestoreDatabaseId = '(default)';  // Use default database
     ```

### Step 5: Configure Google OAuth Consent Screen

1. Go to **Google Cloud Console** → **APIs & Services** → **OAuth Consent Screen**
2. Choose User Type: `Internal` (for testing) or `External` (for production)
3. Fill in **Application name**: "UniRide"
4. Add **Scopes**: Select `email`, `profile`, `openid`
5. Add **Test users**: Add your test email (e.g., `meeranxbalochi@gmail.com`)
6. Click **Save and Continue**

### Step 6: Verify OAuth 2.0 Credentials

1. Go to **Google Cloud Console** → **APIs & Services** → **Credentials**
2. Find the OAuth 2.0 Client ID for Android (should be auto-created)
3. Click to edit and verify:
   - **Package name**: `com.university.uniride_app` ✓
   - **SHA-1 fingerprint**: (matches your debug keystore) ✓

---

## Testing Login Flow

### Run Debug APK with Logging

```bash
# Build debug APK
flutter build apk --debug

# Run with live logs
flutter logs -f

# Look for these log patterns when logging in:
[Auth] Google Sign-In successful: user@example.com
[Auth] OAuth token obtained
[Auth] Firebase credential created, signing in...
[Auth] Firebase auth succeeded for UID: xxxxx
[Profile] Loading profile for email: user@example.com
[Profile] New user detected, creating profile with role: student
[Profile] Writing profile to Firestore...
[Profile] Profile created successfully
[Auth] Profile processing complete
```

### If Login Still Fails

Check logs for error codes:

| Error Code | Meaning | Fix |
|-----------|---------|-----|
| `invalid-credential` | Certificate mismatch | Re-register SHA-1 in Firebase |
| `permission-denied` | Firestore rules blocking write | Deploy `firestore.rules` |
| `not-found` | Firestore database doesn't exist | Create or update database ID |
| `network-error` | Connection issue | Check internet, Firebase servers |
| `invalid-api-key` | API key wrong | Verify firebase_options.dart |

---

## Production Release Setup ⚠️

For release builds, DO NOT use debug keys. Follow these steps:

### Step 1: Create Release Keystore

```bash
# Generate release keystore (Windows)
keytool -genkey -v -keystore release.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias release

# When prompted:
# - Keystore password: (create strong password, e.g., "MySecurePass123")
# - Key password: (same as keystore password recommended)
# - Alias name: release
# - First and Last Name: UniRide
# - Organizational Unit: Transit
# - Organization: University
# - City: (your city)
# - State: (your state)
# - Country Code: (e.g., PK)
```

### Step 2: Update build.gradle.kts

```kotlin
android {
    // ... existing config ...
    
    signingConfigs {
        release {
            storeFile = file("/path/to/release.keystore")
            storePassword = "your-keystore-password"
            keyAlias = "release"
            keyPassword = "your-key-password"
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.release
        }
    }
}
```

### Step 3: Register Release Certificate in Firebase

1. Get SHA-1 of release keystore:
   ```bash
   keytool -list -v -keystore release.keystore -alias release -storepass your-keystore-password
   ```
2. Register the SHA-1 and SHA-256 in Firebase Console (same as Step 2 above)
3. Redeploy your app to Google Play Store

---

## Firestore Database Structure

### Collections Created on First Login

**users/** (custom database)
```
{
  uid: "abc123xyz",
  email: "user@example.com",
  displayName: "Campus User",
  photoURL: "https://...",
  role: "student",  // or "driver", "admin"
  studentBusId: "bus-001",        // students only
  studentStopId: "stop-A",        // students only
  studentStopName: "Main Gate",   // students only
  createdAt: 1234567890000
}
```

**buses/** (custom database)
```
{
  id: "bus-001",
  busNumber: "B-101",
  busName: "City Express",
  capacity: 50,
  currentPassengers: 32,
  status: "in_transit",  // or "online", "idle", "maintenance"
  routeName: "Main Route",
  fleetCode: "BUS-A1B2",
  currentLocation: {
    lat: 30.1798,
    lng: 66.9750,
    speed: 45.5,
    heading: 180
  },
  nextStopIndex: 2,
  lastStopIndex: 1,
  nextStopEtaMinutes: 5,
  stops: [...],
  driverId: "driver-001",
  driverName: "Ahmed",
  driverPhone: "+92300000000",
  announcement: "",
  announcementType: ""
}
```

**routes/** (custom database)
```
{
  id: "route-001",
  name: "Main Route",
  description: "Downtown to Campus",
  stops: [
    {id: "stop-A", name: "Main Gate", lat: 30.18, lng: 66.97, order: 1},
    {id: "stop-B", name: "Library", lat: 30.19, lng: 66.98, order: 2}
  ]
}
```

---

## Troubleshooting Checklist ✓

- [ ] Firebase project created and linked to app
- [ ] google-services.json downloaded and placed in `android/app/`
- [ ] APK signing certificate registered in Firebase Console (both SHA-1 and SHA-256)
- [ ] Custom Firestore database created or default database selected
- [ ] Firestore security rules deployed
- [ ] Google OAuth Consent Screen configured
- [ ] Test user email added to OAuth test users
- [ ] Android permissions all present in AndroidManifest.xml
- [ ] Firebase Authentication enabled (Google provider)
- [ ] Firestore Database enabled (not just Analytics)
- [ ] Google Sign-In API enabled in Google Cloud Console
- [ ] Cloud Messaging API enabled (for notifications)

---

## Quick Reference

| File | Purpose |
|------|---------|
| `android/app/google-services.json` | Firebase config (auto-downloaded) |
| `lib/firebase_options.dart` | Firebase SDK initialization options |
| `lib/services/auth_service.dart` | Google Sign-In + Firestore profile creation |
| `lib/core/constants/app_constants.dart` | Custom database ID and constants |
| `firestore.rules` | Security rules (NEW - deploy to Firebase) |
| `android/app/build.gradle.kts` | APK signing configuration |

---

## Support

If login still fails after following all steps:

1. **Check Debug Logs**
   ```bash
   flutter logs -f | grep "\[Auth\]\|\[Profile\]"
   ```

2. **Verify Firebase Project**
   - Ensure custom database exists: `ai-studio-dbc3b6d6-5228-498a-814c-23dc87d38fa1`
   - Or change to `(default)` in app_constants.dart

3. **Test with Different Email**
   - First login might fail if super admin email check is strict
   - Use your personal Google account to test as a regular student

4. **Check Firebase Console**
   - Firestore → Data tab: Can you see `users` collection being created?
   - Authentication → Users tab: Does your Google account appear after signing in?

---

**Last Updated:** September 1, 2026
**Version:** 1.0.0
