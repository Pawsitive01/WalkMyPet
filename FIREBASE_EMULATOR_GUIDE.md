# Firebase Local Emulator Suite Guide

This guide explains how to use the Firebase Local Emulator Suite for stable local development.

## ✨ Benefits

- **Stable Development**: More reliable than Firebase Studio's built-in emulator
- **Local Testing**: Test Firebase features without hitting production
- **No Cost**: All Firebase operations are free in the emulator
- **Data Persistence**: Option to export/import emulator data
- **Better Debugging**: Clear UI for viewing Auth users and Firestore data

## 🚀 Quick Start

### 1. Start the Firebase Emulators

```bash
# Easy way - use the provided script
./start-emulators.sh

# Or manually
firebase emulators:start
```

### 2. Access the Emulator UI

Open your browser to: **http://localhost:4000**

Here you can:
- View all authenticated users
- Browse and edit Firestore collections
- Monitor emulator activity

## 📊 Emulator Ports

| Service | Port | UI Link |
|---------|------|---------|
| **Emulator UI** | 4000 | http://localhost:4000 |
| **Authentication** | 9099 | http://localhost:4000/auth |
| **Firestore** | 8081 | http://localhost:4000/firestore |

## 🔧 How It Works

### Automatic Connection in Debug Mode

The app **automatically connects** to local emulators when running in debug mode:

```dart
// In lib/services/firebase_emulator_config.dart
static const bool _useEmulators = kDebugMode;
```

- **Debug builds**: Use local emulators
- **Release builds**: Use production Firebase

### Manual Configuration

You can modify `lib/services/firebase_emulator_config.dart` to change:
- Emulator host (default: `localhost`)
- Ports
- Which services to use

## 📱 Running Your App with Emulators

### Step 1: Start Emulators

```bash
./start-emulators.sh
```

Wait until you see:
```
✔  All emulators ready! It is now safe to connect your app.
```

### Step 2: Run Your App

```bash
# Android
flutter run -d emulator-5554

# Web
flutter run -d web-server

# Or use hot reload on already running app
# Press 'r' in the terminal
```

### Step 3: Verify Connection

Check the console output. You should see:

```
🔥 Initializing Firebase...
✅ Firebase initialized successfully
🧪 Connecting to Firebase Emulators...
✅ Auth Emulator connected: localhost:9099
✅ Firestore Emulator connected: localhost:8081
✅ All Firebase Emulators connected successfully!
📊 Emulator UI available at: http://localhost:4000
```

## 🎯 Testing Features

### Authentication

1. Open Emulator UI: http://localhost:4000/auth
2. Your app's sign-ups/sign-ins will appear here
3. Manually add test users if needed

### Firestore

1. Open Emulator UI: http://localhost:4000/firestore
2. View all collections and documents
3. Edit data in real-time
4. Changes reflect immediately in your app

## 💡 Tips

### Data Persistence

To save emulator data between sessions:

```bash
# Export data
firebase emulators:export ./emulator-data

# Import data on next start
firebase emulators:start --import=./emulator-data
```

### Reset Data

Simply stop and restart the emulators - all data is cleared.

### Production vs Development

The app automatically switches:
- **`flutter run`** (debug) → Uses emulators
- **`flutter run --release`** → Uses production Firebase

## 🐛 Troubleshooting

### Emulators Won't Start

```bash
# Check if ports are in use
lsof -i :4000
lsof -i :9099
lsof -i :8081

# Kill processes if needed
killall -9 java node
```

### App Not Connecting

1. Ensure emulators are running (`firebase emulators:start`)
2. Check console for connection messages
3. Verify `FirebaseEmulatorConfig.connectToEmulators()` is called in `main.dart`

### Port Conflicts

Edit `firebase.json` to change ports:

```json
{
  "emulators": {
    "auth": {
      "port": 9099  // Change this
    },
    "firestore": {
      "port": 8081  // Change this
    }
  }
}
```

## 📚 Resources

- [Firebase Emulator Suite Docs](https://firebase.google.com/docs/emulator-suite)
- [Emulator UI Guide](https://firebase.google.com/docs/emulator-suite/install_and_configure#emulator_ui)
- [Security Rules Testing](https://firebase.google.com/docs/emulator-suite/connect_firestore#instrument_your_app_to_talk_to_the_emulators)

## 🎬 Common Workflows

### Workflow 1: Fresh Start Development

```bash
# Terminal 1: Start emulators
./start-emulators.sh

# Terminal 2: Run app on Android
flutter run -d emulator-5554

# Terminal 3: Run app on Web
flutter run -d web-server
```

### Workflow 2: Testing Auth Flow

1. Start emulators
2. Run your app
3. Create test account in app
4. Open http://localhost:4000/auth
5. View the created user
6. Test sign-in/sign-out

### Workflow 3: Testing Firestore

1. Start emulators
2. Run your app
3. Create data in app
4. Open http://localhost:4000/firestore
5. Verify data structure
6. Edit data and see live updates in app

---

**Happy coding with Firebase Emulators! 🔥**
