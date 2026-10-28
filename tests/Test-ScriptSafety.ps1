# Gerçek kümeye bağlanmaz. Yalnız yerel koruma kontrollerini sınar.
. "$PSScriptRoot/../scripts/Common.ps1"
$checks = 0
function terraform { $global:LASTEXITCODE = 0 }
function kubectl { $global:LASTEXITCODE = 0; 'unexpected-cloud-context' }
$caught = $false
try { Assert-LocalCluster } catch {
    if ($_.Exception.Message -notmatch 'docker-desktop') { throw }
    $caught = $true
}
if (-not $caught) { throw 'Yanlış küme engellenmedi.' }
$checks++

$tempDir = Join-Path ([IO.Path]::GetTempPath()) ('hafta9-check-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tempDir | Out-Null
try {
    $planFile = Join-Path $tempDir 'test.tfplan'
    Set-Content $planFile 'example'
    Write-PlanRecord $planFile 'test-image' 'test-commit'
    $record = Read-PlanRecord $planFile
    if ($record.image_ref -ne 'test-image') { throw 'Plan kaydı okunamadı.' }
    $checks++
    Add-Content $planFile 'changed'
    $caught = $false
    try { $null = Read-PlanRecord $planFile } catch {
        if ($_.Exception.Message -notmatch 'tutarsız') { throw }
        $caught = $true
    }
    if (-not $caught) { throw 'Değiştirilmiş plan engellenmedi.' }
    $checks++
} finally { Remove-Item -Recurse -Force -LiteralPath $tempDir }

function Fail-Example { $global:LASTEXITCODE = 7 }
$caught = $false
try { Invoke-Native Fail-Example @() } catch {
    if ($_.Exception.Message -notmatch '7') { throw }
    $caught = $true
}
if (-not $caught) { throw 'Komut hatası durdurulmadı.' }
$checks++
if ($checks -ne 4) {
    throw "Beklenen dört güvenlik kontrolü tamamlanmadı."
}

# Beklenen hata deneyinden kalan çıkış kodunu temizle.
$global:LASTEXITCODE = 0

Write-Host "$checks betik güvenlik kontrolü geçti. Gerçek küme kullanılmadı."