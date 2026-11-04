# Nota Semakan Apple (App Review Notes)

Salin ke medan **App Review Information → Notes** di App Store Connect.

---

## Teks siap-salin

```
PURPOSE
Ulangkaji UPKK is a revision app for Malaysian KAFA pupils in Year 5
(ages 9-11) preparing for the UPKK assessment. It contains practice
questions and digitised past papers for six subjects.

TARGET AUDIENCE
Children aged 9-11 in Malaysia, plus their parents and KAFA teachers.
The app is listed in the Kids Category (Ages 9-11).

MAIN FLOW
1. Launch the app.
2. A name prompt appears (a display name only - no account is created,
   nothing is transmitted). Tap "Langkau" (Skip) to proceed without one.
3. Home screen lists six subjects. Each has two buttons:
   - "Latih tubi"  : 10 practice questions. FREE.
   - "Percubaan"   : full 70-mark exam paper, 75 minutes. PAID (see below).
4. The bottom tabs are: Percubaan, Kertas, Kemajuan, Info.

LOGIN
None. There is no account, no sign-up, no email collection, and no server.

IN-APP PURCHASE (RM 9.90, one-time, non-consumable)
Product ID: ulangkaji_upkk_full
To review the purchase flow:
1. Open the "Info" tab.
2. Tap "Untuk Ibu Bapa & Guru".
3. A parental gate asks a multiplication question (e.g. "Berapakah 17 x 8?").
   Answer correctly to continue.
4. The "Versi Penuh" screen shows the price, the "Beli" button and
   "Pulihkan pembelian" (Restore Purchases).
5. Tapping "Percubaan" (or "Kertas" -> "Jawab") without purchasing opens the
   same parental gate instead of the paid content.

The purchase unlocks the exam mode only. All practice content remains free.

EXTERNAL SERVICES
None. The app works fully offline. No analytics, no advertising, no
third-party SDKs other than open-source Flutter plugins for local audio
playback, local storage and saving an image to the photo library.

DATA
No data is collected or transmitted. The child's display name, scores and
badges are stored locally (SharedPreferences) and removed when the app is
deleted. The privacy policy is at the Support URL.

USER-GENERATED CONTENT
None. There is no chat, no sharing within the app, and no user content
upload. The share sheet only exports a results card chosen by the user.

ADS
None.

THIRD-PARTY CONTENT
All questions in the practice bank were written for this app. The digitised
past papers are used for revision purposes.

SCREEN RECORDING
A screen recording of the app running on a physical device is attached to
this submission. It starts at the device home screen, launches the app, and
shows the full flow including the parental gate and the in-app purchase
screen (without completing a real transaction).
```

---

## Senarai semak sebelum menghantar

| Perkara | Status |
|---|---|
| Produk IAP dicipta & **ditambah ke versi** di App Store Connect | ⬜ |
| Produk IAP berstatus "Ready to Submit" | ⬜ |
| Privacy Policy URL diisi | ⬜ |
| Support URL diisi | ⬜ |
| App Privacy: **Data Not Collected** | ⬜ |
| Age rating: Kids 9–11 | ⬜ |
| Screenshot 6.9" (wajib) + iPad 13" (jika iPad disokong) | ⬜ |
| Rakaman skrin peranti fizikal 60–120 saat | ⬜ |
| Nota semakan di atas disalin | ⬜ |
| Build 2.0.0 (24) dihantar & selesai diproses | ⬜ |
| DSA / trader status (jika EU) | ⬜ |
