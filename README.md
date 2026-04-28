# Roxum IDE

Roxum IDE is an mobile-first code editor and mini IDE for Android, built with Flutter.
It combines editing, terminal workflows, Git/GitHub tooling, AI assistance, runtime downloads, and deep customization in one app.

#### Roxum uses the powerful [code_forge](https://github.com/heckmon/code_forge) package as it's editor engine.

<a href="https://play.google.com/store/apps/details?id=com.roxum">
  <img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" height="60">
</a>

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

## Building from source

This section is intended for users from countries like China where playstore isn't accessible. Otherwise it is recommended to download the full featured apk from the playstore as mentioned above.<br>

Tha app has two branches:
- [playstore-version](https://github.com/heckmon/roxum-ide/tree/playstore-version) (Full Roxum IDE)
- [main](https://github.com/heckmon/roxum-ide/tree/playstore-version) (A light weight version)

Clone this repo, then:

### Building the full version
Make sure that [git-lfs](https://git-lfs.com/) is installed in your system and accessible via the `path`. Don't skip this step, the compilers and interpreters are stored in the Github large file storage.
#### 1) Build the app as an `aab` bundle

> [!NOTE]
> 
> To include all compilers, interpreters and extensions in the build, we build it as a standalone `aab` file, which is bigger compared to the apk downloaded from the playstore. Playstore build is smaller because these external dependencies are downloaded on demand when the user requested for the particular compiler/interpreter/extension.

```bash
cd android && ./gradlew :app: bundleRelease
```
This will generate the output file in `build/app/outputs/bundle/release/app-release.aab`

#### 2) Building the apk
To install aab in your device, download the latest bundletool from the official repo:
https://github.com/google/bundletool/releases

Then build the apk:
```bash
java -jar path/to/bundletool.jar build-apks --bundle=your_app/build/app/outputs/bundle/release/app-release.aab --output=output.apks
```
This will generate a file called output.apks in the current directory
#### 3) Then install it:
Make sure that you are connected to an emulator or physical device via `adb`.
```bash
java -jar /path/to/bundletool.jar install-apks --apks=output.apks
```

### Building the lite version
### Important
  > This **is not** the full-featured Roxum IDE. This is a light weight version.

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

 The [main](https://github.com/heckmon/roxum-ide/tree/playstore-version) branch contains a light weight version of the roxum, which easy to build and run with flutter or gradle. This version is also available in the [releases](https://github.com/heckmon/roxum-ide/releases) as a standalone apk.
```bash
git checkout main
flutter run --release # Or flutter build apk --release
```
Or with gradle

```bash
git checkout main
cd android && ./gradlew :app: assembleRelease
```

---

Special Thanks ♥️
- [@MaximoMachado](https://github.com/MaximoMachado) — helped fund the Play store release.
