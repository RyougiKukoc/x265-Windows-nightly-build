# x265 Windows nightly build

Download-ready x265 x86_64 multilib CLI builds from the current
[`Multicorewareinc/x265`](https://github.com/Multicorewareinc/x265) `master`
commit.

## Release contents

Only the MSVC build is published to GitHub Releases:

- `x265-windows-x86_64-msvc-multilib.zip`: an x64 MSVC 2022 build containing
  `x265.exe` with 8-, 10-, and 12-bit support, plus `COPYING`.

The ZIP is for standalone encoding. It does not include `x265.dll`, an import
library, or development headers. The executable uses the static MSVC runtime.

The MinGW GCC build script is retained as a verified reference and its workflow
can be run manually for build verification, but it intentionally does not
publish GitHub Release assets.

## Build characteristics

- All release builds target x86_64 with Visual Studio 2022 and NASM.
- The 8-bit CLI links the separately built 10- and 12-bit static libraries to
  provide one multilib executable.
- `ENABLE_SHARED=OFF` keeps the release focused on the command-line encoder.

## Local validation

Install the Visual Studio 2022 C++ workload, CMake, and NASM. Clone the desired
x265 source checkout, then run:

```powershell
.\scripts\build-windows-multilib-msvc.ps1 -SourceDir ..\x265 -OutputDir .\dist\multilib
```

The command validates `x265.exe --version` and confirms that the executable is
an 8+10+12-bit multilib build. The resulting ZIP is written beside the supplied
x265 source checkout.

## License

The `x265.exe` executable in each release is built from upstream x265 and is
distributed under [GPL-2.0-only](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html).
The complete license text is included as `COPYING` in every ZIP. The
corresponding source is the upstream commit linked from that release's notes.
This repository does not grant a Multicoreware commercial x265 license.
