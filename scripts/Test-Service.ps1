. "$PSScriptRoot/Common.ps1"
Assert-LocalCluster
$recordPath = Join-Path $LocalDir 'last-deployment.json'
if (-not (Test-Path $recordPath)) { throw 'Önce Apply-Local.ps1 tamamlanmalıdır.' }
$record = Get-Content -Raw $recordPath | ConvertFrom-Json
$actualImage = (& kubectl --context docker-desktop -n hafta9 get deployment ders-kayit -o 'jsonpath={.spec.template.spec.containers[0].image}')
if ($LASTEXITCODE -ne 0 -or $actualImage -ne $record.image_ref) { throw 'Dağıtım imajı kaydedilen digest ile eşleşmiyor.' }
$health = Invoke-RestMethod 'http://127.0.0.1:8080/readyz'
if ($health.status -ne 'ok') { throw 'Hazır olma kontrolü başarısız.' }
$version = Invoke-RestMethod 'http://127.0.0.1:8080/version'
if ($version.commit -ne $record.expected_commit) { throw 'Çalışan kaynak commit beklenen değerle eşleşmiyor.' }
$null = Invoke-RestMethod 'http://127.0.0.1:8080/api/courses'
Write-Host "Hazır olma, imaj digest ve kaynak sürümü doğrulandı. Sürüm: $($version.version)"
