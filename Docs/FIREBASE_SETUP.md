# Firebase and Cloudinary Setup Guide

This guide will help you set up Firebase and Cloudinary for the WallMuse mobile app.

## Firebase Setup

### 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter a project name (e.g., "wallmuse-app")
4. Follow the setup wizard

### 2. Enable Firestore Database

1. In the Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" for development
4. Select a location for your database

### 3. Set up Firestore Security Rules

Update your Firestore security rules to allow read access to wallpapers:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read access to wallpapers collection
    match /wallpapers/{document} {
      allow read: if true; // Allow public read access
      allow write: if false; // Restrict write access
    }
    
    // Allow read access to categories collection
    match /categories/{document} {
      allow read: if true; // Allow public read access
      allow write: if false; // Restrict write access
    }
  }
}
```

### 4. Add Firebase to Your App

#### For Android:
1. In Firebase Console, go to "Project settings" > "Your apps"
2. Click "Add app" and select Android
3. Enter your package name (e.g., `com.wallmuse.app`)
4. Download `google-services.json` and place it in `android/app/`
5. Update `android/build.gradle` and `android/app/build.gradle` as instructed

#### For iOS:
1. In Firebase Console, go to "Project settings" > "Your apps"
2. Click "Add app" and select iOS
3. Enter your bundle ID (e.g., `com.wallmuse.app`)
4. Download `GoogleService-Info.plist` and add it to your iOS project
5. Update your iOS project as instructed

### 5. Update Firebase Configuration

Update `lib/firebase_options.dart` with your actual Firebase configuration:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'your-actual-android-api-key',
  appId: 'your-actual-android-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  storageBucket: 'your-actual-project-id.appspot.com',
);
```

## Cloudinary Setup

### 1. Create a Cloudinary Account

1. Go to [Cloudinary](https://cloudinary.com/) and sign up
2. Note your cloud name from the dashboard

### 2. Create an Upload Preset

1. In Cloudinary Console, go to "Settings" > "Upload"
2. Scroll down to "Upload presets"
3. Click "Add upload preset"
4. Set "Signing Mode" to "Unsigned"
5. Save the preset name

### 3. Update Cloudinary Configuration

Update `lib/core/services/cloudinary_service.dart` with your actual Cloudinary configuration:

```dart
_cloudinary = CloudinaryPublic(
  'your-actual-cloud-name', // Replace with your Cloudinary cloud name
  'your-actual-upload-preset', // Replace with your upload preset
  cache: false,
);
```

Also update the URL methods in the same file:

```dart
String getOptimizedImageUrl(String publicId, {
  int width = 1080,
  int height = 1920,
  String format = 'auto',
  String quality = 'auto',
}) {
  return 'https://res.cloudinary.com/your-actual-cloud-name/image/upload/'
         'w_$width,h_$height,f_$format,q_$quality/$publicId';
}
```

## Firestore Data Structure

### Wallpapers Collection

Each document in the `wallpapers` collection should have the following structure:

```json
{
  "title": "Beautiful Landscape",
  "tags": ["nature", "landscape", "mountains"],
  "category": "nature",
  "imageUrl": "https://res.cloudinary.com/your-cloud-name/image/upload/v1234567890/wallpapers/landscape.jpg",
  "thumbnailUrl": "https://res.cloudinary.com/your-cloud-name/image/upload/w_300,h_400,c_fill/v1234567890/wallpapers/landscape.jpg",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "public_id": "wallpapers/landscape",
  "featured": false,
  "trending": false,
  "downloads": 0,
  "likes": 0,
  "views": 0,
  "status": "active"
}
```

### Categories Collection

Each document in the `categories` collection should have the following structure:

```json
{
  "name": "Nature",
  "slug": "nature",
  "color": "#4CAF50",
  "featured": true,
  "order": 1,
  "status": "active"
}
```

## Testing the Setup

1. Run `flutter pub get` to install dependencies
2. Ensure your Firebase and Cloudinary configurations are correct
3. Run the app and check if the User Uploads tab loads wallpapers from Firestore
4. Test offline functionality by turning off internet and refreshing

## Troubleshooting

### Common Issues:

1. **Firebase initialization error**: Check your `firebase_options.dart` configuration
2. **Firestore permission denied**: Verify your Firestore security rules
3. **Cloudinary upload fails**: Check your cloud name and upload preset
4. **Cache not working**: Ensure Hive is properly initialized

### Debug Tips:

1. Check the console logs for error messages
2. Verify your Firebase project is in the correct region
3. Ensure your Cloudinary account has sufficient credits
4. Test with a simple document in Firestore first 