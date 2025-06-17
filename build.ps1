[CmdletBinding()]
param (
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Stop'

function Step {
    param (
        [string]$Message
    )

    Write-Host "=== $Message ==="
}

$BaseDir = Get-Location

$SourceDir = Join-Path $BaseDir "source"
$BuildDir = Join-Path $BaseDir "build"
$InstallDir = Join-Path $BaseDir "install"
$OutputFile = Join-Path $BaseDir "LLVM.zip"

$CMakeGenerator = "Visual Studio 17 2022"

$Version = "20.1.7"
$LLVMProjects = "clang;clang-tools-extra"
$LLVMTargets = "X86;AArch64"

Step "Cloning LLVM $Version"
if (Test-Path "$SourceDir") {
    Write-Host "LLVM already cloned"
}
else {
    git clone --depth 1 --branch llvmorg-$Version https://github.com/llvm/llvm-project.git "$SourceDir"
}

Step "Configuring"

New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

$LLVMDir = Join-Path $SourceDir "llvm"

cmake `
    -G $CMakeGenerator -Thost=x64 -B $BuildDir -S $LLVMDir `
    -DCMAKE_BUILD_TYPE=Release `
    -DCMAKE_INSTALL_PREFIX=$InstallDir `
    -DLLVM_ENABLE_PROJECTS="$LLVMProjects" `
    -DLLVM_TARGETS_TO_BUILD="$LLVMTargets" `
    "$SourceDir\llvm"

Step "Building"

cmake --build $BuildDir --config Release --parallel --target install

Step "Compressing result"

Compress-Archive -Path "$InstallDir\*" -DestinationPath $OutputFile