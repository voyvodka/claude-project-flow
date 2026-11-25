# Turkish keys

The fixed wording of this tool's documents in Turkish. Two uses:

- **Writing a Turkish project** — use these words, so every Turkish project reads the same.
- **Reading a project started before 4.0.0** — its documents were written from Turkish templates.
  Each Turkish key below means exactly what its English key means; match either form. Keep writing
  the project's own wording, and rename its keys only when the user asks.

## State file (`00-state.md`)

| English | Turkish |
|---|---|
| `# State` | `# Durum` |
| `Last updated` | `Son güncelleme` |
| `Active phase` | `Aktif faz` |
| `Next step` | `Sıradaki adım` |
| `Document layout` · `full` · `compact` | `Belge düzeni` · `tam` · `kompakt` |
| `The project in one sentence` · `Settled` · `Open` | `Tek cümlede proje` · `Netleşenler` · `Açık konular` |
| `Assumptions` · `Phase history` | `Varsayımlar` · `Faz geçmişi` |
| Assumption ids `A1`, `A2` | `V1`, `V2` |
| `Settled` table: `Topic` · `Status` · `Where` | `Konu` · `Durum` · `Nerede` |
| `Assumptions` table: `ID` · `Assumption` · `Why it was assumed` · `What breaks if it is wrong` | `ID` · `Varsayım` · `Neden varsayıldı` · `Yanlışsa ne kırılır` |
| `Phase history` table: `Phase` · `Status` · `Note` | `Faz` · `Durum` · `Not` |
| Phase history statuses `done` · `skipped` · `waiting` | `tamam` · `atlandı` · `bekliyor` |
| `Document layout` value: `full (five files)` · compact mapping `01-brief.md › Decisions`, `03-mvp.md › Roadmap` | `tam (beş dosya)` · `01-brief.md › Kararlar`, `03-mvp.md › Yol haritası` |

Phases and statuses, as they appear on the `Active phase` line:

| English | Turkish |
|---|---|
| `0 Detect` · `1 Discover` · `2 Research` | `0 Tanıma` · `1 Keşif` · `2 Araştırma` |
| `3 Decide` · `4 Scaffold` · `5 Build` | `3 Netleştirme` · `4 Tesisat` · `5 Uygulama` |
| `Maintenance` | `Bakım` |
| `(awaiting approval)` · `(in progress)` · `(interrupted)` | `(onay bekliyor)` · `(devam ediyor)` · `(yarıda kaldı)` |
| `(MVP complete)` · `(round complete)` | `(MVP tamamlandı)` · `(tur tamamlandı)` |
| `round 2` · `Round 2` | `tur 2` · `Tur 2` |
| `Increment 3` | `Artım 3` |

## Brief, MVP and roadmap

| English | Turkish |
|---|---|
| `# Project Brief` | `# Proje Özeti` |
| `Problem` · `Target users` · `Main flow` | `Problem` · `Hedef kullanıcı` · `Ana akış` |
| `Success criterion` · `Out of scope` · `Constraints` | `Başarı kriteri` · `Kapsam dışı` · `Kısıtlar` |
| `Existing skill` · `Stack` · `Mandatory technologies` | `Mevcut yetkinlik` · `Teknoloji yığını` · `Zorunlu teknolojiler` |
| `Additional details` | `Ek bilgiler` |
| `Constraints` table: `Constraint` · `Value` | `Kısıt` · `Değer` |
| `Constraints` rows: `Time` · `Budget` · `Team` | `Süre` · `Bütçe` · `Ekip` |
| `Stack` values: `user-supplied: …` · `confirmed from existing code: …` · `open — to be researched` | `kullanıcı belirtti: …` · `mevcut koddan doğrulandı: …` · `açık — araştırılacak` |
| `Additional details` table: `Topic` · `Status` | `Konu` · `Durum` |
| `Additional details` rows: `Data and external integrations` · `Expected scale` · `Delivery target` | `Veri ve dış entegrasyonlar` · `Ölçek beklentisi` · `Dağıtım hedefi` |
| `Identity and permissions (roles)` · `Revenue model` · `Maintenance` | `Kimlik ve yetki (roller)` · `Para modeli` · `Bakım` |
| `none / not applicable` | `yok / uygulanmaz` |
| `⚠️ ASSUMPTION` | `⚠️ VARSAYIM` |
| `# MVP Scope` · `In` · `Out` · `Later` | `# MVP Kapsamı` · `İçeride` · `Dışarıda` · `Sonrası` |
| MVP tables: `What` · `Contribution to the success criterion` · `Why it is out` | `Ne` · `Başarı kriterine katkısı` · `Neden dışarıda` |
| `Round 2 — <goal>` | `Tur 2 — <amaç>` |
| `# Roadmap` · `Increments` | `# Yol Haritası` · `Parçalar` |
| Increment fields `Delivers` · `Depends on` · `How it is verified` · `Status` · `Note` | `Ne teslim eder` · `Bağımlılık` · `Nasıl doğrulanır` · `Durum` · `Not` |
| `Status markers:` · `⬜ waiting` · `🔄 in progress` · `✅ done` · `⏸️ paused` | `Durum işaretleri:` · `⬜ bekliyor` · `🔄 devam ediyor` · `✅ tamam` · `⏸️ durduruldu` |
| Compact sections `## Decisions` · `## Roadmap` | `## Kararlar` · `## Yol haritası` |

## Decision entries (`02-decisions.md`)

| English | Turkish |
|---|---|
| `# Decisions` | `# Kararlar` |
| `Decision` | `Karar` |
| `Why` | `Neden` |
| `Rejected` | `Elenenler` |
| `Accepted cost` | `Kabul edilen bedel` |
| `Rests on` | `Bağlı olduğu varsayım` |
| `Source` | `Kaynak` |
| `none` | `yok` |
| Index columns once the file is split: `date · decision · file` | `tarih · karar · dosya` |
| A reversal on the `Why` line: "X was chosen first; changed because of Y" | "önce X seçilmişti, Y nedeniyle değişti" |

## Internal README (`README-internal.md`)

| English | Turkish |
|---|---|
| `Status` · `Running it` · `Documents` · `Worth knowing` | `Durum` · `Çalıştırma` · `Dökümanlar` · `Bilinmesi gerekenler` |
| `Question` · `File` | `Soru` · `Dosya` |
| `Where are we, what is next` · `What are we building, and why` · `Why is it built this way` | `Nerede kaldık, sırada ne var` · `Ne yapıyoruz, neden` · `Neden böyle kurulmuş` |
| `What is in the MVP, and what is not` · `Build order and progress` · `Research findings` | `MVP'de ne var, ne yok` · `İnşa sırası ve ilerleme` · `Araştırma bulguları` |
| `In development` · `MVP complete` · `In production` | `Geliştirme aşamasında` · `MVP tamam` · `Üretimde` |
