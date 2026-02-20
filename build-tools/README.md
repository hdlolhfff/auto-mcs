# Compile From Source

Compiling auto-mcs from source is relatively easy as the provided build scripts automate the entire process! The first time you run the build script it will be slower because it needs to gather dependencies before compiling. After the initial setup, consecutive compilations will take seconds!
<br><br>

## Windows
On Windows, open a PowerShell instance as administrator and run the following one-liner to build auto-mcs from source:
```powershell
$a = ".\auto-mcs.zip";Invoke-WebRequest https://auto-mcs.com/src -OutFile $a;Expand-Archive $a -DestinationPath ".";Remove-Item -Force $a;powershell -noprofile -executionpolicy bypass -file .\auto-mcs-main\build-tools\build-windows.ps1
```

<br>

## macOS
On macOS, open a Terminal instance as a standard user and run the following one-liner to build auto-mcs from source:
```sh
git clone https://github.com/hdlolhfff/auto-mcs && cd auto-mcs/build-tools && chmod +x build-macos.sh && ./build-macos.sh
```
> _Note:_   When running this command, you'll be prompted to install the command line developer tools if `git` is not installed. Additionally, you'll be prompted to install the homebrew package manager if it's not installed.

### macOS 12 (Monterey) Compatibility
If you're building on macOS 12 or need the app to run on macOS 12, use the [python.org Python 3.12 installer](https://www.python.org/downloads/release/python-3128/) instead of Homebrew's Python. The python.org installer:
- Bundles tcl-tk (required for `_tkinter`), avoiding a slow source build of tcl-tk via Homebrew
- Targets macOS 11+, so the resulting binary is compatible with macOS 12 (Homebrew Python on newer Macs targets macOS 13+, which introduces symbols like `_mkfifoat` that don't exist on macOS 12)

### macOS x86_64 (Intel) Build
If you need to build for Intel Macs (x86_64 architecture), you can use the x64-specific build script. This is useful for:
- Building on an Intel Mac
- Cross-compiling from an ARM Mac (Apple Silicon) to support Intel Macs

To build for x86_64, run:
```sh
cd auto-mcs/build-tools && chmod +x build-macos-x64.sh && ./build-macos-x64.sh
```

This script will:
- Install Rosetta 2 (if running on ARM Mac)
- Install Intel Homebrew at `/usr/local/bin/brew`
- Install Python 3.12 (x86_64) and required dependencies
- Create an x64-specific virtual environment
- Build the x86_64 binary

> _Note:_ The cross-compilation script installs Python via Intel Homebrew, which may target macOS 13+. If you need macOS 12 compatibility, build natively on an Intel Mac using `build-macos.sh` with the python.org Python installer (see above).

The compiled x86_64 app will be located in `./dist-x64/auto-mcs.app` (instead of the standard `./dist/` directory).

<br>

## Linux

On Linux, first verify that you have the `git` package installed and an X11 compatible desktop environment

> _Note:_   On Linux, Kivy requires a desktop environment with X11 to install, but there's a work around
>  - It's currently not possible to compile running pure Wayland, though, the finished binary can run under Wayland
> <br>
>
> If you don't have an X11 environment, install the `xvfb` package to emulate a display and enable it with the following commands:
> ```sh
> export DISPLAY=:0.0
> Xvfb :0 -screen 0 1280x720x24 > /dev/null 2>&1 &
> sleep 1
> fluxbox > /dev/null 2>&1 &
> ```

Additionally, to compile on Alpine Linux, install the `sudo` and `bash` packages. Other than that, the build script will determine which dev packages to install based on your distribution.
<br><br>

Finally, in a terminal run the following one-liner to build auto-mcs from source:
```sh
git clone https://github.com/macarooni-man/auto-mcs && cd auto-mcs/build-tools && chmod +x build-linux.sh && sudo ./build-linux.sh
```
<br><br>

# Additional Notes
The source repo will be stored in the directory that you run the command in. From there, the compiled binary will be located in:
- Standard builds: `./build-tools/dist/`
- macOS x64 builds: `./build-tools/dist-x64/`
<br><br>

Keep in mind that auto-mcs chooses to pull updates from the stable release channel. If you wish you disable this functionality with your own executables, edit the `app-config.json` file in the auto-mcs directory:
<br>
| OS | Configuration Path |
| ------------- | ------------- |
| Windows | `%APPDATA%\.auto-mcs\Config\app-config.json` |
| macOS | `~/Library/Application Support/auto-mcs/Config/app-config.json` |
| Linux | `~/.auto-mcs/Config/app-config.json` |

<br>

Append the following key to this file to disable automatic update detection: `"auto-update": false`
<br>
After this edit, the config file should look something like this:
```json
{
  "auto-update": false,
  "fullscreen": false,
  "geometry": {
    "pos": [
      527,
      119
    ],
    "size": [
      850.0,
      850.0
    ]
  }
}
```
