# Data Safety (Google) & App Privacy (Apple)

Jawapan di bawah adalah berdasarkan **kod sebenar** app 2.0.0 (24), bukan andaian.

---

## Bukti daripada kod

| Perkara | Bukti |
|---|---|
| Tiada Internet | `android/app/src/main/AndroidManifest.xml` **tiada** `INTERNET` permission |
| Tiada analytics/iklan | `pubspec.yaml` tiada SDK analytics, iklan atau crash reporting |
| Storan setempat | `shared_preferences` sahaja (nama, markah, lencana, status pembelian) |
| Foto | `gal` — hanya apabila pengguna menekan **Simpan** |
| Kongsi | `share_plus` — sheet sistem, pengguna pilih penerima |
| Pembelian | `in_app_purchase` — diproses Apple/Google; app tidak menerima butiran pembayaran |
| Suara | `flutter_tts` + `audioplayers` — enjin sistem, fail bunyi dalam bundle |

---

## Apple — App Privacy

**Jawapan: “Data Not Collected”** untuk semua kategori.

| Kategori | Jawapan |
|---|---|
| Contact Info | Not collected |
| Health & Fitness | Not collected |
| Financial Info | Not collected |
| Location | Not collected |
| Sensitive Info | Not collected |
| Contacts | Not collected |
| User Content | Not collected |
| Browsing History | Not collected |
| Search History | Not collected |
| Identifiers | Not collected |
| Purchases | Not collected |
| Usage Data | Not collected |
| Diagnostics | Not collected |

- **Tracking:** No
- **Third-party advertising:** No
- **Analytics:** No

> Nota: pembelian IAP diproses oleh Apple. App hanya menyimpan satu boolean
> “sudah dibeli” di dalam peranti; ia bukan data yang dikumpul oleh pembangun.

---

## Google — Data Safety

**Data collected:** None
**Data shared:** None
**Data encrypted in transit:** Not applicable (no data leaves the device)
**Users can request deletion:** Not applicable — no server data

Jawapan borang:

| Soalan | Jawapan |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | Not applicable |
| Do you provide a way for users to request that their data is deleted? | Not applicable (data stored only on device; removing the app deletes it) |
| Does your app use cookies? | No |
| Ads | **No ads** |
| Target audience | **9–11** (children) |
| Families policy | Compliant: no ads, no analytics, no personal data, parental gate for purchases |

### Kebenaran yang diisytiharkan

| Kebenaran | Sebab | Boleh dikeluarkan? |
|---|---|---|
| `WRITE_EXTERNAL_STORAGE` (`maxSdkVersion=29`) | Simpan kad keputusan ke galeri pada Android 9 ke bawah | Tidak — diperlukan oleh `gal` pada API ≤29 |
| `INTERNET`, `ACCESS_NETWORK_STATE` | **Hanya** untuk perpustakaan Google Play Billing yang memproses tip | Tidak — dimasukkan oleh `in_app_purchase` |
| `com.android.vending.BILLING` | Pembelian dalam app (tip) | Tidak |

Tiada kebenaran lain diminta (tiada kamera, mikrofon, lokasi, kenalan,
notifikasi, akses fail penuh, atau **AD_ID**).

> Aplikasi tidak menghantar sebarang data. Kebenaran rangkaian hanya
> digunakan oleh perpustakaan pembayaran untuk berkomunikasi dengan Play
> Store, bukan oleh kod aplikasi.

---

## Pengesahan

```
flutter analyze ......... 0 isu
flutter test ............ 314 lulus
Manifest INTERNET ....... tiada
AD_ID ................... tiada
```
