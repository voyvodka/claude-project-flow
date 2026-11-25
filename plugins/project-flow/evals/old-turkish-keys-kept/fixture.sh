set -e
git init -q; git config user.email t@example.com; git config user.name t
mkdir -p docs/product
cat > docs/product/00-state.md <<'X'
# Durum
**Son güncelleme:** 2026-09-01
**Aktif faz:** 1 Keşif (devam ediyor)
**Sıradaki adım:** Ek bilgiler tablosundaki boş satırları doldur.
**Belge düzeni:** kompakt — kararlar `01-brief.md › Kararlar`, yol haritası `03-mvp.md › Yol haritası`
## Tek cümlede proje
Bir ailenin ortak market listesini tuttuğu küçük web uygulaması.
## Açık konular
- [ ] Para modeli — kullanıcıdan cevap bekliyor
## Faz geçmişi
| Faz | Durum | Not |
|---|---|---|
| 0 Tanıma | tamam | boş klasör |
| 1 Keşif | bekliyor | |
X
cat > docs/product/01-brief.md <<'X'
# Proje Özeti
## 1. Problem
Ailede alışveriş listesi mesajlarda kayboluyor.
## 2. Hedef kullanıcı
Tek bir aile, 4 kişi.
## 3. Ana akış
1. Biri ürün ekler.
2. Markette olan işaretler.
## 4. Başarı kriteri
Bir hafta boyunca liste yalnız uygulamada tutulur.
## 5. Kapsam dışı
- Fiyat karşılaştırma
## 6. Kısıtlar
| Kısıt | Değer |
|---|---|
| Süre | iki hafta sonu |
| Bütçe | 0 |
| Ekip | 1 kişi |
| Zorunlu teknolojiler | yok / uygulanmaz |
| Mevcut yetkinlik | web, TypeScript |
| Teknoloji yığını | açık — araştırılacak |
## Ek bilgiler
| Konu | Durum |
|---|---|
| Veri ve dış entegrasyonlar | yok / uygulanmaz |
| Ölçek beklentisi | 4 kullanıcı |
| Dağıtım hedefi | ⚠️ VARSAYIM: telefon tarayıcısı |
| Kimlik ve yetki (roller) | aile üyeleri eşit |
| Para modeli | |
| Bakım | kendim |
X
git add -A; git commit -qm 'docs: discovery in progress'
