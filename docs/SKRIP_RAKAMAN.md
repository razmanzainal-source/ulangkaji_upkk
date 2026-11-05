# Skrip Rakaman Skrin — App Store Review

Apple **tidak mewajibkan** rakaman untuk semua app. Ia diminta apabila app
sukar disemak (perlu perkakasan khas, akaun, atau ciri tersembunyi). Simpan
rakaman ini sedia — jika App Review memintanya, kita hantar melalui
**Resolution Center**.

- **Tempoh:** 60–120 saat
- **Peranti:** iPhone fizikal (bukan simulator)
- **Build:** 2.0.0 (28) — versi yang dihantar
- **Format:** MP4/MOV, tiada muzik latar

---

## Persediaan (2 minit)

1. iPhone → **Settings → Control Centre** → tambah **Screen Recording**
2. Hidupkan **Focus → Do Not Disturb** (elak notifikasi masuk)
3. Pastikan app **Ulangkaji UPKK** dipasang dari TestFlight (build 28)
4. **Tutup** app (tekan Home, jangan buang dari pengurus)
5. Skrin terang: **Settings → Display → Brightness** ~80%

---

## Skrip 90 saat

| Masa | Tindakan | Apa yang dibuktikan |
|---|---|---|
| 0:00 | Skrin utama iPhone | Bermula dari peranti sebenar |
| 0:03 | Ketik ikon **Ulangkaji UPKK** | App dibuka tanpa log masuk |
| 0:07 | Dialog nama → ketik **Langkau** | Tiada akaun dicipta |
| 0:11 | Skrol senarai subjek | 6 subjek, kad markah |
| 0:16 | Ketik **Latih tubi** (Adab) | Ciri percuma |
| 0:20 | Ketik **Mula menjawab** | 10 soalan |
| 0:24 | Ketik ikon **speaker** | Suara bacaan berfungsi |
| 0:30 | Jawab satu soalan → **Seterusnya** | Maklum balas |
| 0:38 | Keluar → tab **Kemajuan** | Rekod, lencana |
| 0:43 | Ketik **Laporan Ibu Bapa** | Ciri baharu |
| 0:47 | Ketik **Lihat & kongsi laporan** | Pratonton PDF |
| 0:52 | Skrol PDF, tekan **Kongsi PDF** | Helaian kongsi sistem |
| 0:57 | Batal → **Kongsi sebagai gambar** | Jalan kedua (gambar) |
| 1:02 | Batal → tab **Info** → skrol ke **Sokongan** | Kawasan ibu bapa |
| 1:08 | Ketik **Untuk Ibu Bapa & Guru** | Gerbang matematik muncul |
| 1:12 | Jawab contoh `7 + 8` → **Teruskan** | Gerbang lulus |
| 1:17 | Skrin **Sokongan Sukarela** (3 butang tip) | IAP kelihatan |
| 1:22 | **Jangan** tekan Beli — tutup | Tiada transaksi sebenar |
| 1:25 | Tamat | — |

---

## Selepas rakam

1. **Control Centre → hentikan rakaman** → file masuk Photos
2. Hantar ke Mac (AirDrop) → simpan sebagai `rakaman-appreview.mp4`
3. Semak tempoh: `afinfo rakaman-appreview.mp4 | grep duration`
4. Muat naik di **App Store Connect → App Review → Resolution Center**
   (lampiran maksimum 50 MB; jika lebih, hantar pautan)

---

## Perkara yang **tidak** boleh muncul

- Data murid sebenar (nama penuh, markah sebenar orang lain)
- Notifikasi peribadi, mesej WhatsApp, e-mel
- Menu debug / konsol pembangun
- Transaksi pembelian sebenar

---

## Nota untuk pengulas

Rakaman ini sengaja **tidak** menyelesaikan pembelian. Skrin harga dan gerbang
ibu bapa ditunjukkan supaya pengulas dapat mengesahkan aliran IAP tanpa caj.
