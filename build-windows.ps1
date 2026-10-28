# Build Pumpkin for Windows x64.
# Usage: .\build-windows.ps1 [-Full]   (-Full enables LTO, slower)
param([switch]$Full)

Set-Location $PSScriptRoot

if (-not $Full) {
    # Faster local builds: disable fat LTO.
    $env:CARGO_PROFILE_RELEASE_LTO = "off"
    $env:CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "16"
}

cargo build --release -p pumpkin
if ($LASTEXITCODE -ne 0) { throw "cargo build failed with exit code $LASTEXITCODE" }

New-Item -ItemType Directory -Force -Path dist | Out-Null
Copy-Item -Force "target\release\pumpkin.exe" "dist\pumpkin-windows-x64.exe"
Write-Host "Built: dist\pumpkin-windows-x64.exe"