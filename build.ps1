# Builds tf2c_mvm.sp -> tf2c_mvm.smx using the SourceMod 1.13 dev compiler.
# Usage:
#   .\build.ps1
#   .\build.ps1 -Spcomp "C:\path\to\spcomp64.exe"
param(
    [string]$Spcomp,
    [string]$Include,
    [string]$ProjectRoot = $PSScriptRoot
)

$SourceFile = Join-Path $ProjectRoot "tf2classified\tf2c_mvm\source\tf2c_mvm.sp"
$OutputFile = Join-Path $ProjectRoot "tf2classified\tf2c_mvm\plugins\tf2c_mvm.smx"

if (-not $Spcomp) {
    $Spcomp = "C:\Users\steam\steamapps\common\Team Fortress 2 Classified\tf2classified\addons\sourcemod\scripting\spcomp64.exe"
}
if (-not $Include) {
    $Include = Split-Path $Spcomp -Parent
    $Include = Join-Path $Include "include"
}

if (-not (Test-Path -LiteralPath $Spcomp)) {
    Write-Error "spcomp64.exe not found at '$Spcomp'. Pass -Spcomp with the correct path (SourceMod 1.13.0.7301 or newer, NOT 1.11 stable)."
    exit 1
}
if (-not (Test-Path -LiteralPath $SourceFile)) {
    Write-Error "Missing source: $SourceFile"
    exit 1
}

New-Item -ItemType Directory -Force -Path (Split-Path $OutputFile -Parent) | Out-Null

& $Spcomp "-i$Include" "-o$OutputFile" $SourceFile
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: $OutputFile" -ForegroundColor Green
} else {
    Write-Host "Compile failed with exit code $LASTEXITCODE" -ForegroundColor Red
}