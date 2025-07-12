# AdMob Banner Ads Integration

This document describes the implementation of AdMob banner ads styled like wallpaper tiles in the PixsBliss mobile app.

## Overview

The AdMob integration adds banner ads to the Explore tab that are seamlessly integrated into the wallpaper grid, appearing every 8 wallpaper items. The ads are styled to match the existing wallpaper tiles with rounded corners, shadows, and proper spacing.

## Features

- ✅ **Native-looking ads**: Ads are styled to match wallpaper tiles exactly
- ✅ **Seamless integration**: Ads appear every 8 items in the grid
- ✅ **Preloading system**: Ads are preloaded for smooth user experience
- ✅ **Shimmer loading**: Shows loading animation while ads are being fetched
- ✅ **Error handling**: Graceful fallback when ads fail to load
- ✅ **Platform-specific IDs**: Different ad unit IDs for iOS and Android
- ✅ **No native code**: Pure Dart/Flutter implementation

## Configuration

### Ad Unit IDs

**Android:**
- App ID: `ca-app-pub-4991521917195620~9514845555`
- Banner Ad Unit: `ca-app-pub-4991521917195620/4159125830`

**iOS:**
- App ID: `ca-app-pub-4991521917195620~8998720672`
- Banner Ad Unit: `ca-app-pub-4991521917195620/7478024947`

### Dependencies

Added to `pubspec.yaml`:
```yaml
google_mobile_ads: ^4.0.0
```

### Platform Configuration

**Android (`android/app/src/main/AndroidManifest.xml`):**
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-4991521917195620~9514845555" />
```

**iOS (`ios/Runner/Info.plist`):**
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-4991521917195620~8998720672</string>
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
</array>
```

## Implementation Details

### 1. AdMob Service (`lib/core/services/admob_service.dart`)

Singleton service that handles:
- AdMob initialization
- Banner ad loading and caching
- Platform-specific ad unit ID selection
- Ad lifecycle management

### 2. AdMob Provider (`lib/core/providers/admob_provider.dart`)

Riverpod state management for:
- Ad loading state
- Preloaded ad count
- Error handling
- Automatic ad preloading

### 3. Styled Ad Widget (`lib/shared/widgets/styled_ad_widget.dart`)

Custom widget that:
- Matches wallpaper tile styling (rounded corners, shadows)
- Shows shimmer loading animation
- Displays "Ad" label overlay
- Handles error states gracefully

### 4. Explore Tab Integration (`lib/features/home/presentation/pages/explore_tab.dart`)

Modified to:
- Insert ads every 8 wallpaper items
- Use combined list with wallpapers and ads
- Preload ads when running low
- Handle different item types in grid

## Usage

The ads are automatically integrated into the Explore tab. No additional setup is required.

### Ad Placement Logic

```dart
// Insert ad every 8 items
if ((i + 1) % 8 == 0 && i < wallpapers.length - 1) {
  final ad = adMobNotifier.getAd();
  if (ad != null) {
    combinedList.add(ad);
  } else {
    combinedList.add('ad_placeholder');
  }
}
```

### Preloading Strategy

- Initial preload: 5 ads on app startup
- Auto-reload: When loaded ad count drops below 2
- Batch loading: 3 ads at a time

## Styling

The ads are styled to match wallpaper tiles exactly:

- **Border radius**: 18.r (matches wallpaper cards)
- **Shadow**: Same as wallpaper cards
- **Height**: 300.h (medium rectangle ad size)
- **Spacing**: Same as wallpaper grid spacing
- **Animation**: Fade-in and scale animations

## Error Handling

- **Ad loading failure**: Shows shimmer placeholder
- **No ads available**: Shows "Ad unavailable" message
- **Network issues**: Graceful degradation
- **Platform errors**: Logged for debugging

## Testing

For testing, the app uses test ad unit IDs when platform detection fails:
- Test Banner: `ca-app-pub-3940256099942544/6300978111`

## Performance Considerations

- Ads are preloaded to avoid loading delays
- Shimmer animations provide visual feedback
- Ad disposal is handled properly to prevent memory leaks
- Minimal impact on wallpaper grid performance

## Future Enhancements

- [ ] Interstitial ads for premium features
- [ ] Rewarded ads for bonus wallpapers
- [ ] A/B testing for ad placement frequency
- [ ] Analytics integration for ad performance
- [ ] User preference for ad frequency

## Troubleshooting

### Common Issues

1. **Ads not showing**: Check ad unit IDs and network connectivity
2. **Build errors**: Ensure all platform configurations are correct
3. **Memory leaks**: Verify ad disposal in provider
4. **Loading delays**: Increase preload count

### Debug Information

Enable debug logging by checking console output for:
- "AdMob initialized successfully"
- "Banner ad loaded successfully"
- "Banner ad failed to load: [error]"

## Compliance

- Follows AdMob policies and guidelines
- Proper ad labeling with "Ad" overlay
- Respects user privacy and GDPR requirements
- Implements proper ad lifecycle management 