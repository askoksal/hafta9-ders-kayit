# Hafta 9 Ders Kayıt Hizmeti

Bu paket Git → CI → imaj kayıt deposu → Terraform → Kubernetes akışının yerel temelidir.
Kod hazırdır; öğrenci küçük değişiklikler yaparak süreci gözlemler. Ayrıntılı Ek 1–3 henüz
bu paketin parçası değildir. Teknik sözleşme: [docs/TASARIM.md](docs/TASARIM.md).
Test kapsamı ve sınırları: [docs/DOGRULAMA.md](docs/DOGRULAMA.md).

## Ön Koşullar

Önceki haftalarda kurulan Docker Desktop ve içindeki Kubernetes kullanılacak. Minikube yoktur.
Windows PowerShell 5.1 veya PowerShell 7, Git ve Terraform 1.17.0 gerekir.
Git yönergeleri güncel Git 2.56.0 / Git for Windows 2.56.0(2) esas alınarak hazırlanacaktır.
Bu paketin yerel test ortamındaki Git sürümü farklı olabilir; raporda açıkça belirtilir.
GitHub hesabı, internet ve herkese açık örnek kod/paket yayımlama imkânı gerekir.
İkinci bir Docker Hub hesabı veya yerel Python kurulumu gerekmez.

## İlk Test

ZIP'i kullanıcı dizininizde ayrı bir klasöre açın ve PowerShell'de bu README'nin bulunduğu
proje köküne geçin. Çalışma klasörü adı ve içinde boşluk bulunması betiklerle desteklenir.

```powershell
docker version
kubectl config get-contexts
kubectl config use-context docker-desktop
kubectl get nodes
git --version
terraform version
.\scripts\Test-Local.ps1
```

Beklenen sonuç: uygulama testlerinin başarıyla tamamlanması. Kişisel veya kurumsal
PowerShell yürütme politikası betiği engellerse kurumun onaylı yöntemini kullanın;
sistem genelinde politika veya güvenlik duvarı kapatma yönergesi verilmez.

## GitHub ve CI

GitHub'da `hafta9-ders-kayit` adında boş, public depo oluşturun. İçinde README, lisans veya
başlangıç commit'i oluşturmayın. Aşağıdaki kullanıcı adını kendi hesabınızla değiştirin.

```powershell
git init -b main
git add .
git status
git commit -m "Hafta 9 uygulama temelini ekle"
git remote add origin https://github.com/KULLANICI/hafta9-ders-kayit.git
git push -u origin main
```

Önceden `git config --global user.name` ve `user.email` ayarlanmış olmalıdır.
GitHub bağlantısında tarayıcı tabanlı kimlik doğrulama kullanılabilir; hesap parolasıyla
Git HTTPS oturumu beklenmez. Gizli değer içeren dosya görürseniz commit yapmadan durun.
İlk push testleri ve koşullu yayımlamayı başlatır. Sonraki çalışmalar ayrı dal ve
birleştirme isteği üzerinden yapılır. `Uygulama Testleri` ve `Terraform Kontrolleri`
başarılı olmadan `Dogrulanan Imaji Yayimla` çalışmaz. Dal koruma kuralını Ek 1'de kuracağız.

GitHub Actions çalışmasının özetinde tam kaynak commit ve digest ile imaj adresi yer alır.
GitHub profilinizde Packages içinden **yalnız bu örnek paketin** görünürlüğünü public yapın.
Bu tercih için gereken adımlar Ek 1'de ayrıntılandırılacak. Özel paket doğrudan çekilemez.

## Terraform ile Yerel Dağıtım

Önce ad alanı planını üretip inceleyin; ikinci komut daha önce kaydedilen planı uygular ve
yerel erişim Secret'ını hazırlar. `hafta9` ad alanını yalnız bu proje için kullanın.

```powershell
.\scripts\Initialize-Local.ps1
.\scripts\Initialize-Local.ps1 -Apply
```

İmaj adresi ve commit'i Actions özetinden alın. Aşağıdaki yer tutucular gerçek değerlerle değişmelidir.

```powershell
$imageRef = 'ghcr.io/KULLANICI/hafta9-ders-kayit@sha256:TAM_DIGEST'
$sourceCommit = '40_KARAKTERLIK_KAYNAK_COMMIT'
.\scripts\Plan-Local.ps1 -ImageRef $imageRef -ExpectedCommit $sourceCommit
.\scripts\Apply-Local.ps1
.\scripts\Open-Local.ps1
```

İmaj adresinde kullanıcı adı küçük harftir. `latest` veya başka etiket dağıtım girdisi olarak kabul edilmez.
Plan ve uygulama arasında kaynak değişmişse Terraform hata verebilir; eski planı zorlamayın.
Yeni plan üretip tekrar inceleyin. Open-Local penceresi açıkken farklı PowerShell penceresinde:

```powershell
.\scripts\Test-Service.ps1
```

Tarayıcı: http://127.0.0.1:8080 . Belirteç gerektiğinde yalnız kendi bilgisayarınızda
`.local/api-token.txt` dosyasından okunur; ekran görüntüsüne, rapora veya sohbet mesajına eklenmez.
Sürüm değişikliği için yeni imajla Plan-Local ve Apply-Local tekrar çalıştırılır.
Başlık değişikliği için `-Banner 'Yeni Başlık'` verilir. Kopya sayısı deneyi `-Replicas 2`
ile yapılabilir; ardından 1'e dönülür. Çok kopyada kayıt tutarlılığı beklenmez.

## Kaldırma

Port yönlendirme penceresinde Ctrl+C yapın. Planı inceleyin, ardından açık onayla uygulayın:

```powershell
.\scripts\Remove-Local.ps1
.\scripts\Remove-Local.ps1 -Apply -ConfirmNamespace hafta9
```

`hafta9` içindeki bütün kaynaklar ve yerel belirteç kaldırılır. Diğer haftaların ad alanları,
Docker Desktop kümesi ve GHCR imajları silinmez. GHCR paket temizliği ayrı yapılır.
Kısmi hata durumları için [sorun giderme](docs/SORUN-GIDERME.md) belgesine bakın.
