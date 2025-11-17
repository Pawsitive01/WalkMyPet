# 🎯 Firebase Emulator Demo & Testing Guide

## 🎉 What's Been Set Up

Your Firebase Local Emulator Suite is **fully configured and populated** with test data!

### ✅ What's Running

```
┌────────────────┬──────────────┬─────────────────────────────────┐
│ Service        │ Host:Port    │ UI Link                         │
├────────────────┼──────────────┼─────────────────────────────────┤
│ Emulator UI    │ localhost    │ http://localhost:4000           │
│ Authentication │ 0.0.0.0:9099 │ http://localhost:4000/auth      │
│ Firestore      │ 0.0.0.0:8081 │ http://localhost:4000/firestore │
└────────────────┴──────────────┴─────────────────────────────────┘
```

## 📊 Test Data Available

### 🔐 Authentication Users

| Email | Password | Role | Purpose |
|-------|----------|------|---------|
| `walker1@test.com` | `password123` | Walker | John Walker - Pro walker |
| `walker2@test.com` | `password123` | Walker | Jane Walker - Certified trainer |
| `owner1@test.com` | `password123` | Owner | Owner of Max (Golden Retriever) |
| `owner2@test.com` | `password123` | Owner | Owner of Bella (French Bulldog) |
| `admin@test.com` | `admin123` | Admin | Administrator account |

### 📄 Firestore Collections

#### `walkers` Collection
- **walker1**: John Walker (4.8★, 200 walks, $25/hr)
- **walker2**: Jane Walker (4.9★, 250 walks, $30/hr)

#### `owners` Collection
- **owner1**: Max's owner (Golden Retriever, 3 years)
- **owner2**: Bella's owner (French Bulldog, 2 years)

## 🚀 Quick Start Demo

### 1. View Emulator Dashboard

```bash
# Open in your browser
http://localhost:4000
```

You'll see:
- 📊 Overview of all emulators
- 🔐 5 test users in Authentication
- 📄 4 documents in Firestore (2 walkers, 2 owners)

### 2. Explore Authentication

```bash
# Direct link to Auth UI
http://localhost:4000/auth
```

Features:
- ✅ View all 5 test users
- ➕ Add new users manually
- 🔍 Search by email
- 🗑️ Delete users
- 🔄 Reset passwords

### 3. Explore Firestore

```bash
# Direct link to Firestore UI
http://localhost:4000/firestore
```

Features:
- ✅ View `walkers` and `owners` collections
- ➕ Add new documents
- ✏️ Edit existing documents
- 🗑️ Delete documents
- 🔍 Query data

## 🧪 Testing Scenarios

### Scenario 1: Test User Registration

1. Run your app (web or mobile)
2. Navigate to registration
3. Create a new account
4. Check http://localhost:4000/auth - your new user appears instantly!

### Scenario 2: Test User Login

1. In your app, go to login
2. Use credentials: `walker1@test.com` / `password123`
3. Login should work (local, no internet needed!)
4. Check Emulator UI to see user activity

### Scenario 3: View Walker Profiles

1. In Emulator UI, go to Firestore
2. Open `walkers` collection
3. Click on `walker1` or `walker2`
4. See all the data fields
5. Edit any field and save - changes are immediate!

### Scenario 4: Add New Walker

1. In Firestore UI, click "Start collection"
2. Collection ID: `walkers`
3. Document ID: `walker3`
4. Add fields:
   - `name`: (string) "Sam Wilson"
   - `email`: (string) "walker3@test.com"
   - `rating`: (number) 4.5
   - `hourlyRate`: (number) 28
5. Save - now you have 3 walkers!

## 🎨 Interactive Features

### Live Data Sync

Changes in Emulator UI → Instantly reflected in your app!

Try this:
1. Open your app showing walker list
2. In Emulator UI, edit walker1's name
3. Watch your app update in real-time!

### Authentication Flow

1. **Sign Up Flow**:
   ```
   App → Create Account → Emulator saves user → Shows in UI
   ```

2. **Sign In Flow**:
   ```
   App → Login → Emulator validates → Returns token → App authenticated
   ```

3. **Password Reset**:
   - Emulator logs reset attempts
   - View reset events in UI

## 📖 Common Operations

### Export Emulator Data

Save your test data for later:

```bash
firebase emulators:export ./emulator-data

# Creates:
# - auth_export/
# - firestore_export/
```

### Import Emulator Data

Restore previously exported data:

```bash
firebase emulators:start --import=./emulator-data
```

### Reset All Data

Just restart the emulators:

```bash
# Stop emulators (Ctrl+C)
# Start again
./start-emulators.sh
```

### Re-seed Data

Run the seeder scripts again:

```bash
./test-firebase-emulators.sh  # Creates auth users
node seed-firestore-data.js    # Creates Firestore data
```

## 🔧 Advanced Features

### Query Firestore from Terminal

```bash
# Get all walkers
curl http://localhost:8081/v1/projects/walkmypet-dff4e/databases/(default)/documents/walkers

# Get specific walker
curl http://localhost:8081/v1/projects/walkmypet-dff4e/databases/(default)/documents/walkers/walker1
```

### Create User from Terminal

```bash
curl -X POST "http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=test" \
-H "Content-Type: application/json" \
-d '{
  "email": "newuser@test.com",
  "password": "password123",
  "displayName": "New User"
}'
```

## 💡 Pro Tips

1. **Use Chrome DevTools**:
   - Open Network tab
   - See all Firebase API calls to emulator
   - Debug authentication flows

2. **Check Emulator Logs**:
   ```bash
   tail -f firestore-debug.log
   ```

3. **Test Offline First**:
   - Develop entire app offline
   - Only connect to production when ready

4. **Security Rules Testing**:
   - Add rules to `firestore.rules`
   - Test rules in Emulator UI

5. **Performance Testing**:
   - Load test data easily
   - No API quotas or costs!

## 🐛 Troubleshooting

### Port Already in Use

```bash
# Find process using port
lsof -i :4000

# Kill if needed
kill -9 <PID>
```

### Emulators Not Connecting

1. Check emulators are running: `curl http://localhost:4000`
2. Check app console for connection messages
3. Verify `FirebaseEmulatorConfig.connectToEmulators()` is called

### Data Not Appearing

1. Verify emulator is running
2. Check correct collection/document names
3. Refresh Emulator UI (F5)

## 📚 Resources

- **Emulator UI**: http://localhost:4000
- **Auth UI**: http://localhost:4000/auth
- **Firestore UI**: http://localhost:4000/firestore
- **Full Guide**: See `FIREBASE_EMULATOR_GUIDE.md`

## 🎯 Next Steps

1. ✅ **Explore Emulator UI** - Click around, see what's possible
2. ✅ **Test Authentication** - Try logging in with test accounts
3. ✅ **View Firestore Data** - See the walkers and owners
4. ✅ **Run Your App** - Connect and see it work with emulated data
5. ✅ **Experiment** - Add/edit/delete data, see live updates

---

**🎉 You now have a complete, stable Firebase development environment!**

No more relying on Firebase Studio's unstable emulator. Everything runs locally, fast, and reliably.

Happy coding! 🚀
