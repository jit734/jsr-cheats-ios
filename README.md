# JSR CHEATS

Complete iOS IPA source and modding toolkit for iOS devices. Contains the full Xcode project, user interfaces, services, asset catalogs, patch packages, and kernel integration modules.

## Architecture

- `ThreeOneOSFive/views`: SwiftUI UI views and design system components.
- `ThreeOneOSFive/helpers`: Internal core services including File Manager, Workspace, License Manager, Storage, and Cleaner.
- `ThreeOneOSFive/Assets.xcassets`: App icons, vector assets, and graphic catalogs.
- `ThreeOneOSFive/Patches`: Pre-bundled `.3105` patch packages for Free Fire (Normal & MAX).
- `ThreeOneOSFive/exploit` & `ThreeOneOSFive/kexploit`: Kernel helpers, mobile house arrest bridge, and sandbox escape modules.
- `ThreeOneOSFive.xcodeproj`: Complete Xcode project configured for iOS 16.0+.
- `build_fresh.sh`: Automated macOS script to build the 100% fresh unsigned IPA.
- `build_esign_ready_ipa.sh`: Verification script ensuring the IPA is eSign/TrollStore ready.

## Features

- **Free Fire Patches**: Integrated support for Aim Drag, Aim Body, Magic Bullet, Aim Chets, Aim NheTam, and Mod Menus.
- **Built-in Authentication**: Standalone offline access system by **JSR CHEATS**.
- **File & App Data Manager**: Direct file browsing and container management.
- **Cache Cleaner**: App cache cleanup utility for iOS.

## Building the IPA

To build the fresh unsigned IPA on macOS with Xcode installed:

```bash
chmod +x build_fresh.sh build_esign_ready_ipa.sh
./build_fresh.sh
./build_esign_ready_ipa.sh build/JSRCHEATS-unsigned.ipa
```

### GitHub Actions CI

Automated builds are preconfigured in `.github/workflows/build-ios-ipa.yml`. Pushing to `main` automatically compiles and packages the unsigned eSign-ready IPA (`JSRCHEATS-unsigned.ipa`) and publishes it as a workflow artifact.
