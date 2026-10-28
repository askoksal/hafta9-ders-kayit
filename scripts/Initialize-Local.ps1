param([switch]$Apply)
. "$PSScriptRoot/Common.ps1"
Assert-LocalCluster
$tfDir = Join-Path $RepoRoot 'infra/bootstrap'
$plan = Join-Path $LocalDir 'bootstrap.tfplan'
Invoke-Native terraform @("-chdir=$tfDir",'init','-input=false','-lockfile=readonly')
if (-not $Apply) {
    Invoke-Native terraform @("-chdir=$tfDir",'plan','-input=false',"-out=$plan")
    Write-PlanRecord $plan
    Write-Host 'Planı inceleyin. Uygun bulursanız aynı betiği -Apply ile çalıştırın.'
    return
}
$null = Read-PlanRecord $plan
Invoke-Native terraform @("-chdir=$tfDir",'apply','-input=false',$plan)
Remove-Item -LiteralPath $plan,($plan+'.json')

# Bu Secret'ın sahibi bu hazırlık betiğidir. Terraform yalnız adını referans alır.
$tokenFile = Join-Path $LocalDir 'api-token.txt'
$secretName = (& kubectl --context docker-desktop -n hafta9 get secret ders-kayit-access --ignore-not-found -o name)
if ($LASTEXITCODE -ne 0) { throw 'Secret varlığı denetlenemedi; bağlantı ve izinleri kontrol edin.' }
$exists = (-not [string]::IsNullOrWhiteSpace($secretName))
if ($exists) {
    if (-not (Test-Path $tokenFile)) {
        throw 'Secret var fakat yerel belirteç dosyası yok. Otomatik değiştirilmedi; kurtarma/yenileme için yönergeye bakın.'
    }
    Write-Host 'Mevcut erişim Secret nesnesi korundu.'
    return
}
if (-not (Test-Path $tokenFile)) {
    $bytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    [IO.File]::WriteAllText($tokenFile,[Convert]::ToBase64String($bytes))
}
Invoke-Native kubectl @('--context','docker-desktop','-n','hafta9','create','secret','generic','ders-kayit-access',"--from-file=api-token=$tokenFile")
Write-Host 'Erişim belirteci .local/api-token.txt içinde oluşturuldu. Dosyayı paylaşmayın ve Git içine almayın.'
