# Metrik tərifləri memosu / Меморандум определений метрик

> **Məqsəd:** platformanın göstərdiyi hər rəqəmin maliyyə şöbəsinin rəqəmi ilə eyni
> qaydada hesablanması. Bu sənəd maliyyə tərəfindən imzalanır və "tək həqiqət mənbəyi"
> sayılır. Dəyişiklik — yalnız yazılı razılaşma ilə (versiya tarixçəsi aşağıda).

## 1. Təsdiqlənmiş ilkin qaydalar (müştəri ilə razılaşdırılıb, 2026-06-11)

| Metrik | Qayda | Status |
|---|---|---|
| Dövriyyə (выручка) | **ƏDV daxil** | ✔ təsdiq |
| Maya dəyəri (себестоимость) | **Orta maya (средняя)** | ✔ təsdiq |
| Qaytarmalar (возвраты) | **Stokdan çıxılır**, satışdan çıxılaraq "net satış" hesablanır | ✔ təsdiq |
| Təzəlik | **D-1** (dünənki günün sonu) | ✔ təsdiq |

## 2. Dəqiqləşdirilməli qaydalar (Gate 1 / maliyyə workshop-u)

| # | Sual | Variantlar | Qərar |
|---|---|---|---|
| M1 | Marja düsturu | `Net satış (ƏDV daxil) − Orta maya` yoxsa ƏDV-siz baza ilə? (ƏDV daxil dövriyyə + ƏDV-siz maya qarışdırılsa, marja şişər — ayrıca sütunlarda hər ikisini göstərmək təklif olunur) | |
| M2 | Доп. расходы (nəqliyyat, gömrük) | Mayaya daxil edilirmi (1C-də «Поступление доп. расходов»)? | |
| M3 | Tədarükçü retro-bonusları | Marjaya daxil / ayrıca sətir / kənarda? | |
| M4 | Endirimlər | Dövriyyə gross (endirimdən əvvəl) yoxsa net (sənəddəki yekun)? | |
| M5 | İntercompany satışlar | Konsolidə hesabatlarda istisna olunur? | |
| M6 | Xərclərin şöbələrə ayrılması | Hansı açarla (birbaşa sənəddən / proporsional)? | |
| M7 | "Ölü stok" tərifi | Neçə gün hərəkətsiz? (təklif: 90 gün) | |
| M8 | Expiry risk zonaları | Təklif: <3 ay qırmızı, 3–6 ay sarı, >6 ay yaşıl | |

## 3. Marja statusu (vacib gözlənti idarəetməsi)

1C 8.2-də maya ay bağlananda yekunlaşır. Buna görə:

- **Bağlanmış ay** → marja 1C ilə **manatı-manata üzləşdirilir** (yekun status).
- **Cari ay / D-1** → marja **"ilkin"** statusla göstərilir (DWH-də çəkili orta maya);
  ay bağlandıqda avtomatik yenidən hesablanır (true-up) və fərq jurnalı saxlanılır.
- Platformada hər marja rəqəminin yanında status nişanı olacaq: `yekun` / `ilkin`.

## 4. İmza

| Rol | Ad | Tarix | İmza |
|---|---|---|---|
| Maliyyə (müştəri) | | | |
| İcraçı (LeadDrive) | | | |

## Versiya tarixçəsi

- v0.1 — 2026-06-11 — ilkin draft (bölmə 1 müştəri cavablarından).
