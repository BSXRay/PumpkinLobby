# Build Pumpkin for Linux x64 and package as .deb.
# Requires: zig on PATH (or in Downloads), cargo-zigbuild, cargo-deb.
# Usage: .\build-linux-deb.ps1 [-Full]   (-Full enables LTO, slower)
param([switch]$Full)

Set-Location $PSScriptRoot

# Ensure zig is available
$zigDir = "C:\Users\119yu\Downloads\zig-x86_64-windows-0.17.0\zig-x86_64-windows-0.17.0"
if (-not (Get-Command zig -ErrorAction SilentlyContinue)) {
    if (Test-Path "$zigDir\zig.exe") {
        $env:PATH = "$zigDir;" + $env:PATH
    } else {
        throw "zig not found. Install zig or adjust zigDir in this script."
    }
}

if (-not $Full) {
    $env:CARGO_PROFILE_RELEASE_LTO = "off"
    $env:CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "16"
}

$target = "x86_64-unknown-linux-gnu"

# Build with zig as cross linker
cargo zigbuild --release -p pumpkin --target $target
if ($LASTEXITCODE -ne 0) { throw "cargo zigbuild failed with exit code $LASTEXITCODE" }

# Package prebuilt binary into a .deb
Push-Location "crates\pumpkin"
cargo deb --target $target --no-build --no-strip
$debExit = $LASTEXITCODE
Pop-Location
if ($debExit -ne 0) { throw "cargo deb failed with exit code $debExit" }

# Copy result to dist/
New-Item -ItemType Directory -Force -Path dist | Out-Null
$deb = Get-ChildItem "target\debian\*.deb" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($deb) {
    Copy-Item -Force $deb.FullName "dist\"
    Write-Host "Built: dist\$($deb.Name)"
} else {
    Write-Host "No .deb found in target\debian"
}