# Firebase App Distribution — CI Secrets

`.github/workflows/preview-distribution.yml` builds a signed release APK and pushes it to
Firebase App Distribution on every push to the `preview` branch. None of the files it needs
(`google-services.json`, the release keystore, `key.properties`) are committed — they're
gitignored on purpose — so CI reconstructs them at runtime from 7 GitHub Actions secrets.
This doc lists each one and how to generate it.

Add them at **GitHub repo → Settings → Secrets and variables → Actions → New repository secret**.

## The 7 secrets

| Secret | Contents | Encoding |
|---|---|---|
| `GOOGLE_SERVICES_JSON` | `google-services.json` | base64 |
| `ANDROID_KEYSTORE_BASE64` | release `.jks` keystore file | base64 |
| `ANDROID_KEYSTORE_PASSWORD` | keystore (store) password | raw text |
| `ANDROID_KEY_PASSWORD` | key password | raw text |
| `ANDROID_KEY_ALIAS` | key alias | raw text |
| `FIREBASE_SERVICE_ACCOUNT` | service-account key file | **raw JSON, not base64** |
| `FIREBASE_ANDROID_APP_ID` | Firebase App ID, e.g. `1:1234567890:android:abcdef1234567890` | raw text |

`FIREBASE_SERVICE_ACCOUNT` is the one exception to "base64 it" — the workflow writes it to disk
with `printf '%s'`, so paste the JSON file's contents in as-is.

## 1. `GOOGLE_SERVICES_JSON`

1. [Firebase console](https://console.firebase.google.com) → your project → ⚙️ **Project settings**
   → **Your apps** → the Android app (package name must match `applicationId` in
   `android/app/build.gradle.kts`, currently `com.noolure.app`) → **Download `google-services.json`**.
2. Base64-encode it and paste the output as the secret value:

   ```bash
   # Linux — writes the encoded value to a file you can copy from
   base64 -w0 google-services.json > google-services.json.b64

   # macOS (no -w flag; wraps at 76 cols, which is fine — base64 -d ignores newlines)
   base64 -i google-services.json -o google-services.json.b64
   ```

   Open the `.b64` file, copy its contents, paste into the GitHub secret value field.

## 2. Release keystore → `ANDROID_KEYSTORE_BASE64` + the 3 password/alias secrets

If you don't already have a release keystore, generate one (do this once, keep the `.jks` file
and passwords somewhere safe — losing them means you can never update the app under the same
signature again):

```bash
keytool -genkey -v -keystore release-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias <pick-an-alias>
```

`keytool` prompts for a store password and a key password interactively — whatever you enter
becomes `ANDROID_KEYSTORE_PASSWORD` and `ANDROID_KEY_PASSWORD` (they can be the same value).
The alias you passed becomes `ANDROID_KEY_ALIAS`.

Then base64-encode the `.jks` file itself for `ANDROID_KEYSTORE_BASE64`:

```bash
base64 -w0 release-keystore.jks > release-keystore.jks.b64   # macOS: base64 -i release-keystore.jks -o release-keystore.jks.b64
```

## 3. `FIREBASE_SERVICE_ACCOUNT`

This needs to be a service account with permission to manage App Distribution releases —
**not** your personal Google login. Scope it narrowly rather than reusing the broad default
Admin SDK service account:

1. [Google Cloud console](https://console.cloud.google.com/iam-admin/serviceaccounts) → select
   your Firebase project → **Create Service Account** (e.g. `github-app-distribution`).
2. Grant it the **Firebase App Distribution Admin** role (`roles/firebaseappdistro.admin`).
3. Open the new service account → **Keys** tab → **Add Key** → **Create new key** → JSON →
   downloads a `.json` file.
4. Paste that file's raw contents (the whole JSON object, unmodified, **not** base64) as the
   secret value.

## 4. `FIREBASE_ANDROID_APP_ID`

Firebase console → ⚙️ **Project settings** → **General** tab → scroll to **Your apps** →
the Android app card shows **App ID** (format `1:<project-number>:android:<hash>`).

Or via the CLI, after `firebase login`:

```bash
firebase apps:list ANDROID
```

## One-time setup outside GitHub: the tester group

The workflow distributes to a Firebase App Distribution *group alias* hardcoded in the
workflow's `env:` block (`FIREBASE_TESTER_GROUP: "preview"`) — this isn't a secret, so nothing
to add in GitHub, but the group has to exist on the Firebase side before the first run:

Firebase console → **App Distribution** → **Testers & Groups** → **Add group** → name it so its
alias (shown in parentheses next to the display name) is `preview` → add tester emails.

## Sanity check

Once all 7 secrets are set, push to `preview` and watch the run in the **Actions** tab. The
workflow's own build-time check will fail loudly and early if `applicationId` in
`android/app/build.gradle.kts` isn't a valid reverse-domain identifier, before any secret is
even touched.
