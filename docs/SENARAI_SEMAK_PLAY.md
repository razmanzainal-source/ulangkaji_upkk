# Senarai Semak — Google Play Console

Semua nilai di bawah sedia untuk disalin. Fail berada dalam folder `edaran/store/play/`
dan di Desktop.

---

## 1. Create app

| Medan | Nilai |
|---|---|
| App name | `Ulangkaji UPKK` |
| Default language | **Malay (ms-MY)** |
| App or game | **App** |
| Free or paid | **Free** |
| Declarations | ✅ kedua-dua kotak (Play policies + US export laws) |

---

## 2. Upload AAB (Internal testing)

`Testing → Internal testing → Create new release`

| Medan | Nilai |
|---|---|
| App bundle | `UlangkajiUPKK-2.0.0-29.aab` (169 MB) |
| Release name | `2.0.0 (29)` |
| Release notes | `Keluaran pertama: 6 subjek UPKK, kertas percubaan, laporan ibu bapa PDF.` |

Selepas muat naik: **Save → Review release → Start rollout to Internal testing**.

---

## 3. App content (wajib sebelum production)

| Bahagian | Jawapan |
|---|---|
| **Privacy policy** | `https://razmanzainal-source.github.io/ulangkaji-upkk-legal/privacy.html` |
| **Ads** | **No, my app does not contain ads** |
| **App access** | **All functionality is available without special access** |
| **Content ratings** | Isi soal selidik IARC — semua kategori **No** (tiada keganasan, tiada judi, tiada alkohol, tiada kandungan seksual, tiada dadah) |
| **Target audience** | **Ages 9–11** sahaja |
| **News app** | No |
| **Data safety** | **No data collected / No data shared** |
| **Government app** | No |
| **Financial features** | No |
| **Health** | No |

Rujukan penuh: `docs/DATA_SAFETY.md`

---

## 4. Store listing

| Medan | Nilai |
|---|---|
| Short description (80) | `Ulang kaji UPKK untuk murid Tahun 5: 6 subjek, kertas percubaan dan laporan kemajuan.` |
| Full description | Salin dari `docs/METADATA_KEDAI.md` (bahagian “Penerangan penuh”) |
| App icon | `play-icon-512.png` |
| Feature graphic | `play-feature-1024x500.png` |
| Phone screenshots | 6 fail `*_play-phone.png` |
| Category | **Education** |
| Tags | Education, Study |
| Contact email | `razman.zainal@gmail.com` |
| Website | `https://razmanzainal-source.github.io/ulangkaji-upkk-legal/` |

---

## 5. Monetization

**Tiada produk IAP untuk keluaran ini** — bahagian tip dibuang sementara
selepas semakan Apple 2.1.0. Tip akan ditambah dalam 2.1.0.

---

## 6. Testing → Production

1. **Closed testing** — tambah 12 penguji (e-mel). Kekalkan **14 hari** berterusan.
2. Selepas itu: **Apply for production access** → jawab soalan → **Create production release** → **Start rollout**.

> Keperluan 12×14 hari terpakai kepada akaun **peribadi** yang didaftarkan selepas 13 Nov 2023. Kalau akaun awak lebih lama, langkah ini mungkin dilangkau.

---

## 7. Selepas terbit

- Semak **Android vitals** (crash/ANR) setiap minggu
- Balas ulasan pengguna
- Muat naik kemas kini dengan `versionCode` lebih tinggi
