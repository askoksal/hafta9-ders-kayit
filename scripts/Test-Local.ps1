# Docker Desktop açık olmalıdır. Python'un Windows'a kurulması gerekmez.
. "$PSScriptRoot/Common.ps1"
Push-Location $RepoRoot
try {
    Invoke-Native docker @('build','--target','test','-t','hafta9-tests:local','.')
    Invoke-Native docker @('run','--rm','--network','none','--read-only','--tmpfs','/tmp:rw,noexec,nosuid,size=32m',
        '--user','10001:10001','--cap-drop','ALL','--security-opt','no-new-privileges','hafta9-tests:local')
} finally { Pop-Location }
