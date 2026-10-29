# PaperMC-style build: fetch upstream Pumpkin, apply patches, build.
param(
    [switch]$Windows,
    [switch]$LinuxDeb,
    [switch]$Full,
    [string]$Upstream = "https://github.com/Pumpkin-MC/Pumpkin.git"
)

Set-Location $PSScriptRoot

$work = Join-Path $PSScriptRoot "work\pumpkin"
if (-not (Test-Path "$work\.git")) {
    New-Item -ItemType Directory -Force -Path (Split-Path $work) | Out-Null
    git clone $Upstream $work
    if ($LASTEXITCODE -ne 0) { throw "clone failed" }
}

Push-Location $work
git fetch origin master
git reset --hard origin/master
if ($LASTEXITCODE -ne 0) { throw "reset failed" }

# Apply patches
$patches = Get-ChildItem "$PSScriptRoot\patches\*.patch" | Sort-Object Name
foreach ($p in $patches) {
    git am --3way $p.FullName
    if ($LASTEXITCODE -ne 0) { throw "git am failed on $($p.Name)" }
}
Pop-Location

# Build
if ($Windows) {
    Push-Location $work
    if (-not $Full) {
        $env:CARGO_PROFILE_RELEASE_LTO = "off"
        $env:CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "16"
    }
    cargo build --release -p pumpkin
    if ($LASTEXITCODE -ne 0) { throw "build failed" }
    New-Item -ItemType Directory -Force -Path "$PSScriptRoot\dist" | Out-Null
    Copy-Item -Force "$work\target\release\pumpkin.exe" "$PSScriptRoot\dist\pumpkin-windows-x64.exe"
    Pop-Location
    Write-Host "Built: dist\pumpkin-windows-x64.exe"
}

if ($LinuxDeb) {
    $zigDir = "C:\Users\119yu\Downloads\zig-x86_64-windows-0.17.0\zig-x86_64-windows-0.17.0"
    if (-not (Get-Command zig -ErrorAction SilentlyContinue)) {
        if (Test-Path "$zigDir\zig.exe") { $env:PATH = "$zigDir;" + $env:PATH }
        else { throw "zig not found" }
    }
    Push-Location $work
    if (-not $Full) {
        $env:CARGO_PROFILE_RELEASE_LTO = "off"
        $env:CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "16"
    }
    $target = "x86_64-unknown-linux-gnu"
    cargo zigbuild --release -p pumpkin --target $target
    if ($LASTEXITCODE -ne 0) { throw "zigbuild failed" }
    Push-Location "crates\pumpkin"
    cargo deb --target $target --no-build --no-strip
    $debExit = $LASTEXITCODE
    Pop-Location
    if ($debExit -ne 0) { throw "cargo deb failed" }
    New-Item -ItemType Directory -Force -Path "$PSScriptRoot\dist" | Out-Null
    $deb = Get-ChildItem "$work\target\debian\*.deb" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($deb) { Copy-Item -Force $deb.FullName "$PSScriptRoot\dist\"; Write-Host "Built: dist\$($deb.Name)" }
    Pop-Location
}

Write-Host "Done."