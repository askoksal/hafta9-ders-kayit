param([switch]$Apply,[string]$ConfirmNamespace='')
. "$PSScriptRoot/Common.ps1"
Assert-LocalCluster
$appDir = Join-Path $RepoRoot 'infra/local'
$bootstrapDir = Join-Path $RepoRoot 'infra/bootstrap'
$appPlan = Join-Path $LocalDir 'remove-application.tfplan'
$bootstrapPlan = Join-Path $LocalDir 'remove-bootstrap.tfplan'
if (-not $Apply) {
    $recordFile = Join-Path $LocalDir 'last-deployment.json'
    if (-not (Test-Path $recordFile)) { throw 'Dağıtım kaydı yok. docs/SORUN-GIDERME.md içindeki kısmi işlem yolunu kullanın.' }
    $record = Get-Content -Raw $recordFile | ConvertFrom-Json
    Invoke-Native terraform @("-chdir=$appDir",'init','-input=false','-lockfile=readonly')
    Invoke-Native terraform @("-chdir=$appDir",'plan','-destroy','-input=false',"-var=image_ref=$($record.image_ref)","-out=$appPlan")
    Write-PlanRecord $appPlan
    Invoke-Native terraform @("-chdir=$bootstrapDir",'init','-input=false','-lockfile=readonly')
    Invoke-Native terraform @("-chdir=$bootstrapDir",'plan','-destroy','-input=false',"-out=$bootstrapPlan")
    Write-PlanRecord $bootstrapPlan
    Write-Host 'Planları inceleyin. hafta9 ad alanı ve içindeki Secret dahil tüm nesneler kaldırılacaktır.'
    Write-Host 'Uygunsa: .\scripts\Remove-Local.ps1 -Apply -ConfirmNamespace hafta9'
    return
}
if ($ConfirmNamespace -cne 'hafta9') { throw '-ConfirmNamespace hafta9 açık onayı gereklidir.' }
$null = Read-PlanRecord $appPlan
$null = Read-PlanRecord $bootstrapPlan
Invoke-Native terraform @("-chdir=$appDir",'apply','-input=false',$appPlan)
Invoke-Native terraform @("-chdir=$bootstrapDir",'apply','-input=false',$bootstrapPlan)
foreach ($file in @($appPlan,($appPlan+'.json'),$bootstrapPlan,($bootstrapPlan+'.json'),(Join-Path $LocalDir 'api-token.txt'),(Join-Path $LocalDir 'last-deployment.json'))) {
    if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file }
}
Write-Host 'Uygulama ve hafta9 ad alanı kaldırıldı. Küme, diğer haftalar ve GHCR imajları korunmuştur.'
