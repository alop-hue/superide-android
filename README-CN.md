# Roxum IDE

Roxum IDE 是一款专为 Android 打造、基于 Flutter 开发的移动优先代码编辑器和迷你 IDE。
它将代码编辑、终端工作流、Git/GitHub 工具、AI 辅助、运行时下载以及深度自定义功能整合到一个应用中。

#### Roxum 使用强大的 [code_forge](https://github.com/heckmon/code_forge) 软件包作为编辑器引擎。

<a href="https://play.google.com/store/apps/details?id=com.roxum">
  <img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" height="60">
</a>

## 版本 2 新内容：

* **新增 SSH 支持，可连接远程系统。**
* **新增内置 Termux 支持，可将 Termux 作为后端使用。**
* **支持下载并加载本地 GGUF LLM 模型，用于离线聊天和代码补全（参考 [#9](https://github.com/heckmon/roxum-ide/issues/9) 和 [#16](https://github.com/heckmon/roxum-ide/issues/16)）。**
* **根据 [#11](https://github.com/heckmon/roxum-ide/issues/11) 的请求，新增主题搜索栏。**
* **将 [编辑器](https://github.com/heckmon/code_forge) 后端迁移至 Rust。**
* **将 JDT-LS 替换为 kmp-lsp，为 Java、Kotlin 和 Swift 提供 LSP 支持。**
* **修复了 [#15](https://github.com/heckmon/roxum-ide/issues/15) 和 [#14](https://github.com/heckmon/roxum-ide/issues/14)。如果问题仍然存在，可以使用 Termux。**
* **[#10](https://github.com/heckmon/roxum-ide/issues/10) 和 [#18](https://github.com/heckmon/roxum-ide/issues/18) 可通过新的 Termux 后端解决。**

### 展示图集

<table>
  <tr>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/home.jpg" width="100%"></td>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/ag.jpg" width="100%"></td>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/ag_diff.jpg" width="100%"></td>
    <td><img src="https://raw.githubusercontent.com/heckmon/android-arm64-shared-libraries/refs/heads/main/scrnshots/rt-roxum.jpg" width="100%"></td>
  </tr>
</table>

---

<br>

# 如果 Play Store 在你的国家无法访问：

## 从 [releases](https://github.com/heckmon/roxum-ide/releases) 下载完整 APK

#### 或者

## 从源码构建

本部分主要面向中国等无法访问 Play Store 的用户。否则，建议直接从 Play Store 下载上方提到的完整功能 APK。<br>

克隆此仓库后：

请确保系统中已安装 [git-lfs](https://git-lfs.com/)，并且可通过 `path` 访问。不要跳过此步骤，因为编译器和解释器存储在 GitHub Large File Storage 中。

#### 1) 将应用构建为 `aab` 包。

> [!NOTE]
>
> 为了包含所有编译器、解释器和扩展，我们将其构建为独立的 `aab` 文件，因此体积比从 Play Store 下载的 APK 更大。Play Store 版本较小，因为外部依赖会在用户需要特定编译器/解释器/扩展时按需下载。

```bash
cd android && ./gradlew :app:bundleRelease
```

生成文件位置：

`build/app/outputs/bundle/release/app-release.aab`

#### 2) 从 AAB 创建 APK

要在设备上安装 AAB，需要先转换为 APK。请先从官方仓库下载最新 bundletool：

https://github.com/google/bundletool/releases

然后构建 APK：

```bash
java -jar path/to/bundletool.jar build-apks --bundle=your_app/build/app/outputs/bundle/release/app-release.aab --output=output.apks --mode=universal
```

会在当前目录生成：

`output.apks`

#### 3) 安装 APK 文件

请确保已通过 `adb` 连接模拟器或实体设备。

```bash
java -jar /path/to/bundletool.jar install-apks --apks=output.apks
```

---

特别感谢 ♥️

* [@MaximoMachado](https://github.com/MaximoMachado) — 帮助资助了 Play Store 发布。
