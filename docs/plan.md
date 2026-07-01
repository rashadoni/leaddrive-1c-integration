# Pharma Distribütor — Analitik Hesabat Platforması: Arxitektura + PoC Planı

## Kontekst

Müştəri: əczaçılıq distribütoru. 500–600 tədarükçü, 15 000 SKU, 1 500 aptek-müştəri, gündə 30 000 satış sənədi. ERP: **1C platforma 8.2** (konfiqurasiya adı hələ məlum deyil) + **MS SQL Server 2019 Enterprise**, baza 300 GB, eyni bazada anbar idarəetməsi. Problem: ağır hesabatlar anbar əməliyyatlarını dondurur. Tələblər: D-1 təzəlik kifayətdir; anbar 08:00–20:00 işləyir (gecə 12 saat boş pəncərə); orta maya, ƏDV daxil, qaytarmalar stokdan çıxılır; partiya/seriya + yararlılıq müddəti ölçüsü; şöbələrə səhər dashboard push; maksimum dövr-müqayisə imkanı; xərclər eyni bazadadır; on-prem üstünlük; daxili 1C proqramçıları var; **diskdə bazanın .bak kopyası var**. Sərt uğur meyarı: **hesabatlıq iş prosesinə sıfır təsir**.

İstifadəçinin qərarı: əvvəlcə **test/PoC**, arxitektura-mərkəzli, Markdown formatda.

## Qərar və stress-test xülasəsi

**Qərar:** Gecə ETL → ayrıca serverdə **PostgreSQL DWH (star schema)** → nazik **Next.js platforma** (LeadDrive komponentləri lift edilir) + **Metabase** yanında QA/ad-hoc kimi + **Claude NL→SQL** sonuncu, şərti faza kimi. PoC tam həcmdə, **.bak kopyası üzərində**, prod-a toxunmadan.

**Konsensus (bütün yoxlamalar razı):** DWH + gecə ETL nüvəsi düzgündür; PoC kopya + SQL Server **Developer Edition** (test üçün pulsuz) düzgün ilk addımdır; MSSQL-only ikinci instans (lisenziya) və AlwaysOn readable replica (D-1 üçün artıq + 1C read-only replika ilə işləmir + oxunan replika tam lisenziya tələb edir) rədd edilir.

**Açıq fikir ayrılığı (Codex — müstəqil rəyçi):** "Custom platforma PoC-də olmasın, əvvəl hazır BI (Metabase), custom sonra." **Bizim mövqe:** nazik custom qat ucuzdur, çünki komponentlər hazır mövcuddur (yoxlanılıb), Telegram/AZ-RU push isə müştəri tələbidir; amma Codex-in iki düzəlişi qəbul edilir: (1) **rekonsiliasiya PoC-nin mərkəzi məhsuludur**, (2) **NL→SQL qəbul-kriteriyası DEYİL** — sonuncu, egress-dən asılı fazadır.

**Ən riskli vəd:** gündəlik marja "manatı-manata". 8.2-də maya ay bağlananda yekunlaşır → **bağlanmış ay dəqiq, D-1 marja "ilkin" statuslu** — SOW-da bu dillə yazılmalıdır.

**Confidence: Medium-High.** Ən böyük naməlum: konfiqurasiya növü (УТ 10.3 партионный учёт / УПП-РАУЗ / custom) — maya yanaşmasını bütövlükdə müəyyən edir (Gate 1-də həll olunur). İkinci: `ПолучитьСтруктуруХраненияБазыДанных()` 8.2-də davranışı — mənbələr ziddiyyətlidir, hər iki hala fallback hazırlanır.

## Hədəf arxitektura (prod, PoC-dən sonra)

```
1C 8.2 / MSSQL 2019 Ent (prod)
   │  gecə ~21:00: DATABASE SNAPSHOT yaradılır → ondan oxunur → silinir
   │  (konsistent, lisenziyasız, NOLOCK anomaliyasız; anbar bağlı olduğundan yük ~0)
   │  + Resource Governor cap ETL login-ə + 06:00 hard watchdog
   ▼
ETL (Node/TS: mssql → pg COPY)  →  PostgreSQL 16 DWH (star schema, ay partisiyaları, ~80–100 GB)
                                        │
              ┌─────────────────────────┼──────────────────────────┐
              ▼                         ▼                          ▼
   Semantik views qatı          Metabase (read-only,        Next.js platforma:
   (mv_sales_daily,             QA + ad-hoc + benchmark)    şöbə dashboardları,
    mv_margin_daily,                                        08:00 email/Telegram push,
    mv_stock_expiry…)                                       XLSX export, müqayisə motoru,
              │                                             audit log
              ▼
   Claude NL→SQL (yalnız semantik views üzərində; variant B məxfilik)
```

- Prod-da **ikinci MSSQL lisenziyası YOXDUR** — ETL gecə birbaşa prod-dan (snapshot-dan) oxuyur. Developer Edition yalnız PoC test maşınındadır.
- Həcm riyaziyyatı (yoxlanılıb): gündə ≤1M fakt sətri; gecə yük (D-1 + 7 günlük sliding pəncərə) ≈ 4–7M sətir ≈ 3–25 dəq; pəncərə 12 saat → 50–150× ehtiyat. 24 aylıq backfill ≈ 365M sətir — bcp+COPY ilə bir günlük iş, **kopyadan, prod-a toxunmadan**.

## Məxfilik variantları (müştəri seçəcək; tövsiyə: B ilə başla)

| Variant | Kənara nə gedir | Üstün | Mənfi |
|---|---|---|---|
| **A.** Claude API: sual + sxem + aqreqat nəticə | Aqreqat rəqəmlər API-yə gedir | Ən rahat UX: izahlı, danışan cavablar | Kommersiya aqreqatları kənardan keçir; internet asılılığı |
| **B. (tövsiyə)** Claude API: yalnız sual + sxem (cədvəl/sütun adları, metrik tərifləri) | Heç bir rəqəm getmir; SQL qayıdır, lokalda icra olunur | Frontier keyfiyyət + data tam lokalda | Avtomatik AI şərhi yoxdur (istəyə görə düymə ilə → A) |
| **C.** Tam lokal LLM (GPU server) | Heç nə | Tam izolyasiya (air-gap) | GPU server xərci; SQL keyfiyyəti nəzərəçarpan zəif; baxım yükü |
| **D.** B + maskalı narrasiya | Pseudonimləşdirilmiş aqreqatlar | Orta yol (LeadDrive `pii-masker.ts` uyğunlaşdırılır) | Mürəkkəblik artır |

Qeyd: Anthropic API kommersiya şərtlərinə görə müştəri datasını default olaraq training-ə vermir. Egress (api.anthropic.com:443) bağlıdırsa → NL fazası düşür, qalan platforma tam işləyir (ona görə NL qəbul-kriteriyası deyil).

## Alternativlər (baxıldı və mövqe)

| Variant | Mövqe | Səbəb |
|---|---|---|
| V1: Postgres DWH + nazik custom + Metabase | **Tövsiyə** | $0 lisenziya; komanda stack-i PG-dir; bütün tələbləri örtür |
| V2: + ClickHouse | Sonraya | Bu həcmdə (~365M sətir) PG kifayətdir; ehtiyac yaranarsa miqrasiya yolu açıqdır |
| V3: AlwaysOn readable replica | Rədd | D-1 üçün artıq; oxunan replika tam lisenziya istəyir; 1C read-only bazada işləmir |
| V4: Gecə restore olunan 1C kopyası, istifadəçilər native hesabat çəkir | Yalnız müvəqqəti "relief valve" | Lisenziya tələsi (istifadəçi oxuyursa = prod istifadə, Developer olmaz); tələblərin heç birini (müqayisə, push, expiry-pivot) vermir; yavaş 8.2 hesabatları yavaş qalır |
| V5: Yalnız hazır BI (Metabase/Power BI) | Qismən qəbul | Metabase docker-compose-da yanımızda gedir (QA + ad-hoc); amma AZ/RU NL, Telegram push, vahid marja tərifi choke-point-i vermir; PBIRS lisenziyası SA-dan asılı |

## PoC planı (~4 həftə: 4–6 gün off-site hazırlıq + ~21 gün engagement)

### Phase 0 — off-site hazırlıq, müştəriyə toxunmadan (4–6 gün)
| Artefakt | Nəticə |
|---|---|
| 0.1 IT sorğu vərəqi | Konfiqurasiya adı/versiyası; партионный/РАУЗ rejimi + "восстановление последовательности" cədvəli; seriya/markalama istifadəsi; xərc sənəd növləri; hüquqi şəxslər/anbarlar/valyutalar; retro-bonus praktikası; AD/SMTP/Telegram; **egress siyasəti**; test maşın OS/spec; backup cədvəli |
| 0.2 Metadata extractor paketi | **8.2-uyğun обработка (.epf)**: adi formalar, **XML/TSV çıxış (8.2-də JSON YOXDUR)**; `ПолучитьСтруктуруХраненияБазыДанных` cəhd edir; fallback: `Params` cədvəlindəki `DBNames` blob-unu açan Node skripti (inflateRaw); fallback B: `_Document*/_Period/_Recorder*` sütun-pattern heuristikası |
| 0.3 Discovery SQL paketi | Cədvəl senzusu (sətir/ölçü), `_YearOffset`, `_Version` (rowversion) mövcudluğu, sənəd/registr inventarı, aylıq həcm profili, collation |
| 0.4 DWH DDL + semantik YAML + metrik memo (RU/AZ) | Marja tərifi (orta maya, ƏDV daxil, qaytarmalar çıxılır, доп. расходы daxil) — **maliyyəçi imzalayır** |
| 0.5 ETL skelet repo (yeni, standalone) | extract→stage→transform→**reconcile** CLI; run-log cədvəlləri; alert stub |
| 0.6 Deploy bundle | docker-compose (PG16 + app + Metabase) + offline tarball-lar + **Windows-native fallback runbook** (NSSM) — müştəri çox güman Windows-dur |

### Phase 1 — Discovery (gün 1–4) → **GATE 1**
.bak bərpası (əvvəl `RESTORE FILELISTONLY` → disk hesabı; bərpa 1–2.5 saat; sonra `SIMPLE` recovery, log shrink). 1C proqramçıları обработка-nı **prod-da** işə salır (yalnız metadata, saniyələr çəkir, data oxumur — test maşında 1C server lisenziyası lazım olmur), nəticə kopya ilə üzləşdirilir (backup-config drift yoxlanışı). Discovery SQL kopyada. **Gate 1 qərarları:** maya branch-ı (A: партионный registr / B: DWH-də weighted-average + ay-sonu true-up), NL go/no-go (egress), konfiqurasiya sürprizləri.

### Phase 2 — ETL backfill + rekonsiliasiya (gün 5–9) → **GATE 2**
Dim-lər (məhsul/müştəri/tədarükçü/anbar/təşkilat/seriya/tarix) + faktlar (satış sətirləri, qaytarmalar, alışlar) 13–24 ay, bcp+COPY. **Rekonsiliasiya dəsti:** gün-bə-gün sənəd sayı / məbləğ / ƏDV / stok 1C kontrol hesabatları ilə müqayisə, uyğunsuz günlərin avtomatik re-extract-ı, admin "trust dashboard". **Gate 2: maliyyəçi dövriyyə/say/ƏDV-ni manatı-manata imzalayır** (marja bilərəkdən burada yoxdur).

### Phase 3 — Marja motoru (gün 10–12; branch B isə +2–3 gün)
Branch A: `ПартииТоваровНаСкладах`-dan; Branch B: DWH weighted-average + 1C ay-bağlama ilə true-up. Доп. расходы (landed cost) daxil. **Nəticə: bağlanmış ay dəqiq; D-1 "ilkin" statusla, sənədləşmiş fərq payı ilə.**

### Phase 4 — Delivery qatı (gün 13–16)
Semantik views; 5 hesabat (müştəri/məhsul/tədarükçü üzrə satış; xərclər; marja; expiry/partiya stok yaşlanması; dövr müqayisəsi); 1–2 şöbə dashboard-u; 08:00 email push; opsional Telegram; Metabase mart-lara read-only qoşulur. **Nəticə: 2 pilot şöbə real səhər push-u alır.**

### Phase 5 — NL→SQL (gün 17–19, yalnız Gate 1-də egress OK olarsa)
Yalnız semantik views üzərində SQL generasiyası; `libpg-query` AST validasiyası (tək SELECT, denylist, məcburi LIMIT); `report_ro` rolu (`default_transaction_read_only`, `statement_timeout=15s`, yalnız views-a GRANT); audit cədvəli; 20 qızıl AZ/RU sual + gözlənilən SQL testi. **Qəbul kriteriyası deyil — demo + dəqiqlik hesabatı.**

### Phase 6 — Performans + prod təklifi (gün 20–21)
Top-10 ağır sorğu benchmark (<5s hədəf; mart-larda <1s gözlənilir); tam gecə E2E məşqi + alert testi; prod rollout memo: snapshot rejimi, RG cap, watchdog, backup pəncərəsi ilə koordinasiya, server spec, ops sahibliyi, config-update drift proseduru.

## 1C 8.2 texniki tələləri (ETL-də mütləq nəzərə alınır)

- **JSON yoxdur** → обработка XML/TSV yazır; 8.3-style обработка açılmayacaq.
- **`_YearOffset`** = 0 və ya 2000 → 2000-dirsə bütün tarixlər +2000 il saxlanır → extract-da `DATEADD(year,-2000,…)`.
- `_IDRRef binary(16)` → hex açar; boş ref = 16 sıfır bayt → "Unknown" dim üzvünə (NULL yox).
- `numeric(15,x)` → string kimi oxu, JS float-a pul buraxma. `useUTC:false` (AZ UTC+4, DST yox).
- Registrator: `_RecorderTRef binary(4)` + `_RecorderRRef` — metadata xəritəsi ilə decode.
- `_Posted=0x01` filtri; `_Marked` istisna; mənfi stok / orphan ref data-quality flag-ları.
- **Backdated düzəlişlər əsas düşməndir** (həcm yox): (1) `_Version` rowversion varsa — dəqiq cursor; (2) hər gecə 7 günlük sliding re-extract; (3) rekonsiliasiya-repair (13 ay geriyə kontrol cəmlər, uyğunsuz gün avto-yenidən çəkilir).
- Config yenilənəndə `_Fld` nömrələri dəyişə bilər → обработка yenidən işlədilir; ETL start-da sxem assert edir, drift-də dayanıb alert verir (heç vaxt səssiz zibil yükləmir).

## LeadDrive-dan lift edilən komponentlər (yoxlanılmış yollar)

| Komponent | Yol | Qeyd |
|---|---|---|
| Anthropic client factory | `src/lib/ai/anthropic-client.ts` | As-is (timeout/retry tuned) |
| PII masker | `src/lib/ai/pii-masker.ts` | Variant D narrasiya üçün |
| CSV/XLSX export | `src/lib/export/tabular.ts` | As-is (BOM, formula-injection guard) |
| Səhər push cron | `src/app/api/cron/scheduled-reports/route.ts` | Pattern as-is; `executeReport` → mart sorğuları |
| Email sender | `src/lib/email.ts` | **Diqqət: `isPrivateHost` SSRF guard-ı lokal SMTP relay-i bloklayır → konfiq edilə bilən olmalıdır** |
| KPI card + sparkline-lar | `src/components/dashboard/kpi-card.tsx`, `src/components/charts/mini-charts.tsx` | As-is |
| Recharts dashboards, `SavedReport` JSON sxemi | müxtəlif | Adaptasiya ilə |

Yeni repo (təklif: `pharma-dwh` / `leaddrive-analytics`): `mssql` + `pg` əlavə olunur (leaddrive-v2-də yoxdur). `1c-erp/inbound-sync.ts` HTTP-sync-dir — yalnız error-isolation konvensiyaları götürülür, kod yox.

## Boşluq siyahısı (PoC-də həll yeri göstərilib)

1. Fakt qreyni: sənəd sətri × seriya (seriya nullable); DataMatrix varsa GS1 AI parse (01 GTIN/17 expiry/10 batch) — expiry zənginləşdirmə (Phase 2).
2. Qaytarmalar: işarəli sətirlər bir faktda + `doc_type`; orijinal satışa link (Phase 2).
3. **Multi-təşkilat + intercompany satışlar** — regionda çox rast gəlinir; istisna olunmasa dövriyyə şişir. `DimOrg` + intercompany flag (Gate 1 sualı).
4. Multi-anbar + gündəlik EOD stok materializasiyası (Phase 2).
5. **Tədarükçü retro-bonusları** — marjanı ciddi əyir; maliyyə ilə in/out qərarı (questionnaire + Gate 1).
6. Valyuta: alışlar USD/EUR ola bilər → məzənnə registri (Phase 2).
7. Endirimlər: gross vs net revenue tərifi metrik memo-da (Phase 0.4).
8. Xərc ayırma modeli: hansı sənədlər, şöbələrə necə — maliyyə workshop-u (Phase 1).
9. Auth: PoC = credentials + şöbə rolları; prod = AD/LDAP; row-level security PoC-dən kənardır (sənədləşir).
10. Şöbə→hesabat matrisi müştəri imzası ilə; ETL uğursuzsa — köhnə data **görünən "data as of" banner-i ilə**, heç vaxt boşluq/sükut.
11. AZ təqvimi + iş-günü-uyğun dövr müqayisələri (MTD vs eyni iş günləri), UTC+4.
12. XLSX 1M sətir limiti → export paginasiyası; PDF push üçün puppeteer-core (stack-də var).
13. Zero-impact sübut protokolu: ETL gecəsi vs baseline perf counter-lər → müştəriyə ölçülmüş artefakt.

## Yoxlama (verification)

- **Gate 1:** discovery hesabatı + maya branch qərarı + NL go/no-go — sənədlə.
- **Gate 2:** dövriyyə/say/ƏDV 1C ilə manatı-manata — maliyyəçi imzası.
- **Marja:** bağlanmış ay = dəqiq üzləşmə; D-1 = "ilkin" + fərq payı sənədləşir.
- **Performans:** top-10 sorğu <5s (gözlənti <1s); tam gecə E2E məşqi log + alert testi ilə.
- **Zero-impact:** PoC tamamilə kopyada (konstruksiya ilə sıfır); prod rollout-da ölçülmüş counter müqayisəsi.
- NL (varsa): 20 qızıl sual dəsti üzrə dəqiqlik hesabatı.

## İlk icra addımı (plan təsdiqlənsə)

Phase 0 artefaktlarından başlanır: (1) IT sorğu vərəqi → dərhal müştəriyə göndərilə bilər; (2) 8.2 обработка + DBNames fallback skripti; (3) discovery SQL paketi; (4) DWH DDL + metrik memo; (5) ETL skelet repo + docker-compose. Bunların hamısı müştəri sahəsinə getmədən, bu maşında hazırlanır.
