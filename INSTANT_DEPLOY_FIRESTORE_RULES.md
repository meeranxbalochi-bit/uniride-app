# ⚡ Instant Deploy Firestore Rules (Firebase Console)

## Fastest Method - Direct Copy-Paste (2 minutes)

### Step 1: Open Firebase Console Rules Editor
👉 **Direct Link:** https://console.firebase.google.com/project/gen-lang-client-0559318477/firestore/rules

### Step 2: Copy The Updated Rules

Copy this entire code:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ────────────────────────────────────────────────────────────────
    // USERS COLLECTION
    // Users can create their own profile (on first login)
    // Users can read/update only their own profile
    // Admins can update any user
    // ────────────────────────────────────────────────────────────────
    match /users/{uid} {
      // Allow creating own profile (first time login)
      allow create: if request.auth != null && request.auth.uid == uid;
      
      // Allow reading own profile
      allow read: if request.auth != null && request.auth.uid == uid;
      
      // Allow updating own profile OR admin updating anyone
      allow update: if request.auth != null && 
                      (request.auth.uid == uid || 
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.get('role') == 'admin');
      
      // No deletes
      allow delete: if false;
    }
    
    // ────────────────────────────────────────────────────────────────
    // BUSES COLLECTION
    // All authenticated users can read
    // Only drivers and admins can write
    // ────────────────────────────────────────────────────────────────
    match /buses/{busId} {
      // Authenticated users can read all buses
      allow read: if request.auth != null;
      
      // Only drivers and admins can create/update/delete buses
      allow create, update, delete: if request.auth != null &&
        (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.get('role') in ['driver', 'admin']);
    }
    
    // ────────────────────────────────────────────────────────────────
    // ROUTES COLLECTION
    // All authenticated users can read
    // Only admins can write
    // ────────────────────────────────────────────────────────────────
    match /routes/{routeId} {
      // Authenticated users can read all routes
      allow read: if request.auth != null;
      
      // Only admins can create/update/delete routes
      allow create, update, delete: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.get('role') == 'admin';
    }
    
    // ────────────────────────────────────────────────────────────────
    // DENY ALL OTHER COLLECTIONS BY DEFAULT
    // ────────────────────────────────────────────────────────────────
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### Step 3: Paste in Firebase Console

1. Go to https://console.firebase.google.com/project/gen-lang-client-0559318477/firestore/rules
2. You'll see a **Rules** tab with code editor
3. **Clear** everything that's there (Ctrl+A, Delete)
4. **Paste** the code above (Ctrl+V)
5. See the yellow banner with `Publish` button
6. **Click "Publish"** button

### ✅ Done!

Rules will be deployed in **seconds**. You'll see confirmation:
```
✓ Firestore Rules updated successfully
```

---

## What Changed from Previous Rules?

### ❌ Old (Blocked Login)
```firestore
allow write: if request.auth != null && request.auth.uid == uid;
allow create: if request.auth != null;
```
**Problem:** Conflicting rules - write was too restrictive, create was too permissive

### ✅ New (Allows Login)
```firestore
allow create: if request.auth != null && request.auth.uid == uid;
allow update: if request.auth != null && (request.auth.uid == uid || is_admin);
```
**Fix:** Separate rules that work together properly

---

## Why This Fixes Login

**Before:**
1. User logs in with Google ✓
2. App tries to create user profile in Firestore
3. `create` rule says "OK, anyone authenticated"
4. `write` rule says "NO, only if uid matches" ✗
5. Firestore denies the write
6. Login fails with "permission-denied"

**After:**
1. User logs in with Google ✓
2. App tries to create user profile in Firestore
3. `create` rule says "OK, if uid matches" ✓
4. Profile created successfully ✓
5. Login succeeds! ✅

---

## Verify Deployment

After publishing, check:

1. **Firebase Console** → Firestore Database → Rules tab
   - Should show your new rules code ✓

2. **Check Rules Status**
   - Green checkmark = Active ✓
   - View "Version History" if needed

3. **Test Login**
   ```bash
   flutter build apk --debug
   flutter logs -f
   ```
   Should see:
   ```
   [Profile] Writing profile to Firestore...
   [Profile] Profile created successfully ✅
   ```

---

## Troubleshooting

### Rules won't publish?
- **Check syntax** - Copy-paste might have formatting issues
- **Reload page** - Refresh Firebase Console and try again
- **Clear cache** - Ctrl+Shift+Delete, then retry

### Still getting permission-denied error?
1. Rules are published but app is cached
2. **Uninstall app:** `adb uninstall com.university.uniride_app`
3. **Rebuild APK:** `flutter build apk --debug`
4. **Reinstall:** `adb install build/app/outputs/apk/debug/app-debug.apk`
5. Try login again

### Custom database not found?
1. Check if database ID exists: `ai-studio-dbc3b6d6-5228-498a-814c-23dc87d38fa1`
2. If not, create it as a "Named Database"
3. Or change `app_constants.dart` to use `(default)` database

---

## Done! ✅

Your Firestore rules are now deployed and login should work!

**Next:** Test the app on your phone and check the logs. 🚀
