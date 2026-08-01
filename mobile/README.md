# CountryBoy Conductor (Flutter)

Mobile POS for bus conductors — offline-first ticketing, Bluetooth receipts, sync to `api.countryboy.co.zw`.

## Release APK (small / split by ABI)

Do **not** publish the fat universal APK (~60 MB+) to App Releases when you can avoid it. Build one APK per CPU architecture:

```bash
cd mobile

# Production API — phone ABIs only (skip x86_64 emulator)
flutter build apk --release --split-per-abi \
  --target-platform=android-arm,android-arm64 \
  --dart-define=API_BASE_URL=https://api.countryboy.co.zw/api \
  --dart-define=PUBLIC_WEB_URL=https://countryboy.co.zw
```

Outputs (under `build/app/outputs/flutter-apk/`):

| File | Typical devices | Size (approx.) |
|------|-----------------|----------------|
| `app-armeabi-v7a-release.apk` | Older 32-bit phones | ~20–25 MB |
| `app-arm64-v8a-release.apk` | Most modern phones / POS | ~20–25 MB |

**What to upload on App Releases:** use **`app-arm64-v8a-release.apk`** as the current download for depot devices (rename to `countryboy.apk` if you like). Keep the v7a build only if you still have 32-bit handsets.

Do not set `ndk.abiFilters` in Gradle when using `--split-per-abi` — Flutter owns that list and the two conflict.

### Version

Bump in `pubspec.yaml` before each store/sideload publish:

```yaml
version: 1.0.1+2   # name+code  →  version_name / version_code on App Releases
```

## Dev run

```bash
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=https://api.countryboy.co.zw/api \
  --dart-define=PUBLIC_WEB_URL=https://countryboy.co.zw
```
