# pharma-dwh — Əczaçılıq Distribütoru üçün Analitik Hesabat Platforması (PoC)

1C 8.2 / MS SQL Server 2019 (300 GB, gündə 30k satış sənədi) üzərindən hesabatlar anbar
əməliyyatlarını dondurur. Bu layihə: **gecə ETL → PostgreSQL DWH (star schema) → dashboard +
səhər push + Claude NL→SQL** — prod bazaya sıfır təsirlə.

Tam plan: [`docs/plan.md`](docs/plan.md). PoC tam həcmli `.bak` kopyası üzərində aparılır,
prod-a toxunulmur.

## Kimə nə vermək (Phase 0 çatdırılması)

| Artefakt | Kimə | Nə edir |
|---|---|---|
| [`docs/01-questionnaire.md`](docs/01-questionnaire.md) | Müştərinin İT rəhbəri + 1C komandası | Gate 1-dən əvvəl cavablanmalı suallar |
| [`extractor-1c/`](extractor-1c/) | 1C proqramçıları | Metadata xəritəsinin çıxarılması (обработка + təlimat) |
| [`discovery-sql/`](discovery-sql/) | DBA / İT (bərpa olunmuş kopyada işlədilir) | Baza kəşfiyyatı: həcmlər, _YearOffset, _Version, sənəd inventarı |
| [`docker-compose.yml`](docker-compose.yml) | Test maşını (Linux/Docker) | PG16 DWH + Metabase bir əmrlə |
| [`docs/03-windows-runbook.md`](docs/03-windows-runbook.md) | Test maşını (Windows, Docker yoxdursa) | Native quraşdırma yolu |
| [`docs/02-metrics-memo.md`](docs/02-metrics-memo.md) | Maliyyəçi | Metrik tərifləri — imzalanmalı |

## Repo strukturu

```
docs/               plan, questionnaire, metrik memo, Windows runbook
extractor-1c/       1C 8.2 обработка mənbə kodu + təlimat (metadata xəritəsi)
discovery-sql/      00–05 T-SQL kəşfiyyat skriptləri (kopyada, read-only)
dwh/ddl/            Postgres star-schema DDL (DRAFT — Gate 1-dən sonra yekunlaşır)
dwh/semantic/       Semantik qat YAML şablonu (NL→SQL + hesabatlar üçün)
etl/                Node/TS CLI: discover | decode-dbnames | extract | transform | reconcile
docker-compose.yml  PG16 + Metabase (test maşını üçün)
```

## Quickstart (bizim tərəf)

```bash
cd etl && npm install
cp .env.example .env        # MSSQL (kopya) + PG parametrləri
npm run smoke               # DBNames decoder öz-özünə test
npx tsx src/cli.ts discover # bərpa olunmuş kopyada kəşfiyyat (out/discovery/)
```

## Gate-lər (plandan)

- **Gate 1 (Discovery, gün 1–4):** konfiqurasiya növü → maya branch-ı (A: партионный registr /
  B: DWH weighted-average + ay-sonu true-up); NL→SQL go/no-go (egress); sürprizlər.
- **Gate 2 (gün 5–9):** dövriyyə/say/ƏDV 1C ilə manatı-manata — maliyyəçi imzası.
- Marja: bağlanmış ay = dəqiq; D-1 = "ilkin" status. NL→SQL qəbul kriteriyası DEYİL.

## Statuslar

- [x] Phase 0 skeleti (bu repo)
- [ ] Questionnaire cavabları alındı
- [ ] Gate 1 — discovery hesabatı
- [ ] Gate 2 — rekonsiliasiya imzası
