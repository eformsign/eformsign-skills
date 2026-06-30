$env:PYTHONUTF8 = "1"
$env:PYTHONIOENCODING = "utf-8"

$root = $PSScriptRoot
$dist = "$root\dist"
$skillCreator = "$env:USERPROFILE\.claude\skills\skill-creator"

Push-Location $skillCreator
python -m scripts.package_skill "$root\eformsign" "$dist"
python -m scripts.package_skill "$root\eformsign-user" "$dist"
Pop-Location
