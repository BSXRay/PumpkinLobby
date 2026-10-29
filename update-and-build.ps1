# Fetch latest upstream Pumpkin, apply local patches, build.
param([switch]$Windows, [switch]$LinuxDeb, [switch]$Full)

Set-Location $PSScriptRoot

git fetch upstream master
if ($LASTEXITCODE -ne 0) { throw "git fetch failed" }

git checkout --detach upstream/master
if ($LASTEXITCODE -ne 0) { throw "checkout failed" }

# Apply patches
$patches = Get-ChildItem "patches\*.patch" | Sort-Object Name
foreach ($p in $patches) {
    git am $p.FullName
    if ($LASTEXITCODE -ne 0) { throw "git am failed on $($p.Name)" }
}

if ($Windows) { .\build-windows.ps1 @PSBoundParameters }
if ($LinuxDeb) { .\build-linux-deb.ps1 @PSBoundParameters }

Write-Host "Done."