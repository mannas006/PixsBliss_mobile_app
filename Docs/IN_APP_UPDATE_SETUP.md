# In-App Update System Setup Guide

This guide explains how to set up and use the in-app update system for PixsBliss.

## 🚀 Overview

The in-app update system allows users to download and install app updates directly within the app, bypassing the Play Store. This is useful for beta testing, direct distribution, or when you want to provide updates outside of official app stores.

## 📋 Prerequisites

1. **GitHub Repository**: You need a GitHub repository to host the `update.json` file and APK releases
2. **APK Files**: Build and sign your APK files for distribution
3. **Internet Permission**: Already configured in the app

## 🔧 Setup Steps

### 1. Update the Update URL

In `lib/core/services/update_service.dart`, update the `_updateUrl` constant:

```dart
static const String _updateUrl = 'https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/update.json';
```

Replace `YOUR_USERNAME` and `YOUR_REPO` with your actual GitHub username and repository name.

### 2. Create GitHub Releases

1. **Build your APK**:
   ```bash
   flutter build apk --release
   ```

2. **Create a GitHub Release**:
   - Go to your GitHub repository
   - Click "Releases" → "Create a new release"
   - Tag: `v1.0.5` (match your version)
   - Title: `Version 1.0.5`
   - Upload the APK file from `build/app/outputs/flutter-apk/app-release.apk`

3. **Get the APK URL**:
   - After uploading, right-click on the APK file in the release
   - Copy the download link (should look like: `https://github.com/username/repo/releases/download/v1.0.5/app-release.apk`)

### 3. Update the update.json File

Update the `update.json` file in your repository root:

```json
{
  "version": "1.0.5",
  "apk_url": "https://github.com/YOUR_USERNAME/YOUR_REPO/releases/download/v1.0.5/app-release.apk",
  "changelog": "✨ Added premium unlock feature\n🐛 Fixed wallpaper download issues\n⚡ Improved app performance\n🎨 Enhanced UI animations\n📱 Better Android 13+ compatibility"
}
```

### 4. Commit and Push

```bash
git add update.json
git commit -m "Update to version 1.0.5"
git push origin main
```

## 🔄 Update Flow

### For Users:

1. **Check for Updates**: Tap "Check for Updates" in Settings
2. **Review Update**: See version info and changelog
3. **Download**: Tap "Download Update" to start download
4. **Install**: After download, the APK will be installed automatically

### For Developers:

1. **Build New Version**: Update version in `pubspec.yaml`
2. **Create Release**: Build APK and create GitHub release
3. **Update JSON**: Update `update.json` with new version info
4. **Deploy**: Push changes to GitHub

## 📱 Permissions

The app automatically requests these permissions:

- **Storage Permission** (Android < 10): For saving APK to Downloads folder
- **Install Permission** (Android 8+): For installing APK files

## 🛠️ Testing

### Test Update Flow:

1. **Lower Version**: Set a lower version in `pubspec.yaml` (e.g., `1.0.0`)
2. **Higher Version**: Set a higher version in `update.json` (e.g., `1.0.5`)
3. **Test**: Run the app and check for updates

### Test Download:

1. **Valid URL**: Ensure the APK URL in `update.json` is accessible
2. **File Size**: Test with different APK sizes
3. **Network**: Test on different network conditions

## 🔒 Security Considerations

1. **HTTPS Only**: Always use HTTPS URLs for APK downloads
2. **Signed APKs**: Always sign your APK files before distribution
3. **Version Validation**: The app validates version numbers before downloading
4. **User Consent**: Users must explicitly choose to download updates

## 🐛 Troubleshooting

### Common Issues:

1. **Permission Denied**:
   - Ensure all permissions are properly declared in `AndroidManifest.xml`
   - Check if user granted permissions when prompted

2. **Download Fails**:
   - Verify APK URL is accessible
   - Check network connectivity
   - Ensure sufficient storage space

3. **Installation Fails**:
   - Verify APK is properly signed
   - Check if "Install from Unknown Sources" is enabled
   - Ensure APK is compatible with device

### Debug Information:

Enable debug logging by checking the console output for:
- Update check results
- Download progress
- Installation status
- Error messages

## 📝 Version Management

### Version Format:
- Use semantic versioning: `MAJOR.MINOR.PATCH`
- Example: `1.0.5`, `2.1.0`, `1.0.0`

### Version Comparison:
- The app compares version numbers numerically
- `1.0.5` > `1.0.4`
- `2.0.0` > `1.9.9`

## 🎯 Best Practices

1. **Regular Updates**: Keep the `update.json` file updated with each release
2. **Clear Changelog**: Provide clear, user-friendly changelog descriptions
3. **Test Thoroughly**: Test the update flow before releasing to users
4. **Backup Strategy**: Always have a fallback (like Play Store) for critical updates
5. **User Communication**: Inform users about the update process and requirements

## 📞 Support

If you encounter issues:

1. Check the console logs for error messages
2. Verify all URLs and permissions are correct
3. Test on different Android versions
4. Ensure APK files are properly signed and accessible

---

**Note**: This in-app update system is designed for development and beta testing. For production apps, consider using official app stores or enterprise distribution methods. 