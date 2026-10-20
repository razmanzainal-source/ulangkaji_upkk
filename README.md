# Ulangkaji UPKK

App ulang kaji **Ujian Penilaian Kelas Al-Quran dan Fardu Ain (UPKK)** untuk
murid Tahun 5 KAFA — luar talian sepenuhnya, dalam Bahasa Melayu dan Jawi,
ditemani maskot **Raz**.

© 2026 Razman Zainal. App ini **percuma** dan tiada iklan.

## Apa yang ada dalam app

App ada **empat tab** di bawah: Percubaan, Kertas, Kemajuan dan Info.

| Tab | Keterangan |
| --- | --- |
| **Percubaan** | Kertas percubaan mengikut format UPKK sebenar untuk enam subjek bertulis. Setiap percubaan dijana semula daripada bank soalan, jadi percubaan berturut-turut berbeza. |
| **Kertas** | Imbasan **kertas sebenar UPKK 2024 dan 2025** — dipaparkan sebagai gambar seperti kertas asal, boleh dizum. |
| **Kemajuan** | Laporan ibu bapa: markah terbaik, bilangan percubaan, gred, rentetan hari belajar dan senarai topik yang perlu diulang. |
| **Info** | Pengenalan, kandungan, sumber, privasi, sumbangan dan kredit. |

## Subjek dan format kertas

Semua kertas UPKK bernilai **70 markah** dan diberi masa **1 jam 15 minit**.
Bilangan soalan dan markah setiap bahagian dalam app mengikut kertas sebenar:

| Subjek | Kod | A | B | C | D | E |
| --- | --- | --- | --- | --- | --- | --- |
| Adab | UPKK04 | 2 soalan / 10 | 10 / 10 | 6 / 30 | 4 / 20 | – |
| Akidah | UPKK02 | 2 / 10 | 10 / 10 | 4 / 30 | 6 / 20 | – |
| Bahasa Arab | UPKK06 | 3 / 10 | 10 / 10 | 5 / 20 | 4 / 30 | – |
| Ibadah | UPKK07 | 3 / 10 | 10 / 10 | 6 / 30 | 4 / 20 | – |
| Jawi dan Khat | UPKK05 | 4 / 10 | 10 / 10 | 3 / 15 | 4 / 25 | 1 / 10 |
| Sirah | UPKK03 | 3 / 10 | 10 / 10 | 4 / 30 | 2 / 20 | – |

Gred mengikut gred rasmi UPKK: **A** 80–100, **B** 60–79, **C** 40–59,
**D** 1–39.

## Soalan ditulis sendiri

Semua soalan dalam app ini **ditulis sendiri** untuk app ini berdasarkan format
dan skop sukatan UPKK. Ia **bukan** soalan bocor dan **bukan** ramalan.

Kertas UPKK tahun lepas yang diimbas dipaparkan di tab **Kertas** sebagai bahan
rujukan murid. Imbasan itu digunakan untuk memahami **gaya, aras kesukaran dan
skop kandungan** sahaja — tiada soalan disalin daripadanya ke dalam bank.

## Jawi dan Rumi

Setiap teks Jawi mempunyai baris Rumi di bawahnya. Dalam **latih tubi**, baris
itu dipaparkan — murid yang belum lancar Jawi tetap boleh membaca soalan, dan
ibu bapa yang belum lancar Jawi tetap boleh menyemak jawapan anak. Dalam
**kertas percubaan**, baris Rumi ditanggalkan supaya paparan menyerupai kertas
UPKK sebenar, yang 100% Jawi.

Fon **Noto Naskh Arabic** dibundelkan bersama app supaya huruf Jawi khas
(چ ݢ ڠ ڤ ۏ ڽ) kelihatan betul pada setiap peranti — sesetengah telefon
memaparkannya sebagai petak kosong.

## Latih tubi dan kertas percubaan

Kedua-duanya menggunakan bank soalan yang sama, tetapi tujuannya berbeza dan
app melayaninya dengan cara yang berbeza:

| | Latih tubi | Kertas percubaan |
| --- | --- | --- |
| Tujuan | belajar dan mencuba | meniru peperiksaan sebenar |
| Rumi | ada | tiada |
| Bantuan suara | soalan **dan** setiap pilihan jawapan | tiada langsung |
| Bunyi betul / salah | ada | tiada |
| Masa | tiada had | 1 jam 15 minit |
| Markah dan gred | tiada | ada (70 markah, gred A–D) |
| Keluar di tengah jalan | terus keluar, tanpa dialog | bertanya dahulu |

Bantuan suara latih tubi **tidak** dipasang pada kertas percubaan dengan
sengaja: kertas sebenar tidak membacakan soalan atau pilihan jawapan kepada
calon, dan bantuan itu akan mengubah markah, bukan menguji pemahaman. Setiap
klip ialah rakaman suara perempuan Bahasa Melayu (`ms-MY-YasminNeural`) atau
Arab (`ar-SA-ZariyahNeural`) yang dijana lebih awal, jadi bunyinya sama pada
setiap telefon — termasuk iPhone yang langsung tiada suara Bahasa Melayu.

## Bagaimana app ini dibina

```
assets/content/subjek.json      senarai subjek, format rasmi, senarai kertas sebenar
assets/content/bank/<id>.json   bank soalan setiap subjek
assets/kertas/<subjek>-<tahun>/ imbasan kertas sebenar
lib/models/                     model data (kertas, soalan, jawapan, gred)
lib/services/                   bank soalan, penjana kertas, pemarkahan, kemajuan
lib/screens/                    skrin app
lib/widgets/                    komponen paparan (Dwibahasa, PapanTaip, Maskot)
tools/                          skrip semakan dan penjanaan (Python)
kerja/                          nota dan potongan bank semasa menulis (tidak dibina)
```

### Penjana kertas

Kertas percubaan **tidak** disimpan sebagai fail. Ia dibina setiap kali murid
mula menjawab, daripada bank soalan subjek itu:

- **Tiada soalan berulang dalam satu kertas.** Soalan yang sudah dipilih
  direkodkan dan tidak boleh dipilih lagi, walaupun bank tidak cukup untuk
  memenuhi format.
- **Jumlah markah mesti tepat.** Soalan dalam bank tidak semuanya bernilai
  markah yang sama, jadi penjana mencari gabungan soalan yang jumlahnya
  menepati markah bahagian — bilangan soalan tetap seperti format rasmi.
- **Setiap percubaan berbeza.** Soalan dipilih sebagai tetingkap bergerak yang
  beralih mengikut bilangan percubaan yang telah dibuat murid, jadi selepas
  beberapa percubaan seluruh bank telah diliputi.

### Peralatan semakan

Soalan Jawi ditulis panjang dan kesilapan paling merosakkan ialah **huruf Latin
yang terselit** dalam medan Jawi (`ممباجa` sepatutnya `ممباچ`) — ia menjadikan
perkataan itu tidak boleh dibaca, tetapi hampir tidak kelihatan pada saiz kecil.

Dua skrip menjaga mutu bank:

```bash
cd ulangkaji_upkk

# Semak bank: huruf bukan Jawi, medan Rumi kosong, markah tidak sepadan,
# kunci jawapan di luar julat, bilangan tempat kosong tidak sama dengan bank
# perkataan, perkataan berulang.
python3 tools/semak_bank.py

# Gabungkan potongan bank (kerja/bank/<subjek>-ab.json dan -cd.json) menjadi
# assets/content/bank/<subjek>.json, buang soalan pendua, dan beri id unik.
python3 tools/gabung_bank.py
```

Ujian penjana kertas mengunci peraturan format — 70 markah, bilangan soalan
rasmi, tiada soalan berulang:

```bash
flutter test
```

## Privasi

App ini **berfungsi sepenuhnya tanpa Internet**. Ia tidak meminta akaun, tidak
menghantar apa-apa ke mana-mana, dan tidak mengumpul sebarang data. Markah dan
rekod percubaan disimpan di dalam telefon sahaja, dan boleh dipadam pada
bila-bila masa dari tab Info.

## Sumbangan

App ini percuma dan tiada iklan. Kalau ia membantu anak atau murid awak,
sumbangan sukarela amat dihargai — bagi kos penyelenggaraan, suara rakaman dan
penambahan soalan baharu. Kod QR sumbangan ada di dalam app pada tab **Info**.

## Maklum balas

Pembetulan ejaan Jawi dan cadangan soalan amat dialu-alukan:
**razman.zainal@gmail.com**
