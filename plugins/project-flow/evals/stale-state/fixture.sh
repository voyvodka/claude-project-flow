set -e
git init -q; git config user.email t@example.com; git config user.name t
mkdir -p docs/product
cat > docs/product/00-state.md <<'X'
# Durum
**Son güncelleme:** 2026-09-01
**Aktif faz:** 3 Netleştirme (onay bekliyor)
**Sıradaki adım:** Kararlar yazıldı, Faz 4 için onay bekleniyor.
**Belge düzeni:** kompakt — kararlar `01-brief.md › Kararlar`, yol haritası `03-mvp.md › Yol haritası`
## Tek cümlede proje
Banka CSV'sinden aylık harcama özeti çıkaran bir CLI.
## Faz geçmişi
| Faz | Durum | Not |
|---|---|---|
| 1 Keşif | tamam | |
| 2 Araştırma | atlandı | küçük kişisel araç |
| 3 Netleştirme | tamam | |
| 4 Tesisat | tamam | |
| 5 Uygulama | tamam | MVP tamamlandı |
X
printf '# Proje Özeti\n## 1. Problem\nBanka CSV dosyasını elle topluyorum.\n## 4. Başarı kriteri\nBir ayın CSV dosyası 1 saniyede özetlenir.\n## 5. Kapsam dışı\n- Grafik\n## Kararlar\n### Dil\n**Karar:** Go stdlib\n' > docs/product/01-brief.md
git add -A; git commit -qm 'docs: decisions'
