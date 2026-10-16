# Durum

> Bu dosya projenin nerede olduğunun tek kaynağıdır. Yeni bir sohbete veya yeni bir kişiye
> devrederken ilk okunacak dosya budur. Her faz sonunda güncellenir.
>
> **Yalnızca bugünü anlatır, yerinde yeniden yazılır.** Tarihli başlık açılmaz; olup biten git'te
> ve `archive/state-log.md`'de durur. Sınır: ~120 satır, ~10 KB, en fazla ~10 açık konu. Aşınca
> eski kısım arşive taşınır — kırpmak yetmez, kırpılan dosya geri büyür. Varsayımlar ve faz
> geçmişi bu sınırın dışındadır.

**Son güncelleme:** <TARİH>
**Aktif faz:** <0 Tanıma | 1 Keşif | 2 Araştırma | 3 Netleştirme | 4 Tesisat | 5 Uygulama | Bakım>
<Tek satır. Faz numarasının ardına durumu parantez içinde ekle — "5 Uygulama (onay bekliyor)",
"2 Araştırma (yarıda kaldı)", "5 Uygulama (MVP tamamlandı)". MVP'den sonraki bir turda turu da
yaz: "1 Keşif — tur 2 (devam ediyor)", "5 Uygulama — tur 2 (tur tamamlandı)". Faz numarası nerede
olduğumuzu, parantez o fazın bitip bitmediğini söyler; ikisi olmadan yarım kalmış bir faz
tamamlanmış görünür. Konum yalnızca bu satırda tutulur — ikinci bir konum satırı açılmaz.>
**Sıradaki adım:** <tek cümle, en fazla ~300 karakter — bir sonraki sohbetin ilk yapacağı iş.
Faz 5'te bu satır artımı **tarif etmez, işaret eder**: "Artım 3 · `04-roadmap.md`".
İçeriği orada durur; iki yerde tutulursa biri bayatlar.>
**Belge düzeni:** <tam (beş dosya) | kompakt — kompaktta kararlar ve yol haritası nerede duruyor>

## Tek cümlede proje

<Ne yapıyoruz, kimin için.>

## Netleşenler

| Konu | Durum | Nerede |
|---|---|---|
| <konu> | <karar> | `docs/product/02-decisions.md` |

## Açık konular

- [ ] <cevaplanmamış soru — kimden cevap bekliyor. Kapanan madde silinir: karar olduysa
  `02-decisions.md`'ye, iş olduysa `04-roadmap.md`'ye geçer.>

## Varsayımlar

> Silinmezler. Uygulama sırasında bu varsayıma dayanan bir yere dokunulduğunda kullanıcıya sorulur.

| ID | Varsayım | Neden varsayıldı | Yanlışsa ne kırılır |
|---|---|---|---|
| V1 | <varsayım> | <gerekçe> | <etki> |

## Faz geçmişi

> Fazların süreç kayıtları "Not" sütununa yazılır: başlatılan ve biten araştırma kolları,
> mevcut bir `CLAUDE.md` için birleştir / değiştir / yanına yaz seçimi, öneri yerine istek
> üzerine kurulan araçlar. Yeni başlık açılmaz.

| Faz | Durum | Not |
|---|---|---|
| 0 Tanıma | <tamam / atlandı / bekliyor> | <atlandıysa neden> |
| 1 Keşif | | |
| 2 Araştırma | | |
| 3 Netleştirme | | |
| 4 Tesisat | | |
| 5 Uygulama | | |

<MVP'den sonra açılan her tur, yeniden yürüdüğü fazlar için "(tur 2)" ekli satırlarla devam eder.>
