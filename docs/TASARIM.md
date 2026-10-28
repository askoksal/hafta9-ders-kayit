# Uygulama Sözleşmesi ve Dosya Tasarımı

Sürüm 1.0 — 22 Ekim 2026. Bu paket yerel aşamanın kaynak kod temelidir.
Üç ayrıntılı ek ve bulut sağlayıcı kök yapılandırmaları sonraki aşamada hazırlanacaktır.

## Amaç ve Kapsam

Öğrenci bir değişikliği Git dalında kaydeder; CI hatayı yakalar; düzeltme ve birleştirme sonrası
GHCR'de imaj yayımlanır. Yerel PowerShell dağıtım betikleri Terraform planını inceletir ve
Docker Desktop Kubernetes ortamına uygular. GitHub çalıştırıcısı yerel kümeye bağlanmaz.
Yerel akış sürekli bütünleştirme ve kontrollü teslim örneğidir; kendiliğinden üretime dağıtım değildir.

Uygulama Python 3.14 ve Flask 3.1.3 kullanır. Gunicorn tek işçi ve dört iş parçacığıyla çalışır.
Öğrenci Windows'a Python kurmaz; Docker test aşaması gerekli bağımlılıkları içerir.
Temel imaj içerik digest'iyle, Python bağımlılıkları tam sürümleriyle sabittir.
GitHub Actions eklentileri tam commit kimliklerine sabitlenmiştir.

## Hizmet Sözleşmesi

| Yol | İşlev | Erişim |
| --- | --- | --- |
| GET / | Küçük Türkçe kullanıcı arayüzü | Açık, yalnız örnek veri |
| GET /api/courses | Ders, kontenjan ve bu süreçteki kayıt sayısı | Açık |
| POST /api/enrollments | DEMO001 biçimindeki öğrenci için kayıt | Bearer belirteci |
| GET /api/enrollments | Örnek kayıt listesi | Bearer belirteci |
| GET /version | Uygulama sürümü ve kaynak commit'i | Açık |
| GET /healthz ve /readyz | Bu basit hizmetin çalışma kontrolü | Açık |

POST gövdesi yalnız `student_id` ve `course_id` içerir. Başarı 201; biçim hatası 400;
yetkisiz erişim 401; bilinmeyen ders 404; yinelenen veya dolu ders 409;
yanlış içerik türü 415; fazla büyük gövde 413 döndürür.

Veri bellektedir; yeniden başlatma, sürüm güncellemesi veya süreç değişimi kayıplıdır.
Bu nedenle temel kayıt senaryosu bir Pod'dur ve güncelleme stratejisi Recreate'dir.
Kopya sayısı 2 veya 3 yalnız Terraform ölçek gözleminde kullanılır. Bu durumda Pod'lar
ortak veri tutmaz; port yönlendirme bir Pod'a bağlanır, yük dengeleme deneyi yapılmış sayılmaz.
Gerçek öğrenci verisi, kalıcı veri tabanı ve gerçek kullanıcı yetkilendirmesi kapsam dışıdır.

## Kaynak Sahipliği

`infra/bootstrap` Terraform ad alanını (`hafta9`) oluşturur ve Pod güvenlik etiketlerini yönetir.
`Initialize-Local.ps1`, bu ad alandaki `ders-kayit-access` Secret'ını bir kez üretir.
Gerçek belirteç Terraform'a verilmez, plan ve durum kaydında yer almaz.
Secret'ın değeri yerel `.local/api-token.txt` dosyasında tutulur; yalnız kullanıcı erişimi olan
bir bilgisayarda kullanılmalı, paylaşılmamalıdır. Dosya ve durum kayıtları Git dışında kalır.

`infra/local` ortak `infra/modules/course_service` modülünü çağırır. Bu modül ConfigMap,
Deployment ve ClusterIP Service oluşturur. İmaj digest'i, kopya sayısı ve ekran başlığı girdidir.
Secret ve ad alanı önceden hazır olmalıdır. Terraform bu Secret'ın değerini okumaz.
Uygulamaya Kubernetes erişim belirteci bağlanmaz. Kök dosya sistemi salt okunurdur;
ayrıcalık yükseltme kapalıdır; tüm Linux yetenekleri düşürülür; geçici yazma alanı sınırlıdır.

## Dizinler ve İş Akışı

- `app/`, `wsgi.py`: uygulama ve arayüz.
- `tests/`: işlev, erişim ve eş zamanlı kontenjan testleri.
- `Dockerfile`: test ve çalışma aşamaları.
- `.github/workflows/ci.yml`: test, Terraform denetimi, koşullu GHCR yayımlama.
- `infra/bootstrap/`: ad alanı ve ayrı yerel durum kaydı.
- `infra/local/`: uygulama ve ayrı yerel durum kaydı.
- `infra/modules/course_service/`: ileride bulutta da çağrılacak uygulama modülü.
- `scripts/`: Windows PowerShell ile test, plan, uygulama, doğrulama ve temizlik.
- `.local/`: çalışma sırasında oluşur; belirteç, plan ve dağıtım kayıtları içerir; dağıtılmaz.

Depo adı için `hafta9-ders-kayit`, ana dal için `main` kullanılır.
Kullanıcı veya kuruluş başına tek GHCR imaj yolu kullanılır; bu örnekte bireysel GitHub hesabı esas alınır.
GitHub Packages ilk yayımlamada özel olabilir. Yerel anonim imaj çekme için paketin görünürlüğü
öğrenci tarafından public yapılır. Yalnız örnek uygulama yayımlanır; sırlar imajda bulunmaz.
Kuruluşun public paket politikasına izin vermediği durumda bu yol uygulanmadan erişim tasarımı uyarlanır.

## Buluta Geçiş İçin Arayüz

Sonraki aşamada AWS, Azure ve Google Cloud altyapı kökleri hazırlanacak. Mevcut ortak modül
herkese açık GHCR veya sağlayıcının kayıt deposundaki digest girdisini alabilir.
Özel kayıt deposu erişimi ve bulut kimlikleri bu aşamada ayrıca yapılandırılacaktır.
Küme/ağ altyapısı ve uygulama farklı durum kayıtları kullanacak. Bu pakette bulutun
uçtan uca çalıştığına dair bir iddia ve çalışan bulut dağıtım iş akışı yoktur.

## Ders Metninde Yapılacak Uyum Düzeltmesi

8.1 Tablo 10'un uygulama satırı: CI/CD dağıtım görevi Terraform'u çağırır;
Deployment ve Service'in yapılandırma sahibi Terraform'dur. `kubectl apply` ikinci bir
yönetim yolu olarak öğretilmez. 9.1–9.3 ve üç ek aynı dosya adlarını kullanacaktır.
