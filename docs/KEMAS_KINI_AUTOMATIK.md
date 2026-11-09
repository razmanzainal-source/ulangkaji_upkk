# Kemas Kini Automatik

App memeriksa versi baharu setiap kali dibuka. Pemeriksaan ini **tidak
menghalang app daripada berfungsi tanpa Internet** — kegagalan rangkaian
diabaikan sepenuhnya.

## Cara ia berfungsi

1. Selepas app dibuka (skrin Rumah dipaparkan), `SemakanVersi` membuat
   semakan di latar belakang.
2. **iOS** — versi terbaharu dibaca terus daripada **App Store** melalui
   iTunes Lookup API (menggunakan id app, kaedah sama seperti app Wira Kira):
   `https://itunes.apple.com/lookup?id=6830672652&country=my`
   Jadi setiap kali versi baharu disahkan Apple dan tersedia di kedai, app
   lama terus tahu — **tanpa** perlu mengemas kini fail manual.
3. **Android** (dan sebagai sandaran) — versi dibaca daripada
   `https://razmanzainal-source.github.io/ulangkaji-upkk-legal/versi.json`.
4. Versi semasa dibaca daripada `package_info_plus` (versi sebenar app).
5. Perbandingan dibuat mengikut angka (2.10.0 > 2.9.0):

| Keadaan | Tindakan |
|---|---|
| `versi_semasa >= terkini` | Tiada gangguan |
| `minimum <= versi_semasa < terkini` | Dialog **"Versi baharu tersedia"** — butang *Nanti* dan *Kemas kini sekarang* |
| `versi_semasa < minimum` | Dialog **"Kemas kini diperlukan"** — tidak boleh ditutup, butang kembali disekat |

Butang *Kemas kini sekarang* membuka App Store (iOS) atau Google Play
(Android) terus pada halaman app.

Masa tamat: 5 saat (sambungan) / 6 saat (keseluruhan). Selepas itu semakan
dibatalkan dan app berjalan seperti biasa.

## Format `versi.json`

Fail tinggal dalam repo `razmanzainal-source/ulangkaji-upkk-legal`:

```json
{
  "nota": "Versi 2.1.0: tip sukarela RM 3 / RM 5 / RM 10.",
  "android": { "terkini": "2.1.0", "minimum": "2.0.0" },
  "ios":     { "terkini": "2.1.0", "minimum": "2.0.0" }
}
```

- `terkini` — versi terbaharu di kedai. Pada iOS, nilai ini ditindih oleh
  versi sebenar App Store; pada Android ia sumber utama.
- `minimum` — versi paling lama yang dibenarkan. **Ini satu-satunya kawalan
  untuk memaksa kemas kini pada iOS.** Jika `minimum` sama dengan versi
  terkini, semua versi lama dipaksa mengemas kini.
- `pautan` (pilihan) — ganti pautan kedai lalai.
- `nota` (pilihan) — ayat tambahan pada dialog.

## Senarai semak setiap kali versi baharu diterbitkan

1. Naikkan `version:` dalam `pubspec.yaml` dan `InfoScreen.versi`.
2. Terbitkan versi baharu ke App Store / Play.
3. **Selepas** versi baharu tersedia di kedai, kemas kini `versi.json`:
   - `terkini` → versi baharu
   - `minimum` → naikkan hanya apabila versi lama memang tidak lagi
     dibenarkan (contoh: perubahan skema data)
4. Jangan naikkan `minimum` melebihi versi yang benar-benar sudah tersedia di
   kedua-dua kedai — pengguna akan terperangkap pada dialog yang tidak boleh
   ditutup tanpa pautan kemas kini yang berfungsi.

## Ujian

`test/semakan_versi_test.dart` mengunci:

- perbandingan versi secara angka (bukan abjad),
- `minimum` memaksa, `terkini` hanya menggalakkan,
- iOS: versi App Store mengatasi `versi.json`, dan tanpa `versi.json` kemas
  kini hanya digalakkan,
- JSON rosak / tiada rangkaian tidak membaling ralat,
- dialog paksa tiada butang *Nanti*.
