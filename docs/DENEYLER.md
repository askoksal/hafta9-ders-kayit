# Ek 2 İçin Hazır Deneyler

Bu kısa liste ayrıntılı Ek 2'nin yerini almaz; kod paketindeki denenecek davranışları tanımlar.

## 1 Hata ve Düzeltme

```powershell
git switch -c deney/kontenjan
```

`app/__init__.py` içinde BULUT101 kontenjanını 2'den 3'e değiştirin. Testleri değiştirmeyin.
Yerel test betiği hata vermelidir. Değişikliği kaydedip dalı gönderin ve GitHub'da birleştirme isteği açın.
CI'nin başarısız kontrolünü inceleyin. Bu bozuk değişikliği main dalına birleştirmeyin.
Kontenjanı yeniden 2 yapıp yeni commit gönderin; CI yeniden çalışıp başarılı olmalıdır.
Gerekli depo koruması Ek 1'de kurulacaktır; yalnız ekran rengi bir yetki sınırı değildir.

## 2 Yeni Uygulama Sürümü

Ayrı dalda Dockerfile'daki `APP_VERSION` varsayılanını 1.0.1 yapın. Uygulama kodunun
test yapılandırmasındaki varsayılanı değiştirmek gerekmez; çalışma sürümü imaja ortam değeriyle yazılır.
CI geçtikten ve main'e birleştirildikten sonra yeni digest ve 40 karakterli commit'i alın.
Plan-Local, Apply-Local ve Test-Service adımlarını tekrarlayın. Tarayıcıda yeni sürümü görün.
Eski kayıtların kaybolması bu bellek tabanlı hizmetin beklenen sınırıdır.

## 3 Yapılandırma ve Kopya Sayısı

Aynı digest ve commit ile Plan-Local'a farklı `-Banner` verin. Plan ConfigMap ve Pod şablonundaki
yapılandırma özetini değiştirmelidir. Apply sonrası ekran başlığı değişir; imaj yeniden oluşturulmaz.
Ardından yalnız gözlem için `-Replicas 2` kullanın, Pod sayısını inceleyin ve 1'e dönün.
İki Pod'da ortak ders kaydı tutulduğu sonucunu çıkarmayın. Port yönlendirmeyi her Pod değişimi
sonrasında yeniden başlatmak gerekebilir.

Kanıtlar: başarısız/başarılı CI, commit, digest, plan özeti, Pod sayısı ve hizmet sürümü.
Belirteç, Secret içeriği, kubeconfig ve durum dosyaları teslim kanıtı değildir.
