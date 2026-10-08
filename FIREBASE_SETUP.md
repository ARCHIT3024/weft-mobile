# Firebase Setup for Weft Mobile (Task 0.18)

## Overview

Weft uses Firebase Cloud Messaging (FCM) for push notifications.
The Firebase project setup requires manual steps in the Firebase Console.

## Steps

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project named **weft-mobile**
3. Disable Google Analytics (not needed for FCM)

### 2. Add Android App
1. Click "Add app" → Android
2. Package name: `city.weft.weft_mobile`
3. Download `google-services.json`
4. Place it at: `weft-mobile/android/app/google-services.json`

### 3. Add iOS App
1. Click "Add app" → iOS
2. Bundle ID: `city.weft.weftMobile`
3. Download `GoogleService-Info.plist`
4. Place it at: `weft-mobile/ios/Runner/GoogleService-Info.plist`

### 4. Enable Cloud Messaging
1. In Firebase Console → Project Settings → Cloud Messaging
2. Enable Firebase Cloud Messaging API (V1)
3. Download the service account JSON for the backend

### 5. Backend Integration
- Store the FCM service account JSON in AWS Secrets Manager as `FCM_SERVICE_ACCOUNT`
- The backend will use this to send push notifications via the FCM HTTP v1 API

## Status

- [ ] Firebase project created
- [ ] Android `google-services.json` added
- [ ] iOS `GoogleService-Info.plist` added
- [ ] FCM API enabled
- [ ] Service account JSON stored in Secrets Manager

> **Note**: The Flutter code (`firebase_core`, `firebase_messaging`) is already
> configured in pubspec.yaml. Firebase initialisation in `main.dart` will be
> added in Phase 2 (task 2.29) once the config files are in place.
