# Roxum IDE

Roxum IDE is an mobile-first code editor and mini IDE for Android, built with Flutter.
It combines editing, terminal workflows, Git/GitHub tooling, AI assistance, runtime downloads, and deep customization in one app.

#### Roxum uses the powerful [code_forge](https://github.com/heckmon/code_forge) package as it's editor engine.

## Get early access.

### The app is out for closed testing/early access. Follow the below steps to join:

Join on this google groups:

https://groups.google.com/u/0/g/roxum-closed-test

Then accept the testing request:

https://play.google.com/apps/testing/com.roxum

Then install on android:

https://play.google.com/store/apps/details?id=com.roxum

### Gallery

 <table>
  <tr>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/home.jpg" width="100%"></td>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/ag.jpg" width="100%"></td>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/ag_diff.jpg" width="100%"></td>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/rt-roxum.jpg" width="100%"></td>
  </tr>
  <tr>
    <td><img src="https://lh3.googleusercontent.com/o8_GNH3SBQnbnrJWduWE9xbW-RF8NBO3iphBx1mEc_gVYbSkyAGZyy5zEcMTGupt_1oCQipOpZMwbjlhJgbjyEs" width="100%"></td>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/git_diff.jpg" width="100%"></td>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/diag.jpg" width="100%"></td>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/accnt.jpg" width="100%"></td>
  </tr>
  <tr>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/explorer.jpg" width="100%"></td>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/lsp.jpg" width="100%"></td>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/ai_cmpl.jpg" width="100%"></td>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/themes.jpg" width="100%"></td>
  </tr>
  
</table> 

---
<br>

## Building from source - Roxum lite

### Important
  > This **is not** the full-featured Roxum IDE available via the Play Store.
  Roxum-lite lacks these features:
  - Dart compiler
  - Rust compiler
  - Go compiler
  - Lua interpreter
  - rust-analyzer
  - ty language server
  - emmyLua language server
  - gopls language server

> For downloading the apk, go to the [releases](https://github.com/heckmon/roxum-ide/releases)

This section is intended for users from countries like China where playstore isn't accessible. Otherwise it is recommended to download the full featured apk from the playstore as mentioned above.<br>

There are two branches are there in the repo. The [playstore-version](https://github.com/heckmon/roxum-ide/tree/playstore-version) is the master branch,
which **wont't work locally** because it uses the [play feature delivery](https://developer.android.com/guide/playcore/feature-delivery), which only works if the app
is downloaded from the google playstore.

Inorder to build the app from source, checkout the [main](https://github.com/heckmon/roxum-ide/tree/playstore-version) branch, a light weight version or roxum, and run it with flutter or gradle. This version is also available in the [releases](https://github.com/heckmon/roxum-ide/releases) as a standalone apk.
```bash
git checkout main
flutter run --release # Or flutter build apk --release
```
Or with gradle

```bash
cd android && ./gradlew :app: assembleRelease
```

---

Special Thanks ♥️
- [@MaximoMachado](https://github.com/MaximoMachado) — helped fund the Play store release.
