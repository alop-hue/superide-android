# Roxum IDE

Roxum IDE es un editor de código e IDE ligero diseñado principalmente para dispositivos móviles Android, desarrollado con Flutter.
Combina edición de código, flujos de trabajo en terminal, herramientas Git/GitHub, asistencia con IA, descarga de runtimes y personalización avanzada en una sola aplicación.

#### Roxum utiliza el potente paquete [code_forge](https://github.com/heckmon/code_forge) como motor del editor.

<a href="https://play.google.com/store/apps/details?id=com.roxum">
  <img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" height="60">
</a>

## Novedades en la versión 2:

* **Se agregó soporte SSH para conectarse a sistemas remotos.**
* **Se agregó soporte integrado para Termux, permitiendo usar Termux como backend.**
* **Opción para descargar y cargar modelos GGUF LLM locales para chat offline y autocompletado de código, solicitado en [#9](https://github.com/heckmon/roxum-ide/issues/9) y [#16](https://github.com/heckmon/roxum-ide/issues/16).**
* **Se agregó una barra de búsqueda para temas, solicitado en [#11](https://github.com/heckmon/roxum-ide/issues/11).**
* **Migración del backend del [editor](https://github.com/heckmon/code_forge) a Rust.**
* **JDT-LS fue reemplazado por kmp-lsp, ofreciendo soporte LSP para Java, Kotlin y Swift.**
* **Corregidos los problemas [#15](https://github.com/heckmon/roxum-ide/issues/15) y [#14](https://github.com/heckmon/roxum-ide/issues/14). Si el problema persiste, puede utilizarse Termux.**
* **[#10](https://github.com/heckmon/roxum-ide/issues/10) y [#18](https://github.com/heckmon/roxum-ide/issues/18) pueden resolverse usando el nuevo backend de Termux.**

### Galería

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

# Si Play Store no está disponible en tu país:

## Descarga el APK completo desde [releases](https://github.com/heckmon/roxum-ide/releases)

#### O

## Compilar desde el código fuente

Esta sección está dirigida a usuarios de países como China, donde Play Store no es accesible. En otros casos, se recomienda descargar el APK completo desde Play Store, como se indicó anteriormente.<br>

Clona este repositorio y luego:

Asegúrate de que [git-lfs](https://git-lfs.com/) esté instalado en tu sistema y accesible mediante el `path`. No omitas este paso, ya que los compiladores e intérpretes están almacenados en GitHub Large File Storage.

#### 1) Compilar la aplicación como paquete `aab`.

> [!NOTE]
>
> Para incluir todos los compiladores, intérpretes y extensiones, se genera un archivo `aab` independiente, que es más grande en comparación con el APK descargado desde Play Store. La versión de Play Store es más pequeña porque estas dependencias externas se descargan bajo demanda cuando el usuario solicita un compilador, intérprete o extensión específicos.

```bash
cd android && ./gradlew :app:bundleRelease
```

Esto generará el archivo:

`build/app/outputs/bundle/release/app-release.aab`

#### 2) Crear APK desde AAB

Para instalar un archivo AAB en tu dispositivo, primero debe convertirse a APK. Descarga la versión más reciente de bundletool desde el repositorio oficial:

https://github.com/google/bundletool/releases

Luego genera el APK:

```bash
java -jar path/to/bundletool.jar build-apks --bundle=your_app/build/app/outputs/bundle/release/app-release.aab --output=output.apks --mode=universal
```

Esto generará:

`output.apks`

#### 3) Instalar los APKs

Asegúrate de estar conectado a un emulador o dispositivo físico mediante `adb`.

```bash
java -jar /path/to/bundletool.jar install-apks --apks=output.apks
```

---

Agradecimiento especial ♥️

* [@MaximoMachado](https://github.com/MaximoMachado) — ayudó a financiar el lanzamiento en Play Store.
