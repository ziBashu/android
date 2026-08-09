# Publish Flux warehub APK + update listing (uses WINDOWS tools script).
$ErrorActionPreference = 'Stop'
$py = Join-Path $env:USERPROFILE 'WINDOWS\tools\publish_flux_warehub.py'
if (-not (Test-Path $py)) { throw "Missing $py" }
python $py
