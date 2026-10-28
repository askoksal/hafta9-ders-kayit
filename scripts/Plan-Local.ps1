param(
    [Parameter(Mandatory=$true)][string]$ImageRef,
    [Parameter(Mandatory=$true)][ValidatePattern('^[0-9a-f]{40}$')][string]$ExpectedCommit,
    [ValidateSet(1,2,3)][int]$Replicas=1,
    [string]$Banner='Hafta 9 Ders Kayıt Hizmeti'
)
. "$PSScriptRoot/Common.ps1"
Assert-LocalCluster
if ($ImageRef -notmatch '^ghcr\.io/[a-z0-9_.-]+/hafta9-ders-kayit@sha256:[0-9a-f]{64}$') {
    throw 'İmaj adresi ghcr.io/kullanici/hafta9-ders-kayit@sha256:... biçiminde tam digest içermelidir.'
}
Invoke-Native kubectl @('--context','docker-desktop','-n','hafta9','get','secret','ders-kayit-access','-o','name')
if ($Replicas -ne 1) { Write-Warning 'Bu yalnız ölçek gözlemidir; Pod bellekleri paylaşılmaz. Kayıt deneyini tek kopyada yapın.' }
$tfDir = Join-Path $RepoRoot 'infra/local'
$plan = Join-Path $LocalDir 'application.tfplan'
Invoke-Native terraform @("-chdir=$tfDir",'init','-input=false','-lockfile=readonly')
Invoke-Native terraform @("-chdir=$tfDir",'validate')
Invoke-Native terraform @("-chdir=$tfDir",'plan','-input=false',"-var=image_ref=$ImageRef", "-var=replicas=$Replicas", "-var=banner=$Banner", "-out=$plan")
Write-PlanRecord $plan $ImageRef $ExpectedCommit
Write-Host 'Plan kaydedildi. İnceledikten sonra Apply-Local.ps1 çalıştırın.'
