. "$PSScriptRoot/Common.ps1"
Assert-LocalCluster
$tfDir = Join-Path $RepoRoot 'infra/local'
$plan = Join-Path $LocalDir 'application.tfplan'
$record = Read-PlanRecord $plan
Invoke-Native terraform @("-chdir=$tfDir",'apply','-input=false',$plan)
Invoke-Native kubectl @('--context','docker-desktop','-n','hafta9','rollout','status','deployment/ders-kayit','--timeout=180s')
$record | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $LocalDir 'last-deployment.json') -Encoding UTF8
Remove-Item -LiteralPath $plan,($plan+'.json')
Write-Host 'Dağıtım tamamlandı. Open-Local.ps1 ile erişimi açıp ayrı terminalde Test-Service.ps1 çalıştırın.'
