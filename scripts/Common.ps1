Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$LocalDir = Join-Path $RepoRoot '.local'

function Invoke-Native {
    param([Parameter(Mandatory=$true)][string]$Program, [string[]]$Arguments)
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Program başarısız. Çıkış kodu: $LASTEXITCODE" }
}

function Assert-LocalCluster {
    foreach ($cmd in @('terraform','kubectl')) {
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { throw "$cmd bulunamadı." }
    }
    $current = (& kubectl config current-context)
    if ($LASTEXITCODE -ne 0 -or $current.Trim() -ne 'docker-desktop') {
        throw 'Yalnız docker-desktop bağlamında çalışın. Önce hedefi doğrulayın.'
    }
    Invoke-Native kubectl @('--context','docker-desktop','cluster-info')
    New-Item -ItemType Directory -Force -Path $LocalDir | Out-Null
}

function Write-PlanRecord {
    param([string]$PlanFile, [string]$ImageRef='', [string]$ExpectedCommit='')
    @{
        plan_sha256=(Get-FileHash $PlanFile -Algorithm SHA256).Hash
        image_ref=$ImageRef
        expected_commit=$ExpectedCommit
        context='docker-desktop'
        namespace='hafta9'
    } | ConvertTo-Json | Set-Content -LiteralPath ($PlanFile + '.json') -Encoding UTF8
}

function Read-PlanRecord {
    param([string]$PlanFile)
    if (-not (Test-Path -LiteralPath $PlanFile) -or -not (Test-Path -LiteralPath ($PlanFile+'.json'))) {
        throw 'Önce planlama adımını tamamlayın.'
    }
    $record = Get-Content -Raw -LiteralPath ($PlanFile+'.json') | ConvertFrom-Json
    if ($record.context -ne 'docker-desktop' -or $record.namespace -ne 'hafta9' -or
        $record.plan_sha256 -ne (Get-FileHash $PlanFile -Algorithm SHA256).Hash) {
        throw 'Plan kaydı tutarsız. Planı yeniden üretip inceleyin.'
    }
    return $record
}
