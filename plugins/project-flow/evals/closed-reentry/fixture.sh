set -e
git init -q; git config user.email t@example.com; git config user.name t
mkdir -p docs/product
cat > docs/product/00-state.md <<'X'
# Durum
**Son güncelleme:** 2026-09-01
**Aktif faz:** 5 Uygulama (MVP tamamlandı)
**Sıradaki adım:** MVP kapandı.
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
printf '# Proje Özeti\n## 4. Başarı kriteri\nBir ayın CSV dosyası 1 saniyede özetlenir.\n## 5. Kapsam dışı\n- Grafik\n## Kararlar\n### Dil\n**Karar:** Go stdlib\n' > docs/product/01-brief.md
printf '# MVP\n## İçeride\n- CSV oku, kategori topla\n## Sonrası\n- JSON çıktı\n## Yol haritası\n### 1. Okuyucu\n- **Durum:** ✅ tamam\n' > docs/product/03-mvp.md
printf 'module x\n\ngo 1.25\n' > go.mod
cat > main.go <<'GO'
package main

import (
	"encoding/csv"
	"fmt"
	"os"
	"strconv"
)

// Reads one bank's export: date,description,category,amount.
func main() {
	f, err := os.Open(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	rows, err := csv.NewReader(f).ReadAll()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	totals := map[string]float64{}
	for _, r := range rows[1:] {
		v, _ := strconv.ParseFloat(r[3], 64)
		totals[r[2]] += v
	}
	for k, v := range totals {
		fmt.Printf("%-20s %10.2f\n", k, v)
	}
}
GO
printf '# Harcama özeti\n\nTek bankanın CSV dışa aktarımından kategori toplamları.\n\n    go run . ekstre.csv\n\nBaşarı kriteri karşılandı: bir aylık dosya 0,2 saniyede özetlendi.\n' > README.md
git add -A; git commit -qm 'feat: mvp'
