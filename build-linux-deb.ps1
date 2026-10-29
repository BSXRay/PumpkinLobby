param([switch]$Full)
Set-Location $PSScriptRoot
$zigDir = "C:\Users\119yu\Downloads\zig-x86_64-windows-0.17.0\zig-x86_64-windows-0.17.0"
if (-not (Get-Command zig -ErrorAction SilentlyContinue)) {
    if (Test-Path "$zigDir\zig.exe") { $env:PATH = "$zigDir;" + $env:PATH }
    else { throw "zig not found" }
}
if (-not $Full) {
    $env:CARGO_PROFILE_RELEASE_LTO = "off"
    $env:CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "16"
}
$target = "x86_64-unknown-linux-gnu"
cargo zigbuild --release -p pumpkin --target $target
if ($LASTEXITCODE -ne 0) { throw "cargo zigbuild failed" }
Push-Location "crates\pumpkin"
cargo deb --target $target --no-build --no-strip
$debExit = $LASTEXITCODE
Pop-Location
if ($debExit -ne 0) { throw "cargo deb failed" }
New-Item -ItemType Directory -Force -Path dist | Out-Null
$deb = Get-ChildItem "target\debian\*.deb" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($deb) { Copy-Item -Force $deb.FullName "dist\"; Write-Host "Built: dist\$($deb.Name)" }