# StudyMate release signing

StudyMate release builds require a private upload key. Debug builds do not use it.

## Create the upload key on Windows

Run this manually in PowerShell with the JDK `keytool` available:

```powershell
keytool -genkeypair -v `
  -keystore "$env:USERPROFILE\studymate-upload-keystore.jks" `
  -storetype JKS `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias upload
```

Keep the keystore and both passwords private. Never commit them or send them through ordinary chat or email. Back up the upload key securely and maintain a second secure backup. Losing it creates operational recovery work even when Google Play key reset options are available.

Copy `android/key.properties.example` to `android/key.properties` and replace every placeholder with local values. Both the properties file and keystore formats are ignored by Git.

For a new Play listing, enable Play App Signing. This developer-owned key is the **upload key** used to sign AAB uploads. It is not the **app signing key** that Google Play manages and uses to sign APKs distributed to users.
