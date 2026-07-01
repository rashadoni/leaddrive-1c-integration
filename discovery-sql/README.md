# Discovery SQL paketi

**Harada işlədilir:** YALNIZ bərpa olunmuş kopyada (`pharma_copy`), prod-da YOX.
Skriptlər read-only-dir (yalnız `#temp` cədvəllər yaradır), amma qayda qaydadır.

**Necə işlətmək:**
- SSMS: hər faylı aç → `pharma_copy` kontekstində icra et → nəticəni
  `File → Save Results As...` ilə saxla; **VƏ YA**
- bizim CLI: `cd etl && npx tsx src/cli.ts discover` — hamısını ardıcıl işlədir,
  nəticələri `etl/out/discovery/*.json` yazır.

| Fayl | Nə verir | Niyə lazımdır |
|---|---|---|
| `00-server-info.sql` | Versiya, edition, baza ölçüsü, compatibility, collation | Mühit pasportu |
| `01-table-census.sql` | Ən böyük 100 cədvəl + 1C prefiks üzrə say/ölçü | Yük haradadır |
| `02-1c-system-checks.sql` | `_YearOffset`, `Params/DBNames` mövcudluğu, `_Version` sütun əhatəsi | ETL-in 3 kritik sualı |
| `03-document-inventory.sql` | Sənəd/registr cədvəllərinin pattern-əsaslı inventarı | Metadata xəritəsinə qədər ilkin xəritə |
| `04-monthly-volume-profile.sql` | Hər sənəd cədvəli üzrə ay-ay sənəd sayı (dinamik SQL) | 30k/gün hansı cədvəldədir — satış sənədini həcm "qışqırır" |
| `05-collation-and-indexes.sql` | Collation kənarlaşmaları + ən böyük indekslər | Extract performansı planlaması |

**Çıxışların hamısı Gate 1 discovery hesabatına daxil edilir.**
