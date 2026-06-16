# Roxum IDE

Roxum IDE is a mobile-first code editor and mini IDE for Android, built with Flutter.
It combines editing, terminal workflows, Git/GitHub tooling, AI assistance, runtime downloads, and deep customization in one app.

#### Roxum uses the powerful [code_forge](https://github.com/heckmon/code_forge) package as the editor engine.

<a href="https://play.google.com/store/apps/details?id=com.roxum">
  <img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" height="60">
</a>

## What's new in version 2:
- **Added SSH support for connecting with remote systems.**
- **Added built-in Termux support for using Termux as a backend.**
- **Option to download and load local GGUF LLM models for offline chat and code completion as requested in [#9](https://github.com/heckmon/roxum-ide/issues/9) and [#16](https://github.com/heckmon/roxum-ide/issues/16)**
- **Added search bar for themes as requested in [#11](https://github.com/heckmon/roxum-ide/issues/11).**
- **Migrated the [editor](https://github.com/heckmon/code_forge) backend to rust.**
- **Replaced JDT-LS with kmp-lsp, which provides LSP support for Java, Kotlin and Swift.**
- **Fixed [#15](https://github.com/heckmon/roxum-ide/issues/15) and [#14](https://github.com/heckmon/roxum-ide/issues/14), if it still persists, termux can be used.**
- **[#10](https://github.com/heckmon/roxum-ide/issues/10) and [#18](https://github.com/heckmon/roxum-ide/issues/18) Can be solved by using the new termux backend.**

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
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/ext.jpg" width="100%"></td>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/diag.jpg" width="100%"></td>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/accnt.jpg" width="100%"></td>
  </tr>
  <tr>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/explorer.jpg" width="100%"></td>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/lsp.jpg" width="100%"></td>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/ai_cmpl.jpg" width="100%"></td>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/themes.jpg" width="100%"></td>
  </tr>
  <tr>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/git_diff.jpg" width="100%"></td>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/gguf.jpg" width="100%"></td>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/termenu.jpg" width="100%"></td>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/term.jpg" width="100%"></td>
  </tr>
  
</table> 

---
<br>

## Building from source

This section is intended for users from countries like China where the Play Store isn't accessible. Otherwise, it is recommended to download the full-featured APK from the Play Store as mentioned above.<br>

The app has two branches:
- [playstore-version](https://github.com/heckmon/roxum-ide/tree/playstore-version) (Full Roxum IDE)
- [main](https://github.com/heckmon/roxum-ide/tree/playstore-version) (A light weight version)

Clone this repo, then:

### Building the full version
Make sure that [git-lfs](https://git-lfs.com/) is installed in your system and accessible via the `path`. Don't skip this step; the compilers and interpreters are stored in the GitHub large file storage.
#### 1) Build the app as an `aab` bundle or download the `release.aab` from the [releases](https://github.com/heckmon/roxum-ide/releases)

> [!NOTE]
> 
> To include all compilers, interpreters and extensions in the build, we build it as a standalone `aab` file, which is bigger compared to the APK downloaded from the Play Store. The Play Store build is smaller because these external dependencies are downloaded on demand when the user requests the particular compiler/interpreter/extension.

```bash
cd android && ./gradlew :app:bundleRelease
```
This will generate the output file in `build/app/outputs/bundle/release/app-release.aab`

#### 2) Building the APK
To install aab in your device, download the latest bundletool from the official repo:
https://github.com/google/bundletool/releases

Then build the APK:
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
  > This **is not** the full-featured Roxum IDE. This is a lightweight version.

  Roxum-lite lacks these features:
  - Dart compiler
  - Rust compiler
  - Go compiler
  - Lua interpreter
  - rust-analyzer
  - ty language server
  - emmyLua language server
  - gopls language server
  - SSH support
  - Termux support
  - External GGUF LLM models.

> For downloading the APK, go to the [releases](https://github.com/heckmon/roxum-ide/releases)

 The [main](https://github.com/heckmon/roxum-ide/tree/playstore-version) branch contains a lightweight version of Roxum, which is easy to build and run with Flutter or Gradle. This version is also available in the [releases](https://github.com/heckmon/roxum-ide/releases) as a standalone APK.
```bash
git checkout main
flutter run --release # Or flutter build apk --release
```
Or with Gradle

```bash
git checkout main
cd android && ./gradlew :app: assembleRelease
```

---

Special Thanks ♥️
- [@MaximoMachado](https://github.com/MaximoMachado) — helped fund the Play store release.
