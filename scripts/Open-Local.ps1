. "$PSScriptRoot/Common.ps1"
Assert-LocalCluster
Write-Host 'http://127.0.0.1:8080 — bu pencereyi açık tutun; bitirmek için Ctrl+C.'
Invoke-Native kubectl @('--context','docker-desktop','-n','hafta9','port-forward','--address','127.0.0.1','service/ders-kayit','8080:80')
