# Balasan Apple — Guideline 1.3 (Kids Category)

Salin blok di bawah ke **App Store Connect → Resolution Center → Reply**.

---

```
Hello App Review Team,

Thank you for your message. Please find our complete responses below.

1. Does the app include third-party analytics?
No. The app contains no analytics SDKs of any kind. It does not include
Firebase, Google Analytics, Crashlytics, Amplitude, or any similar service.
The only third-party code in the app is open-source Flutter plugins used for
local audio playback (audioplayers, flutter_tts), local key-value storage
(shared_preferences), saving an image to the user's own photo library (gal),
the system share sheet (share_plus), opening a web link in the browser
(url_launcher), PDF rendering (pdf, printing), and Apple StoreKit for the
optional in-app tip purchases (in_app_purchase).

2. Does the app include third-party advertising?
No. The app contains no advertising of any kind and no advertising SDK.
There is therefore no ad network to link to.

3. Will the data be shared with any third parties?
No. The app does not transmit any data off the device. It has no account
system, no backend server, and makes no network requests of its own. The only
external interaction is StoreKit, and only when a parent chooses to make an
optional tip purchase. That transaction is processed entirely by Apple; we
receive no personal data and no payment details.

4. Is the app collecting any user or device data for purposes beyond
third-party analytics or third-party advertising?
No. No user or device data is collected for any purpose.

For full transparency, here is everything the app stores, all of which stays
inside the app's own sandbox on the device via Apple's UserDefaults:
  - an optional display name typed by the user (used only for the greeting),
  - practice scores, badges, streak and daily study records,
  - a single boolean flag recording whether the optional tip was purchased.

This information never leaves the device, is not accessible to us, is not
backed up to any server we control, and is deleted when the app is removed.

The app requests exactly one permission: NSPhotoLibraryAddUsageDescription.
It is used only when the user taps "Save" to add a results card to their own
photo library. The app never reads from the photo library.

Regarding Guideline 1.3: the app is designed for children aged 9-11 and
contains no ads, no tracking, no analytics, no user-generated content, no
chat, no external links in the child-facing area, and no data collection.
The optional tip purchases (RM 5 / RM 10 / RM 20) are the only monetisation.
They are placed in a separate area labelled "Untuk Ibu Bapa & Guru" that is
behind a parental gate (an arithmetic question), and they unlock no content:
every question, paper and audio recording is free for all users.

Please let us know if any further detail is required.

Kind regards,
Razman Zainal
razman.zainal@gmail.com
```

---

## Langkah hantar

1. App Store Connect → app **Ulangkaji UPKK**
2. Klik **Resolution Center** (ikon mesej, kanan atas)
3. Buka mesej Apple itu → **Reply**
4. Tampal teks di atas → **Send**
5. Kembali ke halaman versi → jika ada butang **Resubmit to App Review**, tekan

---

## Nota

- Ini permintaan maklumat **rutin** untuk app kanak-kanak — bukan masalah kod.
- Tiada build baharu diperlukan.
- Selepas kita jawab, semakan akan diteruskan (biasanya 1–2 hari).
