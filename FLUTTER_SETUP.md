# KuberX Flutter App Setup Guide

## Firebase Configuration for Flutter

### 1. Install Flutter Dependencies
```bash
flutter pub get
```

### 2. Firebase Project Setup

#### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project called "KuberX" or use existing
3. Enable Authentication → Sign-in method → Google

#### Step 2: Add Flutter App to Firebase
1. Click "Add app" → Flutter
2. Follow the setup wizard
3. Download configuration files

#### Step 3: Update Firebase Options
Replace the placeholder values in `lib/firebase_options.dart` with your actual Firebase configuration:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'your-actual-android-api-key',
  appId: 'your-actual-android-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  authDomain: 'your-project-id.firebaseapp.com',
  storageBucket: 'your-project-id.appspot.com',
);
```

### 3. Google Sign-In Configuration

#### For Android:
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/google-services.json`
3. Update `android/app/build.gradle`:

```gradle
plugins {
    id "com.google.gms.google-services" version "4.3.15" apply false
}

apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation "com.google.android.gms:play-services-auth:20.7.0"
}
```

#### For iOS:
1. Download `GoogleService-Info.plist` from Firebase Console
2. Add it to `ios/Runner/GoogleService-Info.plist`
3. Update `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>your-reversed-client-id</string>
        </array>
    </dict>
</array>
```

### 4. Backend API Configuration
Update `lib/config/api_config.dart` with your backend URL:

```dart
static const String baseUrl = 'http://your-backend-url/api';
// For local development: 'http://localhost:3000/api'
// For production: 'https://your-domain.com/api'
```

## Running the App

### 1. Start Backend Server
```bash
cd backend
npm run dev
```

### 2. Run Flutter App
```bash
flutter run
```

## App Features

### Authentication Flow
1. **Login Screen**: Google Sign-In with Firebase
2. **Profile Setup**: Name and Date of Birth entry
3. **Home Screen**: Portfolio dashboard with crypto data

### API Integration
- Real-time cryptocurrency prices
- Portfolio tracking with profit/loss calculation
- Transaction history
- User profile management

### State Management
- Provider pattern for dependency injection
- AuthService for Firebase authentication
- ApiService for backend communication

## File Structure
```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── Login.dart               # Authentication screen
├── Name.dart               # Profile setup
├── Home.dart               # Main dashboard
├── config/
│   └── api_config.dart     # API endpoints
└── services/
    ├── auth_service.dart   # Firebase auth
    └── api_service.dart    # Backend API
```

## Troubleshooting

### Common Issues
1. **Firebase not initialized**: Ensure `firebase_options.dart` has correct values
2. **Google Sign-In fails**: Check SHA-1 fingerprints in Firebase Console
3. **API calls fail**: Verify backend is running and API URLs are correct
4. **Build errors**: Run `flutter clean && flutter pub get`

### Debug Steps
1. Check Firebase Console for authentication logs
2. Monitor backend logs for API errors
3. Use Flutter inspector for UI debugging
4. Check device logs for detailed error messages
