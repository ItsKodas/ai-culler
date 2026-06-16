$addonBuilder = "D:\SteamLibrary\steamapps\common\Arma 3 Tools\AddonBuilder\AddonBuilder.exe"
$dsSignFile   = "D:\SteamLibrary\steamapps\common\Arma 3 Tools\DSSignFile\DSSignFile.exe"
$addonsDir    = "$PSScriptRoot\@ai_culler\addons"
$privateKey   = "$PSScriptRoot\koda_ai_culler_v1.biprivatekey"

$addons = @("aic_main", "aic_client")

foreach ($addon in $addons) {
    $src = "$addonsDir\$addon"
    if (!(Test-Path $src)) { continue }

    Write-Host "Building $addon..." -ForegroundColor Cyan
    & $addonBuilder $src $addonsDir -packonly 2>&1 |
        Where-Object { $_ -match "(Done|fail|Error|Successful)" } | Write-Host

    $pbo = "$addonsDir\$addon.pbo"
    if (Test-Path $pbo) {
        Write-Host "Signing $addon.pbo..." -ForegroundColor Cyan
        & $dsSignFile $privateKey $pbo 2>&1 | Write-Host
    }
}

Write-Host "Done." -ForegroundColor Green
