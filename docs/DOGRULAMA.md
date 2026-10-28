# Doğrulama Kaydı

Tarih: 22 Ekim 2026. Paket sürümü: yerel temel 1.0.

| Kontrol | Gerçek Sonuç |
| --- | --- |
| Python 3.12.14 üzerinde uygulama testleri | 21 test geçti. |
| Python 3.14.8 üzerinde kilitli bağımlılıklarla testler | 21 test geçti. |
| Hatalı kontenjan değişikliği deneyi | Kontenjan 2 yerine 3 yapıldığında 3 test başarısız oldu; asıl kaynak değiştirilmedi. |
| PowerShell 7.6.7 sözdizimi kontrolü | Tüm dağıtım ve kontrol betikleri ayrıştırıldı. |
| PowerShell koruma testleri | 4 kontrol geçti: yanlış hedef, plan kaydı, plan değişikliği, komut hatasında durma. |
| Terraform 1.17.0 fmt -check | Bütün Terraform dosyalarında başarılı. |
| Kubernetes sağlayıcısı 3.4.0 | Resmî paket indirildi; üç kök/modül için kilit dosyaları hazırlandı. |
| Terraform validate ve mock test çalıştırma | Tamamlanamadı: çalışma ortamı sağlayıcının yerel Unix soketi açmasını engelliyor. `socket: operation not permitted`. Başarılı sayılmadı. |
| GitHub iş akışı statik kontrolü | actionlint 1.7.12 başarılı. |
| Docker imaj oluşturma ve imaj içi test | Bu ortamda Docker yok; çalıştırılmadı. |
| Gerçek Windows PowerShell 5.1 | Burada çalıştırılmadı; GitHub iş akışında zorunlu kontrol olarak tanımlı. |
| Docker Desktop Kubernetes üzerinde dağıtım | Bu ortamda küme yok; çalıştırılmadı. |
| GitHub Actions ve GHCR yayımlama | Gerçek kullanıcı deposuna push/yayımlama yapılmadı; çalıştırılmadı. |
| Bulut dağıtımı | Bu paketin aşaması değil; bulut yapılandırmaları ve Ek 3 hazırlanacak. |

Testler Flask test istemcisiyle gerçek uygulama kodunu çağırır; canlı HTTP sunucusu veya
tarayıcı doğrulaması olarak sunulmaz. PowerShell koruma testleri sahte komutlarla çalışır;
gerçek Terraform apply veya Kubernetes testi değildir. Mock Terraform testleri de gerçek
altyapının uygunluğunu tek başına kanıtlamaz.

## Paket Kabulünden Önce Kalan Kontroller

1. GitHub'da ilk çalıştırmada Docker, Terraform validate/test ve Windows kontrollerinin geçmesi.
2. Test edilmiş çalışma imajının GHCR'ye gönderilmesi ve anonim çekme erişiminin doğrulanması.
3. Windows Docker Desktop ortamında hazırlama, plan, uygulama, arayüz ve sürüm doğrulaması.
4. ConfigMap başlığı değiştiğinde Pod'un yenilenmesi; kopya sayısı gözlemi ve tekrar tek kopyaya dönüş.
5. Uygulama ve ad alanı temizlenirken diğer haftaların kaynaklarının korunması.

Bu paket entegrasyon temelidir; henüz uçtan uca doğrulanmış son öğrenci dağıtımı olarak
işaretlenmez. Ekler ve son paket bu kontrollerin sonuçlarına göre güncellenecektir.
