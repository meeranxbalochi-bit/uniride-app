# Firebase Login Fix Checklist ✅

## تم کیا! (What's Fixed)

✅ **Code Changes:**
- Added detailed error logging to identify exact failure point
- Fixed UI overflow banner on login screen  
- Replaced Google Maps with Leaflet satellite map
- Corrected trigonometric functions in map service
- Created `firestore.rules` with proper security rules

✅ **Commits Pushed:**
1. `8bd1e95` - Firebase logging, overflow fix, Leaflet map
2. `b07e640` - Haversine distance calculation fix
3. `b3da19a` - Firestore security rules + Firebase setup guide

✅ **GitHub Actions:**
- Build #19+ will compile with all fixes
- APK should build successfully now

---

## اب آپ کو کرنا ہے (What YOU Need to Do)

### CRITICAL - Must Do Within 24 Hours:

### 1️⃣ Get Your APK Signing Fingerprint
```bash
# Run this command (copy-paste into PowerShell)
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**Find and copy:**
- `SHA1: XX:XX:XX:...` (e.g., `52:1E:21:60:37:E3:6D:08:FF:38:84:C6:A8:37:FB:7B:DA:64:19:4D`)
- Keep this safe!

### 2️⃣ Register Certificates in Firebase Console

**Go to:** https://console.firebase.google.com/project/gen-lang-client-0559318477/settings/general

Steps:
1. Click "Your Apps" → Android App
2. Scroll down to "SHA certificate fingerprints"
3. Click "Add fingerprint"
4. Paste your SHA1 from step 1
5. Click Save
6. **Repeat: Add SHA-256 too** (it's shown in the keytool output)

**⚠️ IMPORTANT:** If Firebase already shows different fingerprints there, your APK was signed with a different key. Use those fingerprints instead and test with `flutter build apk --debug`

### 3️⃣ Deploy Firestore Security Rules

**Option A - Easy (Firebase Console):**
1. Go to Firestore Database → Rules tab
2. Copy entire content from `firestore.rules` (in repo root)
3. Paste it into the Rules editor
4. Click "Publish"
5. Wait for confirmation

**Option B - Fast (Firebase CLI):**
```bash
npm install -g firebase-tools
firebase login
firebase deploy --only firestore:rules
```

### 4️⃣ Verify Custom Firestore Database

Go to Firestore Database:
- **Look for:** Database with ID ending in `...814c-23dc87d38fa1`
- **If you see it:** ✅ Good, skip to step 5
- **If you DON'T see it:** 
  - Create a "Named Database" with that exact ID, OR
  - Edit `lib/core/constants/app_constants.dart` line 18:
    ```dart
    static const String firestoreDatabaseId = '(default)';  // Use the default database instead
    ```

### 5️⃣ Configure Google OAuth Consent Screen

Go to: https://console.cloud.google.com/apis/consent

Steps:
1. User Type: Choose "Internal" (for testing)
2. App name: "UniRide Transit"
3. Scopes: Select "email", "profile", "openid"
4. Test users: Add your test email (`meeranxbalochi@gmail.com`)
5. Save

---

## Testing After Setup

### Build APK
```bash
flutter pub get
flutter build apk --debug
```

### Install on Phone
```bash
adb install -r build/app/outputs/apk/debug/app-debug.apk
```

### Open App and Check Logs
```bash
flutter logs -f
```

### Try to Login
1. Tap "Sign in with Google"
2. Select your test account
3. Check logs for these messages:

✅ **Success Indicators:**
```
[Auth] Google Sign-In successful: your-email@gmail.com
[Auth] OAuth token obtained
[Auth] Firebase credential created, signing in...
[Auth] Firebase auth succeeded for UID: xxxxx
[Profile] Loading profile for email: your-email@gmail.com
[Profile] New user detected, creating profile with role: student
[Profile] Writing profile to Firestore...
[Profile] Profile created successfully
[Auth] Profile processing complete
```

❌ **Error Indicators & Fixes:**

| Log Message | Issue | Fix |
|-------------|-------|-----|
| `[Auth] Firebase auth failed: invalid-credential` | Certificate mismatch | Re-register SHA-1 in Firebase Console |
| `[Profile] Firestore Error: permission-denied` | Security rules blocking | Deploy firestore.rules (see step 3) |
| `[Profile] Firestore Error: not-found` | Database doesn't exist | Check database ID or change to (default) |
| `[Auth] Unexpected error: Network error` | Internet/Firestore servers down | Wait and retry |
| `[Auth] Google Sign-In successful but then error` | Check second error log | Look for the complete error code |

---

## If Login Still Fails

### Debug Steps:

1. **Check Firebase Console Users:**
   - Go to Authentication → Users tab
   - Do you see your test account appear after failed login attempt?
   - If YES: Auth worked, issue is Firestore
   - If NO: Auth failed, issue is OAuth certificate

2. **Check Firestore Data:**
   - Go to Firestore Database → Data tab
   - Look for `users` collection
   - Is it created but empty? = Rules issue
   - Doesn't exist at all? = Database ID wrong

3. **Verify OAuth Setup:**
   - Google Cloud Console → APIs & Services → Credentials
   - Find "OAuth 2.0 Client ID (Android)"
   - Click it and verify:
     - Package name: `com.university.uniride_app` ✓
     - SHA-1 Fingerprint: Matches your keytool output ✓

4. **Test with Different Email:**
   - If using `meeranxbalochi@gmail.com`, might hit super admin logic
   - Try signing in with a different Gmail account
   - If that works, the issue is role/email specific

---

## Expected Timeline

| Step | Time | Status |
|------|------|--------|
| APK build with new code | 8-10 min | After GitHub Actions completes |
| Register certificates | 5 min | Immediate |
| Deploy security rules | 1-2 min | Immediate |
| Test login on device | 5 min | Immediate |
| **Total:** | ~15-30 min | **Can be done today!** |

---

## Configuration Summary

**Firebase Project:**
- Project ID: `gen-lang-client-0559318477`
- Custom Database: `ai-studio-dbc3b6d6-5228-498a-814c-23dc87d38fa1`
- OAuth Client: `757229807744-9p8uejj4oafstjqklq695hontmamqbg2.apps.googleusercontent.com`
- Android Package: `com.university.uniride_app`
- Google Account: `meeranxbalochi@gmail.com` (auto-admin)

**Test Account:**
- Email: Your Gmail account (add to OAuth consent screen test users)
- Password: Your Gmail password
- Expected Role After Login: `student` (unless using super admin email)

---

## Files to Reference

```
✓ FIREBASE_SETUP.md          ← Full detailed guide
✓ firestore.rules            ← Security rules (deploy to Firebase)
✓ lib/firebase_options.dart  ← SDK config (already correct)
✓ lib/services/auth_service.dart ← Login flow with logging
✓ android/app/google-services.json ← Firebase config
✓ android/app/build.gradle.kts ← APK signing config
```

---

## Support Commands

```bash
# Check current branch and commits
git log --oneline -5

# See all changes made
git diff origin/main^..main

# If something goes wrong, revert to last known good
git revert b3da19a

# Watch live logs during login
flutter logs -f | findstr "[Auth]"  # Windows
flutter logs -f | grep "[Auth]"     # Mac/Linux
```

---

## Success Criteria ✅

You'll know it's working when:

1. ✅ App opens without crashes
2. ✅ Login screen shows (no freezing)
3. ✅ Tap "Sign in with Google" → Google dialog appears
4. ✅ Select test account
5. ✅ User authenticated and profile created
6. ✅ Redirected to student dashboard (or appropriate dashboard based on role)
7. ✅ Satellite map loads and displays
8. ✅ Can scan QR or manually join a bus
9. ✅ Bus tracking works with no overflow banner

---

**Git Commits with Fixes:**
- `b3da19a` - Firebase security rules + setup guide
- `b07e640` - Map distance calculation fix
- `8bd1e95` - Original Leaflet + error logging fixes

**Status:** ✅ Ready for deployment - just need Firebase Console configuration!

**Timeline:** Set aside 30 minutes for full setup today, then test login tomorrow.

Good luck! 🚀
