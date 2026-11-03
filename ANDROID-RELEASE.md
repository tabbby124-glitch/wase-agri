# WAS الزراعية — Android release

## What this repository builds
- Debug APK for direct installation and device testing.
- Android App Bundle (AAB) for Google Play, after a private upload keystore is configured.

The app ID is `com.was.agri`. Keep this ID unchanged after publishing; changing it creates a different Play Store app.

## Build APK
1. Open the repository on GitHub.
2. Select **Actions → WAS Android Build → Run workflow**.
3. Wait for the workflow to finish.
4. Download the artifact named **WAS-Android-debug-APK** and install `app-debug.apk` on an Android phone. The phone may ask to allow installation from that source.

The workflow also runs after relevant changes are pushed to `main`.

## Enable a Play Store-signed AAB
A Play Store release must be signed with a private upload key. Do not commit the keystore or passwords to this repository.

Create an Android upload keystore securely, then add these GitHub Actions repository secrets:
- `ANDROID_KEYSTORE_BASE64`: base64 encoding of the JKS keystore file.
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

After the secrets are configured, run the workflow again. It will upload a **WAS-Google-Play-AAB** artifact.

## Before publishing
- Replace/verify the launcher icon and splash artwork.
- Verify the package ID and version code.
- Test login, Supabase auth, local storage, offline behavior, image upload, and PDF export on physical Android devices.
- Complete Google Play Console app details, privacy policy, data safety form, content rating, screenshots, and testing track.
- Ensure the app's privacy disclosures accurately describe Supabase authentication, cloud database and private file storage.

## Important
This wrapper packages the existing web application in an Android WebView. It does not change user passwords or Supabase credentials. The live weather feature requires an internet connection. A debug APK is for testing, not a Play Store production release.
