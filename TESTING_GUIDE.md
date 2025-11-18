# 🧪 WalkMyPet Testing Guide

Complete testing checklist to verify Firebase Authentication and Firestore integration.

---

## 📱 Before You Begin

### 1. Start the App
```bash
flutter run
```

### 2. Open Firebase Console
- Go to [Firebase Console](https://console.firebase.google.com/)
- Select project: **walkmypet-dff4e**
- Keep two tabs open:
  - **Authentication** → Users
  - **Firestore Database** → Data

### 3. Enable Debug Logging
Check the terminal/console for debug logs with emoji indicators:
- 📝 Account creation
- 🔐 Sign in
- 🔵 Google Sign-In
- ✅ Success
- ❌ Errors
- 💾 Firestore operations

---

## ✅ Test 1: Email/Password Sign-Up (Pet Owner)

### Steps:
1. Launch app
2. Navigate to **Register** tab
3. Click **Pet Owner** card
4. Fill in the form:
   - Email: `testowner@example.com`
   - Password: `password123`
5. Click **Create Account**

### Expected Results:
✅ Success notification: "Account created successfully!"
✅ Redirected back to main screen
✅ Console logs:
```
📝 Creating new account for: testowner@example.com
✅ Firebase Auth account created: {userId}
💾 Creating Firestore user profile...
✅ Firestore user profile created successfully
👤 User type: Pet Owner
```

### Verify in Firebase Console:

**Authentication → Users:**
```
testowner@example.com
Created: [timestamp]
Signed In: [timestamp]
User UID: [unique ID]
```

**Firestore Database → users → {userId}:**
```json
{
  "email": "testowner@example.com",
  "displayName": "Pet Owner",
  "userType": "petOwner",
  "createdAt": [Timestamp],
  "photoURL": null,
  "dogName": null,
  "dogBreed": null,
  "dogAge": null
}
```

---

## ✅ Test 2: Email/Password Sign-Up (Pet Walker)

### Steps:
1. Navigate to **Register** tab
2. Click **Pet Walker** card
3. Fill in the form:
   - Email: `testwalker@example.com`
   - Password: `password123`
4. Click **Create Account**

### Expected Results:
✅ Success notification: "Account created successfully!"
✅ Console logs show user type: "Pet Walker"

### Verify in Firestore:
```json
{
  "email": "testwalker@example.com",
  "displayName": "Pet Walker",
  "userType": "petWalker",
  "createdAt": [Timestamp],
  "hourlyRate": null,
  "bio": null,
  "availability": null
}
```

---

## ✅ Test 3: Email/Password Sign-In

### Steps:
1. Navigate to any auth page
2. Click **Sign In** (toggle from sign-up)
3. Enter credentials:
   - Email: `testowner@example.com`
   - Password: `password123`
4. Click **Sign In**

### Expected Results:
✅ Success notification: "Welcome back!"
✅ Console logs:
```
🔐 Signing in user: testowner@example.com
✅ User signed in: {userId}
```

---

## ✅ Test 4: Google Sign-In (Pet Owner)

### Steps:
1. From main screen, click **Book Walker** on any walker
2. Click **Continue with Google**
3. Select a Google account
4. Approve permissions

### Expected Results:
✅ Success notification: "Welcome [Name]!"
✅ Console logs:
```
🔵 Initiating Google Sign-In...
✅ Google Sign-In successful
👤 User: John Doe (john@gmail.com)
🆔 UID: {userId}
💾 Creating/updating Firestore profile...
✅ Firestore profile created/updated
👤 User type: Pet Owner
```

### Verify in Firestore:
```json
{
  "email": "john@gmail.com",
  "displayName": "John Doe",
  "photoURL": "https://lh3.googleusercontent.com/...",
  "userType": "petOwner",
  "createdAt": [Timestamp]
}
```

**Check for Google profile photo!** ✨

---

## ✅ Test 5: Google Sign-In (Pet Walker)

### Steps:
1. Navigate to **Register** tab
2. Click **Pet Walker** card
3. Click **Continue with Google**
4. Select a **different** Google account

### Expected Results:
✅ New user created with `userType: "petWalker"`
✅ Google photo and display name populated

---

## ✅ Test 6: Cross-Navigation

### Test 6a: Owner → Walker
1. Go to owner auth page
2. Click **Register as a Pet Walker** (at bottom)
3. Should navigate to walker auth page (purple gradient)

### Test 6b: Walker → Owner
1. Go to walker auth page
2. Click **Register as a Pet Owner** (at bottom)
3. Should navigate to owner auth page (pink gradient)

---

## ✅ Test 7: Duplicate Account Handling

### Steps:
1. Try to sign up with existing email: `testowner@example.com`
2. Use any password

### Expected Results:
❌ Error notification: "An account already exists with this email."
✅ Console logs:
```
❌ Authentication error: An account already exists with this email.
```

✅ No duplicate entry in Firestore

---

## ✅ Test 8: Form Validation

### Test 8a: Invalid Email
**Input:** `notanemail`
**Result:** "Enter a valid email address"

### Test 8b: Empty Email
**Input:** (blank)
**Result:** "Email is required"

### Test 8c: Short Password
**Input:** `123`
**Result:** "Password must be at least 6 characters"

### Test 8d: Empty Password
**Input:** (blank)
**Result:** "Password is required"

---

## ✅ Test 9: Wrong Password

### Steps:
1. Try signing in with:
   - Email: `testowner@example.com`
   - Password: `wrongpassword`

### Expected Results:
❌ Error notification: "Incorrect password."

---

## ✅ Test 10: Navigation Flows

### From Main Screen:

**Test 10a: Book Walker**
1. Click **Book Walker** on walker card
2. Should navigate to **Owner** auth page (pink gradient)
3. Top icon should be a **paw** (pet owner)

**Test 10b: Add Your Pet**
1. Click **Add your Pet** on owner card
2. Should navigate to **Owner** auth page (pink gradient)

### From Detail Page:

**Test 10c: Book Walk (Walker Detail)**
1. Open any walker's detail page
2. Click **Book Walk** button at bottom
3. Should navigate to **Owner** auth page

**Test 10d: Add Your Pet (Owner Detail)**
1. Open any owner's detail page
2. Click **Add Your Pet** button at bottom
3. Should navigate to **Walker** auth page (purple gradient)

---

## ✅ Test 11: Google Sign-In Error Handling

### Test 11a: Cancel Sign-In
1. Click **Continue with Google**
2. Close the popup without selecting account

**Expected:** No error shown, loading stops gracefully

### Test 11b: Network Error (Airplane Mode)
1. Enable airplane mode
2. Try Google Sign-In

**Expected:** Error: "Network error. Please check your connection."

---

## ✅ Test 12: Multiple Sign-Ins (Same Account)

### Steps:
1. Sign in with Google as Pet Owner
2. Sign out (if logout implemented)
3. Sign in again with **same Google account** but as **Pet Walker**

### Expected Results:
✅ Firestore document **updated** (not duplicated)
✅ `userType` changed to `petWalker`
✅ `updatedAt` timestamp added
✅ Only **one** document for that user UID

---

## ✅ Test 13: Firestore Security Rules

### Test 13a: Can Read All Users (Public Profiles)
Run in Firestore Rules Playground:
```javascript
get /databases/(default)/documents/users/{userId}
Auth: Unauthenticated

Expected: ✅ Allow (public read for listings)
```

### Test 13b: Can't Create Without Auth
```javascript
create /databases/(default)/documents/users/testUser123
Auth: Unauthenticated

Expected: ❌ Deny
```

### Test 13c: Can Create Own Profile
```javascript
create /databases/(default)/documents/users/{myUserId}
Auth: Authenticated as {myUserId}

Expected: ✅ Allow
```

### Test 13d: Can't Edit Other Users
```javascript
update /databases/(default)/documents/users/{otherUserId}
Auth: Authenticated as {myUserId}

Expected: ❌ Deny
```

---

## 🐛 Common Issues & Solutions

### Issue 1: Google Sign-In Shows Error 10
**Cause:** SHA-1 certificate not configured

**Solution:**
```bash
cd android
./gradlew signingReport
```
Copy SHA-1 → Add to Firebase → Download new `google-services.json`

### Issue 2: "No user from sign in result"
**Cause:** OAuth client not in `google-services.json`

**Solution:**
1. Check `android/app/google-services.json`
2. Look for `"oauth_client"` array
3. Should have entries, not `[]`
4. Re-download from Firebase if empty

### Issue 3: Firestore Permission Denied
**Cause:** Security rules too restrictive

**Solution:**
Check Firestore rules allow:
```javascript
allow read: if true; // Public read
allow create: if isAuthenticated() && isOwner(userId);
```

### Issue 4: Email Verification Sent But Not Required
**Current:** Email verification is sent but not enforced

**Optional Enhancement:**
Add check before allowing booking:
```dart
if (!user.emailVerified) {
  // Show verification required message
}
```

---

## 📊 Success Criteria

All tests should pass with:
- ✅ No crashes
- ✅ Clear error messages
- ✅ Successful Firestore writes
- ✅ Correct user types assigned
- ✅ No duplicate documents
- ✅ Proper navigation flows
- ✅ Google Sign-In working
- ✅ Form validation working

---

## 🎯 Next Testing Phase

After basic auth works:

1. **Profile Completion:**
   - Add pet details (owner)
   - Add bio, hourly rate (walker)
   - Upload profile photos

2. **Booking System:**
   - Create booking requests
   - Accept/decline bookings
   - Track booking history

3. **Real-time Updates:**
   - Use Firestore snapshots
   - Live profile updates
   - Booking notifications

4. **Edge Cases:**
   - Offline mode
   - Slow network
   - Concurrent updates
   - Account deletion

---

## 📝 Test Results Template

Use this to track your testing:

```
Date: ___________
Tester: ___________

Test 1: Email/Password Sign-Up (Owner)     [ ] Pass [ ] Fail
Test 2: Email/Password Sign-Up (Walker)    [ ] Pass [ ] Fail
Test 3: Email/Password Sign-In             [ ] Pass [ ] Fail
Test 4: Google Sign-In (Owner)             [ ] Pass [ ] Fail
Test 5: Google Sign-In (Walker)            [ ] Pass [ ] Fail
Test 6: Cross-Navigation                   [ ] Pass [ ] Fail
Test 7: Duplicate Account Handling         [ ] Pass [ ] Fail
Test 8: Form Validation                    [ ] Pass [ ] Fail
Test 9: Wrong Password                     [ ] Pass [ ] Fail
Test 10: Navigation Flows                  [ ] Pass [ ] Fail
Test 11: Google Sign-In Error Handling     [ ] Pass [ ] Fail
Test 12: Multiple Sign-Ins                 [ ] Pass [ ] Fail
Test 13: Firestore Security Rules          [ ] Pass [ ] Fail

Notes:
_____________________________________________
_____________________________________________
```

---

**Happy Testing! 🚀**
