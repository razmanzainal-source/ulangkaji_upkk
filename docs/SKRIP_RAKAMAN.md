# Skrip Rakaman Skrin — Apple App Review

**Keperluan Apple (2.1):** rakaman 60–120 saat pada **peranti fizikal**, bermula
dari skrin utama peranti, menunjukkan aliran biasa app.

- **Saiz:** 60–120 saat
- **Format:** MP4 (H.264) atau MOV
- **Peranti:** iPhone fizikal (bukan simulator)
- **Audio:** tidak perlu, tetapi elok ada suara menerangkan
- **Jangan tunjuk:** data peribadi sebenar, mesej notifikasi, menu debug

---

## Persediaan (sebelum rakam)

1. iPhone: **Settings → Control Centre → Screen Recording** (tambah).
2. Tutup notifikasi: **Focus → Do Not Disturb**.
3. Pastikan app berada pada skrin utama (bukan dalam app).
4. Kosongkan nama jika mahu (dialog nama akan muncul — itu bagus untuk ditunjuk).
5. Jika mahu tunjuk pembelian tanpa transaksi sebenar: jangan tekan “Beli”
   sehingga selesai; cukup tunjuk skrin harga.

---

## Skrip (90 saat)

| Masa | Tindakan | Keterangan suara (pilihan) |
|---|---|---|
| 0:00 | Skrin utama iPhone | “Ini aplikasi Ulangkaji UPKK.” |
| 0:03 | Ketik ikon app | “Aplikasi dibuka tanpa log masuk.” |
| 0:08 | Dialog nama → ketik **Langkau** | “Tiada akaun dicipta; nama hanya paparan.” |
| 0:12 | Skrol senarai subjek | “Enam subjek UPKK.” |
| 0:18 | Ketik **Latih tubi** (Adab) | “Latih tubi percuma.” |
| 0:22 | Ketik **Mula menjawab** | “Sepuluh soalan.” |
| 0:26 | Tekan ikon pembesar suara | “Soalan dibacakan.” |
| 0:32 | Jawab satu soalan → **Seterusnya** | “Maklum balas serta-merta.” |
| 0:40 | Keluar → tab **Kertas** | “Kertas UPKK 2024 dan 2025 dalam bentuk digital.” |
| 0:46 | Ketik **Jawab** (2024) | “Mod Percubaan memerlukan pembelian.” |
| 0:50 | Muncul gerbang ibu bapa | “Gerbang matematik menghalang kanak-kanak.” |
| 0:56 | Jawab soalan gerbang | “Selepas lulus gerbang…” |
| 1:00 | Skrin **Versi Penuh** | “…barulah harga dan butang beli muncul.” |
| 1:06 | Tunjuk **Pulihkan pembelian** | “Pembelian boleh dipulihkan.” |
| 1:10 | Tutup → tab **Kemajuan** | “Rekod dan lencana disimpan dalam peranti.” |
| 1:16 | Tab **Info** → skrol ke versi | “Versi 2.0.0. Tiada iklan, tiada penjejakan.” |
| 1:25 | Tamat | “Itu sahaja.” |

---

## Selepas rakam

1. Hantar ke Mac (AirDrop) atau terus dari telefon.
2. Semak tempoh: `afinfo rakaman.mov | grep duration`
3. Muat naik dalam App Store Connect → **App Review Information → Attachment**.
4. Simpan salinan dalam folder projek: `docs/rakaman-semakan.mp4` (jangan commit
   jika saiz besar — letak pautan).

---

## Nota untuk pengulas

Rakaman ini sengaja **tidak** menyelesaikan transaksi sebenar. Skrin pembelian
dan butang “Pulihkan pembelian” ditunjukkan supaya pengulas dapat mengesahkan
aliran IAP tanpa caj.
