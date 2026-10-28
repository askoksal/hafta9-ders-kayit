# Sorun Giderme ve Kısmi İşlemler

- **Yanlış bağlam:** `kubectl config get-contexts` ile listeleyin. Yerel kümenizin hazır
  olduğunu doğruladıktan sonra `kubectl config use-context docker-desktop` kullanın.
  Betikler bulut hedefine geçmek için değiştirilmez; bulut yolu Ek 3'te ayrı hazırlanacak.
- **İmaj alınamıyor:** GHCR paketinin public görünürlüğünü, digest'i ve ağ erişimini kontrol edin.
  `kubectl --context docker-desktop -n hafta9 describe pod POD_ADI` ile olayı inceleyin.
  `imagePullPolicy` değiştirmek erişim sorununu çözmez.
- **Secret yok:** Initialize-Local hazırlığı tamamlanmalıdır. Secret başka bir kümede veya
  ad alanındaysa kullanılamaz. Secret değerini Terraform girdisine yazmayın.
- **Yerel belirteç dosyası kayıp:** Mevcut Secret'ın üzerine otomatik yazılmaz. Bu eğitim
  uygulamasında kayıt kaybını kabul ederek yalnız `ders-kayit-access` Secret'ını silin,
  Initialize-Local plan ve uygulamasını yeniden yürütün. Mevcut Pod eski ortam değerini tutar;
  Terraform başlık girdisini değiştirip yeniden planlayarak Pod şablonunu güncelleyin.
- **Boş plan:** Ad alanı veya uygulama zaten istenen durumda olabilir; bu normaldir.
- **Uygulama apply kısmen başarısız:** Terraform otomatik geri almaz. Sorunu giderip
  Plan-Local ile yeni plan oluşturun. Başarısız plandan devam etmek yerine yeniden inceleyin.
- **Henüz last-deployment.json yokken kaldırma:** Normal kaldırma betiği belirsiz girdiyi
  tahmin etmez. Proje kökünde şu işlemi uygulayın; uygulama durum kaydı varsa dağıtımda
  kullandığınız gerçek imaj digest'ini girin:

```powershell
terraform -chdir=infra/local plan -destroy -var="image_ref=GERCEK_IMAJ_DIGEST_ADRESI" -out=cleanup.tfplan
terraform -chdir=infra/local show cleanup.tfplan
terraform -chdir=infra/local apply cleanup.tfplan
terraform -chdir=infra/bootstrap plan -destroy -out=cleanup.tfplan
terraform -chdir=infra/bootstrap show cleanup.tfplan
terraform -chdir=infra/bootstrap apply cleanup.tfplan
```

Her apply öncesi hedefi ve silinecek kaynakları inceleyin. Uygulama hiç planlanmamışsa ve
state yoksa ilk üç komut gerekmez. Bootstrap silinmeden uygulama kaynaklarını kaldırın.
Namespace silinmesi içindeki Secret dahil nesneleri kaldırır. Durum kaydını elle silmek veya
`kubectl delete namespace` ile Terraform'un dışından temizlik yapmak standart yol değildir.
Yerel `.local/api-token.txt` ve planları daha sonra yalnız bu proje klasöründen kaldırın.

Tüm uygulama testleri başarılı olsa da eksik yetki, ağ veya düğüm kapasitesi dağıtımı engelleyebilir.
Namespace `hafta9` başka bir çalışma için kullanılıyorsa bu projeyi o ortamda başlatmayın.
