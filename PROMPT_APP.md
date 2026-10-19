# PROMPT_APP.md — Spesifikasi & Prompt untuk App Ulang Kaji Raz

Dokumen ini menerangkan **setiap ciri** app *Sejarah Tahun 5 Bersama Raz* dengan
cukup terperinci untuk dijadikan **prompt pembinaan app seterusnya** (subjek,
tahun atau bahasa lain). Ia mengandungi:

1. **Prompt sedia guna** — salin terus ke sesi AI untuk memulakan projek baharu.
2. **Spesifikasi penuh** — semua keputusan reka bentuk, peraturan dan perangkap
   yang sudah terbukti dalam app ini.

> Semua nombor dalam dokumen ini ialah nilai sebenar app ini. Untuk app baharu,
> tukar bahagian bertanda `{...}` sahaja (contoh: `{SUBJEK}` = Sejarah,
> `{TAHUN}` = 5).

---

## 0. Prompt sedia guna

```text
Bina app ulang kaji {SUBJEK} Tahun {TAHUN} untuk kanak-kanak sekolah rendah
Malaysia, dalam Bahasa Melayu sahaja, berfungsi SEPENUHNYA tanpa Internet.

Nama paparan launcher: "{SUBJEK} {TAHUN}" (pendek, muat di bawah ikon).
Tajuk dalam app: "{SUBJEK} Tahun {TAHUN} Bersama Raz".
Maskot: burung hantu bernama Raz. Ikon app dan maskot mesti daripada SATU
karya yang sama (burung hantu bercermin mata dan bertopi graduasi), dengan
warna tema app — bukan dua watak berlainan.
Kredit: hanya "© 2026 Razman Zainal" — tiada ayat "Dibangunkan oleh".

Sasaran: Android (APK pilihan utama) dan iOS. Web hanya untuk semakan reka bentuk.
Tema: biru #1565C0 (utama) / biru muda #42A5F5, latar biru sangat muda
#F4F8FD, kad putih.

Bina empat tab bawah: Topik, Uji Diri, Kemajuan, Info.
- Topik: 12 topik mengikut DSKP (satu topik satu Standard Kandungan),
  25 soalan setiap topik. Ketik topik → sesi 5 soalan.
- Uji Diri: Kertas Percubaan format UASA (Bahagian A, B dan C) +
  Latih Topik Lemah.
- Kemajuan: Laporan Ibu Bapa & Guru.
- Info: maklumat, sumber, penafian, privasi, sumbangan (kod QR) dan kredit.

Ciri wajib:
1. Bank soalan JSON luar talian: 300 soalan (12 unit × 25), jenis pilihan
   A–D (termasuk soalan bergambar), betul/salah, betul/salah berkelompok,
   padan, susun, isi tempat kosong dan taip (jawapan bertulis idea).
2. Bintang 0–3 bagi setiap unit berdasarkan peratus soalan yang sudah dikuasai
   (3 bintang ≥ 90%, 2 ≥ 70%, 1 ≥ 35%).
3. Kertas percubaan UASA SEBENAR: 50 markah dalam 1 jam 15 minit —
   Bahagian A 20 soalan objektif (20 markah), Bahagian B 4 soalan
   (padan 5 pasang, betul/salah 5 pernyataan, isi tempat kosong 5 kosong,
   jawapan idea 5 isi = 20 markah), Bahagian C 2 soalan respons terhad
   (5 idea setiap satu = 10 markah). Kertas DISELESAIKAN seperti kertas
   sekolah: markah "pen merah", markah setiap soalan dan setiap bahagian,
   cop gred UASA (A 82–100, B 66–81, C 50–65, D 35–49, E 20–34, F 0–19).
4. Soalan bertulis dimarkah mengikut skema UASA: 1 isi = 1 markah, jawapan
   separa tetap diberi markah; had 150 aksara; selepas semakan mesti tunjuk
   jawapan contoh dan nota penerangan. Ejaan hampir betul diterima, tetapi
   angka dan tahun mesti tepat.
5. Suara Bahasa Melayu AUTOMATIK: klip rakaman yang dibungkus dalam app
   dimainkan selalu; enjin suara peranti hanya sandaran supaya app tidak
   pernah senyap. Tiada tetapan suara untuk ibu bapa. Nama anak tidak pernah
   disebut oleh rakaman (nama hanya pada kepala surat kertas).
6. Keputusan Kertas Percubaan boleh DIKONGSI ke media sosial (WhatsApp,
   Facebook, Instagram, Threads): tangkap kad kertas bertanda sebagai gambar
   PNG dan hantar bersama kapsyen ringkas. Media sosial tidak menerima teks
   sahaja, jadi mesti gambar.
7. Ikon app: satu karya burung hantu bertema {SUBJEK} dijana untuk semua saiz
   Android (termasuk lapisan adaptif dengan kandungan dalam zon selamat 66dp),
   iOS (legap, tiada sudut bulat) dan web. Maskot dalam app dipotong daripada
   karya yang sama menjadi lencana bulatan.
8. Semua data kekal dalam telefon (SharedPreferences). Tiada akaun, tiada
   analitik, tiada iklan, tiada panggilan rangkaian ketika app digunakan.

Tulis kod dengan ulasan Bahasa Melayu, uji dengan `flutter test` (guna fon palsu
ujian, tiada `pumpAndSettle` bila ada animasi berulang), dan pastikan
`flutter analyze` bersih sebelum selesai.
```

---

## 1. Identiti app

| Perkara | Nilai |
| --- | --- |
| Nama launcher (Android `android:label`, iOS `CFBundleDisplayName`/`CFBundleName`, `web/manifest.json`, `web/index.html`) | **Sejarah 5** |
| Tajuk dalam app | **Sejarah Tahun 5 Bersama Raz** |
| Package / bundle id | `com.razmanzainal.sejarah_tahun5` (iOS: `com.razmanzainal.sejarahTahun5`) |
| Ikon app & maskot | daripada **satu karya** (`tools/karya_ikon.png`): burung hantu bercermin mata dan bertopi graduasi atas kad biru "SEJARAH TAHUN 5". Ikon dijana oleh `python3 tools/jana_ikon.py`, maskot oleh `python3 tools/potong_maskot.py` (lihat 3.1) |
| Kredit | **hanya** `© 2026 Razman Zainal.` |
| Versi | `versiApp` dalam `info_screen.dart` **mesti sama** dengan `pubspec.yaml` (1.0.0) |
| Bahasa | Bahasa Melayu sahaja (UASA/KSSR) — tiada kod dwibahasa |

Peraturan yang mudah dilanggar:

- Jangan sekali-kali tulis "Dibangunkan oleh Razman Zainal" — hanya simbol hak
  cipta.
- Nama launcher **pendek**; tajuk penuh hanya di dalam app.

---

## 2. Platform & keperluan teknik

- **Android = sasaran utama** (APK, dipasang terus ke telefon keluarga).
- **iOS = sokongan penuh** (Xcode/simulator untuk semakan; pemasangan ke iPhone
  sebenar memerlukan tandatangan Apple pembangun).
- **Web = untuk semakan reka bentuk sahaja** (bukan untuk murid; app dibina
  untuk telefon).

Pakej yang digunakan:

| Pakej | Guna |
| --- | --- |
| `audioplayers` | memainkan klip rakaman suara dan kesan bunyi |
| `flutter_tts` | enjin suara peranti — **sandaran sahaja** |
| `shared_preferences` | simpan kemajuan, nama anak, rekod kertas (kekal dalam telefon) |
| `gal` | simpan gambar kad keputusan / kod QR ke galeri |
| `share_plus` | kongsi gambar keputusan ke media sosial |
| `url_launcher` | buka pautan sumber rasmi (hanya apabila diketuk sendiri) |
| `web` | `package:web` untuk muat turun fail pada pelayar web |

Peraturan teknik:

- Tiada panggilan rangkaian ketika app digunakan. Semua aset dibungkus dalam
  app (`assets/content/soalan_tahun5.json`, `assets/bunyi/`, `assets/gambar/`).
- Semua pautan luar ialah `https` dan dibuka dengan `url_launcher` sahaja.
- Audio dijana **pada masa pembinaan** (bukan dalam app) melalui
  `tools/jana_suara.py`; app hanya memainkan fail `.m4a` yang dibungkus.

---

## 3. Tema & reka bentuk

Warna berpusat dalam `lib/tema.dart` (`class Warna`):

| Nama | Nilai | Guna |
| --- | --- | --- |
| `utama` | `#1565C0` | warna utama (butang, kepala, aksen) |
| `utamaMuda` | `#42A5F5` | gradien dan sorotan |
| `latarSkrin` | `#F4F8FD` | latar skrin (biru sangat muda) |
| `betul` / `latarBetul` | `#2E7D32` / `#E8F5E9` | maklum balas betul |
| `salah` / `latarSalah` | `#E53935` / `#FFEBEE` | maklum balas salah |
| `latarNota` / `tepiNota` | `#FFF8E1` / `#FFB300` | kad nota penerangan |
| `dakwat` | `#D32F2F` | "pen merah" pada kertas percubaan |

Biru dipilih kerana tenang dan serius (sesuai Sejarah) tetapi masih terang
untuk kanak-kanak Tahun 5. Jangan tukar warna tanpa menyemak skrin `UjianScreen`
dan `KertasBertanda` — keduanya bergantung pada kontras kad putih atas latar.

**Saiz teks** mesti datang daripada `class Teks` sahaja (`gergasi` 36,
`rajah` 64, `tajuk` 26, `besar` 22, `sederhana`, `kecil` …). Ketebalan dan
warna boleh diubah dengan `copyWith`, tetapi **saiz tidak boleh** ditulis
terus dalam skrin.

### 3.1 Ikon app & maskot Raz

Semua aset watak datang daripada **satu karya**: `tools/karya_ikon.png`
(burung hantu bercermin mata dan bertopi graduasi atas kad biru bulat,
bertulis "SEJARAH TAHUN 5").

1. `tools/jana_ikon.py`:
   - memangkas bingkai karya (6.5% setiap sisi);
   - **tidak menukar warna** — karya sudah biru tema app (jika karya app
     baharu berwarna lain, geser hue keseluruhan kecuali mata/kulit);
   - menjana ikon Android (semua ketumpatan + lapisan adaptif 108dp dengan
     kandungan dalam zon selamat), iOS (legap, tiada sudut bulat) dan web.
2. `tools/potong_maskot.py`:
   - memotong **lencana bulatan** (potong bulat + cincin putih) daripada karya
     — pendekatan ini dipilih kerana pemotongan lutsinar gaya "cutout" gagal
     apabila warna watak hampir sama dengan latar biru;
   - menyimpan `assets/gambar/maskot_raz.png` (badan penuh) dan
     `maskot_raz_muka.png` (muka sahaja).

Widget `Maskot` (`lib/widgets/maskot.dart`):

- `saiz` lalai 84; di bawah `_ambangMuka = 84` guna `maskot_raz_muka.png`,
  jika tidak `maskot_raz.png`;
- mood (`MoodMaskot.biasa`, gembira, fikir, idea …) menukar lencana emoji dan
  denyutan skala — **jangan** `pumpAndSettle()` dalam ujian kerana denyutan ini
  berulang tanpa henti.

---

## 4. Struktur navigasi

Empat tab di bawah (`lib/screens/rumah_screen.dart`):

| Tab | Skrin | Isi |
| --- | --- | --- |
| **Topik** | `peta_screen.dart` | senarai 12 topik (kad ikon + bintang + peratus) |
| **Uji Diri** | `uji_diri_screen.dart` | butang Kertas Percubaan + Latih Topik Lemah |
| **Kemajuan** | `laporan_screen.dart` | Laporan Ibu Bapa & Guru |
| **Info** | `info_screen.dart` | maklumat, sumber, penafian, privasi, sumbangan, kredit |

Skrin sokongan: `latih_tubi_screen.dart` (latihan 5 soalan satu topik),
`ujian_screen.dart` (kertas percubaan), `kongsi_screen.dart` (pratonton +
kongsi).

**12 unit** (satu unit = satu Standard Kandungan DSKP):

| # | Kod | Nama | Ikon | Awalan id |
| --- | --- | --- | --- | --- |
| 1 | 6.1 | Institusi Raja | 👑 | `raja-` |
| 2 | 6.2 | Agama Islam | 🕌 | `islam-` |
| 3 | 6.3 | Bahasa Melayu | 📜 | `bahasa-` |
| 4 | 7.1 | Campur Tangan dan Penjajahan Kuasa Asing | 🏰 | `jajah-` |
| 5 | 7.2 | Perjuangan Menentang Campur Tangan dan Penjajahan | ⚔️ | `juang-` |
| 6 | 7.3 | Sejarah Kemerdekaan 1957 | 🎊 | `merdeka-` |
| 7 | 8.1 | Institusi Yang di-Pertuan Agong | 🤴 | `agong-` |
| 8 | 9.1 | Jata Negara | 🛡️ | `jata-` |
| 9 | 9.2 | Bendera Kebangsaan | 🚩 | `bendera-` |
| 10 | 9.3 | Lagu Kebangsaan | 🎵 | `lagu-` |
| 11 | 9.4 | Bahasa Kebangsaan | 🗣️ | `bk-` |
| 12 | 9.5 | Bunga Kebangsaan | 🌺 | `bunga-` |

---

## 5. Bank soalan (data, bukan kod)

Bank ialah **sumber semua soalan** app: latihan topik, Uji Diri dan Kertas
Percubaan. Salah di sini = salah dalam app.

### 5.1 Bentuk fail

`assets/content/soalan_tahun5.json` dihasilkan daripada 12 fail unit. Bentuk
fail unit:

```json
{
  "id": "institusi-raja",
  "kod": "6.1",
  "nama": "Institusi Raja",
  "bidang": "Warisan Negara Kita",
  "ikon": "👑",
  "warna": "#1565C0",
  "soalan": [ ... 25 soalan ... ]
}
```

Semua soalan ada `id`, `sp`, `jenis`, `soalan`, `nota`, `ikon`, `aras`;
soalan objektif (`mcq`, `gambar`, `betul_salah`) ada `pilihan` + `jawapan`.
Jenis dan medan tambahannya:

| `jenis` | Medan tambahan | Peraturan penting |
| --- | --- | --- |
| `mcq` | `pilihan` (4), `jawapan` (indeks 0–3) | jawapan = indeks dalam susunan seperti ditulis |
| `gambar` | `pilihan` (4), `jawapan` (indeks) + **salah satu**: `rajah` (emoji) **atau** `gambar` (laluan penuh, contoh `assets/gambar/jata_negara.png`) | jangan cipta nama fail baharu; 7 unit guna PNG, 5 unit emoji sahaja |
| `betul_salah` | `pilihan` `["Betul","Salah"]`, `jawapan` 0/1 | setiap unit mesti ada satu `0` dan satu `1` |
| `padan` | `pasangan` (tepat 5 `{a,b}`) | sisi `a` 1–4 perkataan, sisi `b` satu ayat pendek; elak dua `b` yang boleh diterima |
| `susun` | `urutan` (4–5 item) | ditulis dalam **urutan betul**; app mengocok paparan |
| `tempat_kosong` | `ayat` (5, setiap satu ada `____`), **`jawapanKosong`** (5) | nama medan jawapan ialah `jawapanKosong`, **bukan** `jawapan` |
| `betul_salah_set` | `pernyataan` (tepat 5 `{teks, jawapan}`) | campur `true`/`false`, sekurang-kurangnya 2 setiap satu |
| `taip` | `idea` (2–5), `jawapanContoh` | **setiap idea = 1 markah**; markah penuh = `idea.length` |

Komposisi **setiap** unit (25 soalan, wajib tepat):

```
13 mcq + 1 gambar + 2 betul_salah
       + 1 padan + 1 susun + 1 tempat_kosong + 1 betul_salah_set
       + 2 taip (2–3 idea) + 3 taip (5 idea)
```

Nota `taip`: `idea` ada `maksud` (untuk guru) dan `kata` (kata kunci huruf
kecil, bentuk akar). Semak supaya satu kata kunci tidak muncul dalam dua idea
soalan yang sama. `jawapanContoh` satu ayat lengkap, ≤150 aksara.

### 5.2 Saluran penulisan (`build/bank/`)

| Fail | Fungsi |
| --- | --- |
| `PANDUAN.md` | kontrak data penuh (baca sebelum menulis soalan) |
| `fakta.md` | senarai fakta yang dibenarkan + senarai "JANGAN GUNA" |
| `fakta_semakan.md` | laporan semakan fakta beserta sumber (buku teks, laman rasmi) |
| `unit01.json`–`unit12.json` | soalan mentah setiap unit |
| `semak_unit.py` | pengesah bentuk + komposisi + jawapan contoh (mesti keluar kod 0) |
| `pemarkah.py` | port Python enjin pemarkahan Dart — **mesti kekal sepadan** |
| `bina_bank.py` | mencantum semua unit menjadi `assets/content/soalan_tahun5.json` |

```bash
python3 build/bank/semak_unit.py build/bank/unit*.json   # semak kandungan
python3 build/bank/bina_bank.py                          # bina semula bank
```

`semak_unit.py` memeriksa: bentuk JSON, komposisi 25 soalan, id unik, julat
jawapan, dan **setiap `jawapanContoh` mesti mendapat markah penuh** mengikut
pemarkah (supaya contoh jawapan yang dipaparkan kepada murid betul-betul layak
5/5).

### 5.3 Audit kandungan (wajib)

- Fakta dikunci dalam `fakta.md`. Jangan tambah tarikh, nama atau angka yang
  tidak ada di sana tanpa pengesahan.
- Rujuk DSKP (salinan PDF dalam `docs/dskp/`) untuk kod SP; setiap `sp` mesti
  kod SP dalam unit itu sahaja (81 SP keseluruhan).
- **Jangan salin** buku teks atau kertas peperiksaan. Soalan ditulis sendiri;
  buku teks dan laman rasmi hanya untuk menyemak fakta (senarai penuh dalam
  `fakta_semakan.md`).
- Nada: mesra, tenang, tiada politik kepartian, tiada perbandingan yang boleh
  menyinggung mana-mana kaum, agama atau institusi; tiada gambaran kejam.
- Semua unit mesti boleh menyumbang: ≥14 soalan objektif, `padan`,
  `betul_salah_set`, `tempat_kosong`, dan ≥3 `taip` 5 markah (bahan Bahagian B
  dan C kertas percubaan).

---

## 6. Mod ulang kaji (Topik → Latih Tubi)

- Satu topik = satu unit 25 soalan. Setiap sesi latihan = **5 soalan**
  (`LatihTubiScreen.bilanganSoalanSesi`).
- Pemilihan soalan (`lib/services/pemilih_soalan.dart`): utamakan soalan yang
  belum dikuasai / pernah salah, kemudian yang belum dijawab, kemudian rawak.
- Maklum balas serta-merta setiap soalan: betul/salah, nota penerangan, butang
  dengar audio.
- **Bintang & penguasaan** (`lib/services/kemajuan.dart`):
  - soalan "dikuasai" apabila pernah dijawab betul;
  - bintang unit: nisbah dikuasai ≥ 0.9 → 3, ≥ 0.7 → 2, ≥ 0.35 → 1, jika tidak 0;
  - "Latih Topik Lemah": soalan yang pernah salah dan belum dikuasai, diulang
    sehingga dikuasai.
- Semua jenis boleh dimainkan: pilihan A–D (`ButangPilihan`), padan
  (`PapanPadan` — ketik pasangan), susun (`PapanSusun` — seret kad), tempat
  kosong (`PapanTempatKosong` — pilih kata dari bank yang dikocok), betul/salah
  set (`PapanBetulSalah`), taip (`PapanTaip` — had 150 aksara, kiraan aksara).

---

## 7. Mod ujian — Kertas Percubaan (ciri paling penting)

### 7.1 Membina kertas

Format **UASA KPM Sejarah Tahun 5**: **50 markah dalam 1 jam 15 minit**
(`masaKertasTeks` dalam `pemilih_soalan.dart`).

| Bahagian | Kandungan | Markah |
| --- | --- | --- |
| **A** | 20 soalan objektif (`mcq` + `gambar`) campuran semua topik, kuota seimbang | 20 |
| **B** | 4 soalan: 1 `padan` (5 pasang), 1 `betul_salah_set` (5 pernyataan), 1 `tempat_kosong` (5 kosong), 1 `taip` (5 idea) | 20 |
| **C** | 2 `taip` 5 idea daripada topik berbeza | 10 |

- Soalan Bahagian B dan C mesti daripada topik berlainan.
- Bahagian ditentukan mengikut kedudukan dalam senarai: 20 pertama = A,
  4 berikutnya = B, selebihnya = C (disimpan supaya kertas boleh disambung).
- Pemilihan mengutamakan soalan yang pernah salah, tetapi kertas mestilah
  lengkap walaupun bank baharu.

### 7.2 Skema markah (UASA)

- **1 isi = 1 markah** (rubrik UASA). `taip` 5 idea = 5 markah; markah penuh
  = `idea.length`.
- **Markah separa**: 3 daripada 5 idea betul = 3 markah — bukan betul/salah.
- `padan` 5 pasang = 5 markah; `tempat_kosong` 5 kosong = 5 markah;
  `betul_salah_set` 5 pernyataan = 5 markah (setiap pernyataan 1 markah).
- Jumlah kertas 50 markah; peratus = markah / 50 × 100.

### 7.3 Jadual gred UASA (mesti tepat)

| Gred | Julat | Nama |
| --- | --- | --- |
| A | 82–100 | Cemerlang |
| B | 66–81 | Kepujian |
| C | 50–65 | Baik |
| D | 35–49 | Memuaskan |
| E | 20–34 | Mencapai Tahap Minimum |
| F | 0–19 | Tidak Mencapai Tahap Minimum |

### 7.4 Skrin "kertas bertanda" (`lib/widgets/kad_kertas_bertanda.dart`)

Kertas dipaparkan seperti **kertas yang sudah ditanda guru**:

1. **Kepala surat** — nama sekolah/subjek ("SEJARAH TAHUN 5"), nama anak,
   tarikh, masa.
2. **Pemisah garis putus-putus** (`GarisPutus`).
3. **Blok markah "pen merah"** — label `MARKAH`, jumlah `42 / 50`, peratus, dan
   **markah setiap bahagian** (A, B, C) — semuanya dalam warna `Warna.dakwat`
   (merah, condong), dengan `✓` / `✗` daripada **ikon Material** (bukan emoji).
4. **Cop gred** — bulatan berlapis dengan `Transform.rotate` sedikit, teks
   `GRED` kecil + huruf besar + nama gred, dalam warna gred.
5. **Markah setiap soalan** — grid `Wrap` cip: nombor soalan + markah
   (`3/5` untuk bertulis, ikon ✓/✗ untuk objektif).
6. Bintang (0–3) dan ayat galakan **di luar** kad kertas.
7. **Keputusan ikut topik** — bar kemajuan setiap unit.
8. **Soalan yang perlu diulang** — kad semakan: soalan, badge markah pen merah,
   jawapan sepatutnya (hijau + ikon), butang dengar, nota penerangan.
9. Butang `Kertas Baharu` (kertas baharu daripada set soalan yang sama).

### 7.5 Kongsi keputusan ke media sosial

- `lib/services/kongsi.dart` menangkap `KadKertasBertanda` **pada 3×
  resolusi** (gambar tajam), menyimpannya sebagai PNG sementara, dan membuka
  share sheet peranti (`share_plus`) bersama kapsyen ringkas.
- Media sosial (Instagram, Threads) **tidak menerima teks sahaja** — gambar
  PNG mesti dihantar bersama teks.
- Kapsyen: nama anak (jika ada), markah kertas, peratus dan gred. **Tiada**
  kod QR, tiada pautan, tiada maklumat sensitif.
- Kod QR sumbangan tidak pernah masuk ke dalam gambar yang dikongsi.

---

## 8. Soalan bertulis (`taip`) — enjin pemarkahan luar talian

`lib/services/pemarkah.dart` (dan port Pythonnya `build/bank/pemarkah.py`):

- **Pemarkahan idea**: jawapan murid dinormalkan (huruf kecil; hanya `a–z0–9`
  dikekalkan; tanda sempang memisahkan perkataan). Setiap idea ada senarai
  `kata`; jika mana-mana kata kunci hadir, idea itu dikira.
- **Bentuk terbitan diterima**: awalan/akhiran Melayu (`meN-`, `ber-`, `di-`,
  `-kan`, `-an`, `-i` …) dengan syarat bentuk dasar ≥ 4 huruf. Kata kunci
  pendek (≤ 4 huruf) mesti padan tepat.
- **Hampir betul (salah eja)**: toleransi jarak Levenshtein mengikut panjang
  perkataan — 0 untuk ≤ 4 huruf, 1 untuk 5–7 huruf, 2 untuk ≥ 8 huruf.
- **Angka dan tahun mesti tepat**: padanan hampir hanya bermula pada 5 huruf,
  jadi `1957` tidak boleh ditulis `1956`.
- **Kredit separa**: 2/5 idea = 2 markah.
- Selepas semakan, paparkan **jawapan contoh** + nota penerangan + butang
  dengar. Jawapan contoh dijamin markah penuh (disemak `semak_unit.py`).
- Had jawapan **150 aksara** (`hadAksaraJawapan`), dikira dan dipaparkan dalam
  `PapanTaip`.

Perangkap yang pernah berlaku:

- Kata kunci bersempang (`undang-undang`, `tolong-menolong`) **tidak pernah
  padan** kerana enjin membuang sempang dan memisahkan perkataan. Guna satu
  perkataan (`undang`, `tolong`, `hormat`).
- Jangan letak kata kunci yang sama dalam dua idea — satu ayat murid akan
  mendapat dua markah.
- `pemarkah.py` dan pemarkah Dart **mesti diubah serentak**; ujian Dart dan
  `semak_unit.py` akan menangkap percanggahan.

---

## 9. Suara — automatik, Bahasa Melayu, tiada tetapan

Suara bacaan ialah **rakaman** yang dijana pada masa pembinaan
(`tools/jana_suara.py`, suara `ms-MY-OsmanNeural`, kadar `-10%`):

- **1464 klip** (`assets/bunyi/suara/`, ~48 MB) + `manifest.json`:
  `{versi, suara, kadar, bilangan, fail: {kunci → nama fail}}`;
  `bilangan` = jumlah kunci (1683), `fail` = peta kunci → fail.
- Nama fail = `sha1(teks)[:16].m4a` — teks yang sama dikongsi (banyak kunci
  boleh menunjuk fail yang sama).
- Klip dimainkan **selalu** apabila ada, pada semua peranti (termasuk telefon
  yang ada suara Melayu). Enjin suara peranti (`flutter_tts`) hanya **sandaran**
  apabila klip tiada, supaya app tidak pernah senyap.
- **Nama anak tidak pernah disebut** oleh rakaman; nama hanya ditulis pada
  kepala surat. Ayat sapaan tidak mengandungi nama.
- Skema kunci (mesti sepadan antara `jana_suara.py`, `suara.dart` dan bank):
  `f-*` (ayat tetap), `q-<id>` (soalan), `p-<id>-<i>` (pilihan), `pd-<id>-<a|b>-<i>`
  (pasangan), `ps-<id>-<i>` (urutan), `tk-<id>-<i>` (jawapan kosong),
  `tb-<id>-<i>` (bank kata tempat kosong), `bs-<id>-<i>` (pernyataan
  betul/salah), `j-<id>` (jawapan contoh).
- Penjanaan: `edge-tts` (`python3 -m edge_tts --voice ms-MY-OsmanNeural
  --rate=-10%`) → mp3 → `afconvert -f m4af -d aac -b 40000` → m4a → manifest.
  Nota: `--rate` mesti ditulis `--rate=-10%` (argparse tidak menerima nilai
  bermula dengan `-` jika dipisah). Hanya sebutan baharu dijana semula
  (janaan bertambah, bukan bermula dari kosong).
- **Semakan sebutan** tanpa mendengar: `python3 tools/periksa_sebutan.py`
  mengukur kadar lintasan sifar (ZCR) klip berisiko ("Cuba lagi." mesti
  menyerupai geseran /tʃ/, bukan letupan /k/). Lulus sebelum setiap keluaran.
- Kesan bunyi (`assets/bunyi/*.m4a`) berasingan daripada rakaman suara.

---

## 10. Laporan Ibu Bapa & Guru (`LaporanScreen`)

- **Prestasi ikut topik** — peratus dikuasai setiap topik (bintang + bar).
- **Cadangan untuk ulang kaji** — ayat ringkas; topik lemah didahulukan.
- **Sejarah kertas percubaan** — markah, peratus, cop gred kecil bagi setiap
  kertas (rekod lama dihadkan) + butang set semula kemajuan.
- **Jawapan bertulis (Bahagian C)** — petikan jawapan murid dan markah rubrik
  supaya ibu bapa nampak kualiti jawapan, bukan angka sahaja.
- **Jadual gred UASA** penuh + penjelasan cara markah dikira (1 isi = 1 markah).

---

## 11. Halaman Info (`InfoScreen`)

Kandungan: pengenalan app, menu dalam app, sumber soalan (pautan DSKP BPK,
buku teks DBP dan laman rasmi yang disemak), penafian (bukan kertas rasmi KPM),
privasi (semua data dalam telefon, tiada analitik/akaun), sumbangan dan kredit
(**hanya** `© 2026 Razman Zainal.`).

- Kod QR sumbangan **tidak** dipaparkan terus; ia di sebalik butang
  "Kod QR sumbangan" yang membuka tetingkap kecil dengan butang **Simpan**
  (`gal` pada peranti, muat turun fail pada web).
- Teks kredit bunyi: "Suara bacaan: rakaman Bahasa Melayu (ms-MY) dalam app —
  klip yang sama pada setiap peranti; enjin suara telefon hanya sandaran
  apabila rakaman tiada."

---

## 12. Data & privasi

- Semua data kemajuan disimpan dengan `shared_preferences` dalam telefon:
  bilangan betul/salah setiap soalan, nama anak, rekod kertas percubaan
  (hadkan bilangan rekod lama), tetapan bunyi.
- **Tiada**: akaun, log masuk, analitik, iklan, panggilan rangkaian ketika app
  digunakan, kebenaran istimewa yang tidak perlu.
- Nama anak hanya disimpan setempat dan hanya muncul dalam app dan gambar
  keputusan yang dikongsi oleh ibu bapa sendiri.

---

## 13. Ujian & kualiti

`flutter test` — **143 ujian** (bank soalan, pemarkah, gred, suara, tangkapan
gambar, skrin) + `flutter analyze` bersih. Ujian ialah yang membolehkan
kandungan 300 soalan dan audio dikemas kini tanpa merosakkan app.

Jenis ujian yang perlu ada:

- **Data bank**: 12 unit × 25 soalan, id unik, jawapan dalam julat, komposisi
  jenis setiap unit, 168 soalan objektif, 7 fail rajah wujud.
- **Pemarkah**: imbuhan, sinonim, salah eja, had Levenshtein, angka/tahun
  (mesti tepat), jawapan kosong, kredit separa.
- **Gred**: sempadan setiap huruf (100, 82, 81, 66, 65, 50, 49, 35, 34, 20,
  19, 0), nama gred, julat teks.
- **Kemajuan**: bintang, penguasaan, topik lemah, susunan sesi, kuota kertas
  percubaan, rekod lama.
- **Suara**: pilihan automatik (peranti vs rakaman), tiada tetapan, teks yang
  disebut betul (`sebutanBetul`).
- **Skrin**: rumah/tab, latih tubi, papan `tempat_kosong` dan `betul_salah_set`,
  ujian, kertas bertanda, laporan, info (termasuk popup QR).

Gotcha yang mesti diingat (menjimatkan berjam-jam):

1. **Jangan `pumpAndSettle()`** jika skrin ada maskot beranimasi berulang —
   ia tidak akan pernah selesai. Guna `pump(Duration)` berulang.
2. `Suara.berhenti()` meninggalkan pemasa (~2 s dan ~12 s). Akhiri ujian
   widget dengan `pumpWidget(SizedBox())` diikuti `pump(Duration(seconds: 11))`.
3. Palsukan `flutter_tts` dalam `setUpAll` dengan `isLanguageAvailable → false`
   supaya ujian menggunakan rakaman, bukan enjin peranti.
4. Matikan bunyi dalam ujian (`Tetapan.instance.tetapkanBunyi(false)`).
5. Nama saluran plugin `gal` ialah `gal`; saluran global audioplayers
   (`xyz.luan/audioplayers.global/events`) mesti dipalsukan sebagai
   `MockStreamHandler`.
6. `find.text` pada teks `Text.rich` (seperti `42 / 50`) memerlukan
   `findRichText: true`.
7. Penemudi teks mesti unik — contoh `3/5` pada cip dan `3/5 markah` pada badge
   mesti berbeza rentetan.
8. Ujian `taip` menguji enjin, bukan skrin: sabitan markah penuh contoh jawapan
   ada dalam `test/pemarkah_test.dart` + `semak_unit.py`.

---

## 14. Binaan & penghantaran

```bash
# Android (sasaran utama)
flutter build apk --release
# hasil: build/app/outputs/flutter-apk/app-release.apk

# Android mengikut seni bina (jika saiz penting)
flutter build apk --release --split-per-abi

# iOS (sokongan penuh; simulator untuk semakan)
flutter build ios --release
flutter build ipa

# Web (semakan reka bentuk sahaja; bukan untuk murid)
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8090
```

- APK keluaran projek ini: **109.5 MB** (semua seni bina; audio 48 MB + aset).
  Untuk telefon keluarga, `--split-per-abi` menghasilkan APK peranti yang
  lebih kecil (hantar yang `arm64-v8a`).
- Android menandatangani dengan kunci debug (`signingConfig = debug`) — cukup
  untuk pemasangan sendiri (sideload), bukan untuk Play Store.
- Semua aset audio dan gambar **mesti dibungkus** (`assets/` dalam
  `pubspec.yaml`); semak `flutter build apk` selepas setiap penambahan aset.

---

## 15. Susunan fail (rujukan)

```
lib/
  main.dart
  models/     soalan.dart, jawapan.dart, rubrik.dart, gred.dart
  screens/    rumah_screen, peta_screen, latih_tubi_screen, uji_diri_screen,
              ujian_screen, kongsi_screen, laporan_screen, info_screen
  services/   bank_soalan, kemajuan, pemilih_soalan, pemarkah, suara, bunyi,
              tetapan, simpan_gambar (+ _io, _web), kongsi
  widgets/    butang_pilihan, maskot, dialog_nama, bunga_api, rajah_soalan,
              papan_padan, papan_susun, papan_taip, papan_tempat_kosong,
              papan_betul_salah, garis_putus, kad_kertas_bertanda, label_ikon
  tarikh.dart tarikh Bahasa Melayu
  tema.dart   skala teks dan warna berpusat

assets/
  content/soalan_tahun5.json      bank soalan (300)
  bunyi/suara/ 1464 klip + manifest.json
  bunyi/*.m4a   kesan bunyi
  gambar/       7 rajah lukisan + maskot_raz*.png + qr_donasi.png

build/bank/     PANDUAN.md, fakta.md, fakta_semakan.md, unit01–12.json,
                semak_unit.py, pemarkah.py, bina_bank.py
build/log/      log penjanaan (suara, apk)
docs/dskp/      DSKP-Sejarah-Tahun-5.pdf + DSKP.txt (sumber kod SP)
tools/          jana_suara, jana_bunyi, jana_rajah, jana_ikon,
                potong_maskot, periksa_sebutan, karya_ikon.png
test/           bank_soalan, pemarkah, gred, kertas_bertanda, kemajuan,
                suara_pilihan, sapaan, kongsi, info_screen …
```

---

## 16. Senarai semak penghantaran

- [ ] `flutter analyze` bersih; `flutter test` semua lulus.
- [ ] `python3 build/bank/semak_unit.py build/bank/unit*.json` keluar kod 0.
- [ ] `python3 tools/periksa_sebutan.py` lulus.
- [ ] Nama launcher "Sejarah 5" pada Android, iOS dan web.
- [ ] Kredit hanya `© 2026 Razman Zainal.`
- [ ] Versi `info_screen.dart` = `pubspec.yaml`.
- [ ] Tiada nama rajah baharu dalam bank tanpa fail dalam `assets/gambar/`.
- [ ] APK dibina dan dipasang pada sekurang-kurangnya satu telefon Android.
- [ ] Semak pada telefon: suara berbunyi, kertas percubaan lengkap
      (20 + 4 + 2), gambar keputusan boleh dikongsi.
- [ ] Semak DSKP/fakta untuk soalan baharu (jangan reka tarikh).

---

## 17. Pengajaran penting (jangan ulang)

1. **Format UASA mesti disahkan** daripada sumber KPM sebelum menulis bank:
   Sejarah Tahun 5 = 50 markah (A 20 + B 20 + C 10) dalam 1 jam 15 minit.
   Bahagian B ialah padan/betul-salah/isi tempat kosong/idea; Bahagian C
   respons terhad. Jangan andaikan format subjek lain sama.
2. **`jawapanKosong`** (bukan `jawapan`) untuk jawapan isi tempat kosong —
   pepijat senyap yang menjadikan semua soalan jenis itu tidak boleh dimainkan.
3. **Markah `taip` = `idea.length`**, bukan tetap 5; 21 jawapan contoh pernah
   tidak mendapat markah penuh — kini disemak automatik.
4. **Kata kunci tanpa sempang**: enjin membuang sempang → guna `undang`,
   `tolong`, `hormat`.
5. **Angka mesti tepat**: toleransi ejaan hanya untuk perkataan ≥ 5 huruf.
6. **Maskot gaya lencana bulatan** — potongan lutsinar gagal apabila warna
   watak hampir sama dengan latar; cincin putih menyelamatkan kontras.
7. **Jangan tukar hue ikon** jika karya sudah berwarna tema; hanya pangkas
   bingkai dan jana saiz.
8. **Audio dijana pada masa pembinaan** dengan `edge-tts` (suara neural
   Bahasa Melayu) — jangan harap enjin `say` macOS untuk sebutan Melayu yang
   betul (tiada suara ms-MY lelaki; "c" menjadi /k/).
9. **Jangan salin mana-mana buku teks/kertas sebenar** — soalan ditulis
   sendiri, fakta disemak, sumber direkod dalam `fakta_semakan.md`.
10. **Ujian widget**: tiada `pumpAndSettle` dengan animasi berulang; palsukan
    saluran plugin; `findRichText: true` untuk `Text.rich`.
11. **Saiz APK**: audio mendominasi; jika perlu, jana pada bitrate lebih
    rendah atau gunakan `--split-per-abi`.
12. **DSKP yang dimuat turun dari BPK** mungkin perlu pengepala pelayar (UA)
    untuk dimuat turun; simpan salinan dalam `docs/dskp/` sebagai rujukan.
