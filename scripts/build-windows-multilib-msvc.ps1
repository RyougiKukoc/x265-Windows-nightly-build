param(
    [Parameter(Mandatory = $true)][string]$SourceDir,
    [Parameter(Mandatory = $true)][string]$OutputDir
)
$ErrorActionPreference = 'Stop'

$SourceDir = (Resolve-Path $SourceDir).Path
$OutputDir = [IO.Path]::GetFullPath($OutputDir)
$Generator = 'Visual Studio 17 2022'
$Nasm = 'C:\Program Files\NASM\nasm.exe'
if (-not (Test-Path $Nasm)) { $Nasm = (Get-Command nasm -ErrorAction Stop).Source }
$Common = @('-G', $Generator, '-A', 'x64', '-DENABLE_ASSEMBLY=ON', "-DCMAKE_ASM_NASM_COMPILER=$Nasm", "-DNASM_EXECUTABLE=$Nasm", '-DENABLE_SHARED=OFF', '-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded')

New-Item -ItemType Directory -Force -Path "$OutputDir\12bit", "$OutputDir\10bit", "$OutputDir\8bit" | Out-Null

cmake -S "$SourceDir\source" -B "$OutputDir\12bit" @Common -DHIGH_BIT_DEPTH=ON -DMAIN12=ON -DEXPORT_C_API=OFF -DENABLE_CLI=OFF
cmake --build "$OutputDir\12bit" --config Release --parallel
Copy-Item "$OutputDir\12bit\Release\x265-static.lib" "$OutputDir\8bit\x265_main12.lib" -Force

cmake -S "$SourceDir\source" -B "$OutputDir\10bit" @Common -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_CLI=OFF
cmake --build "$OutputDir\10bit" --config Release --parallel
Copy-Item "$OutputDir\10bit\Release\x265-static.lib" "$OutputDir\8bit\x265_main10.lib" -Force

$Cache = @"
set(EXTRA_LIB "x265_main10.lib;x265_main12.lib" CACHE STRING "" FORCE)
set(EXTRA_LINK_FLAGS "" CACHE STRING "" FORCE)
set(LINKED_10BIT ON CACHE BOOL "" FORCE)
set(LINKED_12BIT ON CACHE BOOL "" FORCE)
"@
$CachePath = "$OutputDir\8bit\init.cmake"
Set-Content -Path $CachePath -Value $Cache -Encoding ascii
cmake -S "$SourceDir\source" -B "$OutputDir\8bit" -C "$CachePath" @Common -DENABLE_CLI=ON
cmake --build "$OutputDir\8bit" --config Release --parallel

$Exe = "$OutputDir\8bit\Release\x265.exe"
if (-not (Test-Path $Exe)) { throw "x265.exe was not generated" }
& $Exe --version
if ($LASTEXITCODE -ne 0) { throw "x265.exe --version failed with exit code $LASTEXITCODE" }
$Version = (& $Exe --version 2>&1 | Out-String)
if ($Version -notmatch '8bit\+10bit\+12bit') { throw "The executable is not a multilib build: $Version" }

$PackageDir = "$OutputDir\package"
New-Item -ItemType Directory -Force -Path $PackageDir | Out-Null
Copy-Item $Exe "$PackageDir\x265.exe" -Force
Copy-Item "$SourceDir\COPYING" "$PackageDir\COPYING" -Force
$Zip = "$SourceDir\x265-windows-x86_64-msvc-multilib.zip"
Remove-Item $Zip -Force -ErrorAction SilentlyContinue
Compress-Archive -Path "$PackageDir\*" -DestinationPath $Zip -Force
Write-Output "PACKAGE=$Zip"
