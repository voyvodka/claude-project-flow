set -e
git init -q; git config user.email t@example.com; git config user.name t
mkdir -p docs/product
cat > docs/product/00-state.md <<'X'
# Durum
**Son güncelleme:** 2026-10-20
**Aktif faz:** 1 Keşif (devam ediyor)
**Sıradaki adım:** Kalan engelleyici maddeler: kapsam dışı ve kısıtlar.
**Belge düzeni:** kompakt — kararlar `01-brief.md › Kararlar`, yol haritası `03-mvp.md › Yol haritası`
## Tek cümlede proje
Banka CSV'sinden aylık harcama özeti çıkaran bir CLI.
## Faz geçmişi
| Faz | Durum | Not |
|---|---|---|
| 0 Tanıma | tamam | boş klasör |
| 1 Keşif | devam ediyor | 2. tur |
X
printf '# Proje Özeti\n## 1. Problem\nBanka CSV dosyasını elle topluyorum.\n## 3. Ana akış\n1. CSV ver\n2. Özet al\n## 4. Başarı kriteri\nBir ayın CSV dosyası 1 saniyede özetlenir.\n' > docs/product/01-brief.md
git add -A; git commit -qm 'docs: discovery round 2'
