# Firebase Setup Guide

Follow these steps to connect your custom Firebase project to TrackX.

## Step 1: Create a Firebase Project
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add Project** and name it `trackx`.

## Step 2: Configure Authentication
1. Navigate to **Build > Authentication > Sign-in method**.
2. Enable **Email/Password** and **Google Sign-In** providers.

## Step 3: Configure Database & Storage
1. Navigate to **Build > Firestore Database** and click **Create Database** (start in test/locked mode).
2. Deploy the firestore security rules:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```
3. Navigate to **Build > Storage** and initialize a storage bucket.

## Step 4: Register Apps
1. Add an Android app using package name: `com.example.trackx`.
2. Add an iOS app using bundle ID: `com.example.trackx`.
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) and place them in their respective platform native folders.
