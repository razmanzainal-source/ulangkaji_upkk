#!/usr/bin/env python3
"""Jana rakaman suara untuk soalan Ulangkaji UPKK.

Kenapa rakaman dijana lebih awal dan bukan bergantung pada suara telefon:
  * iPhone dan iPad SELALUNYA TIADA suara Bahasa Melayu langsung;
  * pelayar web dan komputer sering membaca teks Melayu dengan pelat Inggeris
    atau Indonesia, jadi sebutannya sukar difahami murid;
  * telefon yang ada suara Melayu pula memilih suara lelaki atau perempuan
    sesuka hati — murid sepatutnya mendengar **satu suara yang sama** pada
    setiap peranti.

Suara yang dipakai (kedua-duanya suara perempuan, melalui edge-tts percuma,
tiada kunci API):

  * `ms-MY-YasminNeural` — subjek Melayu (Adab, Akidah, Ibadah, Jawi, Sirah).
    Teks dibaca daripada medan **Rumi**, bukan Jawi: enjin suara tidak boleh
    membaca tulisan Jawi, dan membaca Jawi dengan suara Melayu menghasilkan
    sebutan yang salah sepenuhnya.
  * `ar-SA-ZariyahNeural` — subjek Bahasa Arab. Teks dibaca daripada medan
    **Arab** (bukan Rumi), kerana suara Arab membaca harakat dengan betul dan
    itulah sebutan yang murid perlu dengar.

Rakaman dijana **sekali sahaja semasa pembinaan**. App sendiri kekal 100% luar
talian dan hanya memainkan fail `.m4a` yang dibundelkan.

Guna:
    python3 tools/jana_suara.py                  # jana semua yang belum ada
    python3 tools/jana_suara.py --subjek adab    # satu subjek sahaja
    python3 tools/jana_suara.py --paksa          # jana semula semua
    python3 tools/jana_suara.py --kerja 6        # bilangan tugasan selari
    python3 tools/jana_suara.py --senarai        # senarai suara Melayu/Arab sahaja

Keperluan: `pip3 install edge-tts`
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor

AKAR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FOLDER_SUBJEK = os.path.join(AKAR, "assets", "content", "subjek.json")
FOLDER_BANK = os.path.join(AKAR, "assets", "content", "bank")
KELUARAN = os.path.join(AKAR, "assets", "bunyi", "suara")
MANIFEST = os.path.join(KELUARAN, "manifest.json")

# Suara perempuan. `SUARA` dan `SUARA_ARAB` boleh ditukar melalui pemboleh ubah
# persekitaran jika mahu mencuba suara lain.
SUARA = os.environ.get("SUARA", "ms-MY-YasminNeural")
SUARA_ARAB = os.environ.get("SUARA_ARAB", "ar-SA-ZariyahNeural")

# Kadar bacaan: sedikit perlahan daripada biasa supaya murid Tahun 5 sempat
# mengikuti. edge-tts menerima bentuk seperti "-10%".
KADAR = os.environ.get("KADAR", "-8%")

# Kadar bit audio. Ini rakaman suara manusia, bukan muzik: 32 kbps mono sudah
# cukup jelas, dan mengekalkannya rendah menjaga saiz app — beribu-beribu klip
# pendek boleh membengkakkan saiz muat turun dengan cepat.
#
# Itu penilaian yang salah pada telinga manusia: pada 32 kbps suara Yasmin
# kedengaran **tipis dan tidak jelas** ("tak clear & tidak penuh") — desir AAC
# amat ketara pada fon kepala, dan ayat panjang seperti maklum balas keputusan
# paling teruk terjejas. Sumber edge-tts sendiri 48 kbps, jadi 48 kbps
# mengekalkan mutu asal tanpa menambah saiz dengan sia-sia: aset suara naik
# daripada ~18 MB kepada ~27 MB, harga yang berbaloi untuk suara yang menjadi
# guru bacaan murid Tahun 5.
BITRATE = os.environ.get("BITRATE", "48000")

CUBAAN = 3  # bilangan percubaan semula jika rangkaian gagal

# Subjek yang dibaca dengan suara Arab dan teks Arab.
SUBJEK_ARAB = {"arab"}

# Ayat tetap yang boleh diminta app melalui `Suara.sebutKunci`.
AYAT_TETAP = {
    "f-salah": "Cuba lagi.",
    # Gesaan menjawab dalam latih tubi — murid menekan "Seterusnya" sebelum
    # menjawab soalan. Latih tubi mewajibkan satu jawapan bagi setiap soalan,
    # jadi butang itu enggan bergerak dan ayat ini menerangkan sebabnya.
    # Sengaja bukan teguran: ayat menyuruh murid mencuba, bukan memberitahu
    # dia telah gagal.
    "f-jawab-dulu": "Jawab dulu sebelum teruskan.",
    # Pujian rentetan dalam **latih tubi** — dipanggil apabila murid mendapat
    # 3, 6, 9… jawapan betul berturut-turut (lihat `_puji`).
    #
    # Sengaja TIDAK dipuji pada setiap jawapan betul: ayat yang sama selepas
    # setiap soalan menjadi bunyi latar selepas sepuluh soalan dan tidak
    # lagi didengar. Dengan rentetan, pujian bermakna — ia tiba apabila murid
    # benar-benar konsisten, dan tiga ayat yang bergilir mengelakkan bunyi
    # daripada berulang.
    "f-rentetan1": "Bagus! Tiga betul berturut-turut.",
    "f-rentetan2": "Hebat! Kamu semakin mahir.",
    "f-rentetan3": "Cemerlang! Teruskan rentetan itu.",
    # Ayat-ayat ini **mesti** bermula dengan perkataan yang dipaparkan besar di
    # kad keputusan (lihat `_pujian` dalam `keputusan_screen.dart`): murid
    # membaca "Jangan putus asa" sambil mendengar ayat yang sama. Ayat yang
    # berbeza daripada paparan kedengaran seperti rakaman yang terpotong.
    "f-sempurna": "Cemerlang! Semua jawapan betul.",
    "f-hebat": "Cemerlang! Markah kamu cemerlang.",
    "f-bagus": "Bagus! Sedikit lagi usaha.",
    "f-boleh": "Boleh lagi! Cuba sekali lagi.",
    "f-ulang": "Jangan putus asa. Mari kita ulang kaji sekali lagi.",
    "f-nama": "Assalamualaikum! Siapa nama kamu?",
    # Sapaan pembuka. Nama murid **tidak** disebut — lihat `Suara.sapaan`.
    "f-selamat": "Assalamualaikum, jom belajar KAFA bersama Raz.",
    # Penutup latih tubi — tiga ayat mengikut peratus jawapan betul
    # (lihat `Suara.latihanSelesai`). Tiada markah disebut: latih tubi bukan
    # kertas. "Syabas" hanya untuk 70% ke atas. Tiada ", ya." di hujung
    # mana-mana ayat app.
    "f-latihan": "Syabas! Latihan selesai. Jom cuba lagi.",
    "f-latihan-sederhana": "Latihan selesai. Teruskan usaha, jom cuba lagi.",
    "f-latihan-ulang": "Latihan selesai. Jangan putus asa, mari ulang kaji sekali lagi.",
}

# Teks mesti mengandungi sekurang-kurangnya satu huruf atau angka.
_ADA_HURUF = __import__("re").compile(r"[0-9A-Za-z\u0600-\u06FF]")

DIBENARKAN = set(".,?!:;'-()/")

# Tanda bacaan Arab yang dibenarkan kekal dalam teks yang dibaca oleh suara
# Arab — koma dan tanda soal Arab.
DIBENARKAN_ARAB = DIBENARKAN | set("،؟")

# Pembetulan sebutan — hanya untuk teks yang **didengari**.
#
# Yasmin ialah suara Melayu asli, jadi ejaan Melayu biasa sudah betul. Senarai
# ini dibiarkan kosong supaya sebarang pembetulan yang perlu didokumenkan di
# sini, sama seperti `Suara._sebutan` dalam app.
SEBUTAN = []


def bersih(teks: str) -> str:
    """Buang emoji, tanda hiasan dan penanda Jawi supaya suara lancar.

    Penanda tempat kosong `____` tidak disebut oleh enjin suara Melayu (atau
    disebut "garis bawah" oleh suara telefon). Ia digantikan dengan "tempat
    kosong". Ini cerminan `Suara.sebutanBetul` dalam app supaya kedua-dua
    laluan (rakaman dan suara peranti) berbunyi sama.
    """
    teks = teks.replace("—", ",").replace("–", ",").replace("→", ",")
    teks = teks.replace("«", "").replace("»", "").replace("ﷺ", "")
    teks = re.sub(r"_{2,}", " tempat kosong ", teks)
    teks = re.sub(r"[✓✗✔✘★☆●○]", " ", teks)
    # Tulisan Jawi/Arab ditinggalkan daripada teks yang dibaca: enjin suara
    # Melayu membacanya sebagai huruf yang bertaburan.
    teks = re.sub(r"[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]+", " ", teks)
    keluar = [c for c in teks if c.isalnum() or c.isspace() or c in DIBENARKAN]
    teks = " ".join("".join(keluar).split())
    return re.sub(r"\s+([.,?!:;])", r"\1", teks).strip()


def _bersih_arab(teks: str) -> str:
    """Bersihkan teks Arab tanpa membuang huruf Arab."""
    teks = teks.replace("«", "").replace("»", "").replace("—", "،")
    keluar = [c for c in teks if c.isalnum() or c.isspace() or c in DIBENARKAN_ARAB]
    return " ".join("".join(keluar).split()).strip()


def sebutan(teks: str) -> str:
    """Betulkan perkataan yang disebut gaya Inggeris oleh enjin suara."""
    for pola, ganti in SEBUTAN:
        teks = pola.sub(
            lambda m: (ganti[:1].upper() + ganti[1:])
            if m.group(0)[:1].isupper()
            else ganti,
            teks,
        )
    return teks


def nama_fail(teks: str, suara: str) -> str:
    """Nama fail yang stabil daripada teks dan suara.

    Dua soalan dengan bunyi yang sama berkongsi satu fail, jadi bank yang
    mengulang ayat tidak menggandakan saiz audio.
    """
    cap = hashlib.sha1(f"{suara}\u0000{teks}".encode("utf-8")).hexdigest()[:16]
    return cap + ".m4a"


def jana_satu(teks: str, laluan: str, suara: str) -> None:
    """Jana satu klip: edge-tts -> mp3, kemudian afconvert -> m4a (AAC mono)."""
    with tempfile.TemporaryDirectory() as td:
        mp3 = os.path.join(td, "a.mp3")
        for cuba in range(CUBAAN):
            try:
                hasil = subprocess.run(
                    [
                        sys.executable, "-m", "edge_tts",
                        "--voice", suara,
                        f"--rate={KADAR}",
                        "--text", teks,
                        "--write-media", mp3,
                    ],
                    capture_output=True,
                    text=True,
                    # Tanpa had masa, satu permintaan rangkaian yang tergantung
                    # menghentikan seluruh penjanaan — dan itulah yang berlaku
                    # pada 2,000/2,130 klip.
                    timeout=90,
                )
            except subprocess.TimeoutExpired:
                if cuba == CUBAAN - 1:
                    raise RuntimeError("edge-tts tamat masa: " + teks[:80])
                time.sleep(2.0 * (cuba + 1))
                continue
            if hasil.returncode == 0 and os.path.exists(mp3) and os.path.getsize(mp3) > 0:
                break
            if cuba == CUBAAN - 1:
                raise RuntimeError(
                    "edge-tts gagal: "
                    + (hasil.stderr.strip()[:200] or hasil.stdout.strip()[:200])
                )
            time.sleep(1.5 * (cuba + 1))

        subprocess.run(
            [
                "afconvert", "-f", "m4af", "-d", "aac", "-b", BITRATE,
                "-c", "1", mp3, laluan,
            ],
            check=True,
            capture_output=True,
        )


def _baca(teks: str | None, rujuk_arab: bool) -> str:
    """Teks yang benar-benar disebut bagi satu teks yang dipaparkan.

    Subjek Bahasa Arab dibaca daripada tulisan Arab; subjek lain dibaca
    daripada baris Rumi, kerana enjin suara Melayu tidak boleh membaca Jawi.
    """
    if rujuk_arab:
        return _bersih_arab(teks or "")
    return bersih(teks or "")


def _teks(s: dict, rujuk_arab: bool) -> list[tuple[str, str]]:
    """Senarai (kunci, teks) bagi satu soalan.

    Bentuk kunci mesti sepadan dengan fungsi `Suara.kunci*` dalam
    `lib/services/suara.dart` — kalau tidak, klip yang dijana tidak akan
    dijumpai oleh app.

    Dua kumpulan klip dijana:

      * `q-<id>` — teks soalan itu sendiri (butang speaker di sebelah soalan);
      * `o-<teks>` — setiap teks yang murid perlu **baca dan pilih**: pilihan
        A/B/C/D, ayat kecil di bawah soalan berbilang item, item padanan, kad
        susun, perkataan bank, pernyataan betul/salah dan ayat tempat kosong.

    Klip `o-` dikunci mengikut **teks**, bukan mengikut nombor soalan. Teks
    yang berulang dalam beberapa soalan berkongsi satu rakaman, dan itulah
    sebabnya bantuan suara latih tubi hanya menambah kira-kira 17 MB walaupun
    bank mengandungi lebih 2,000 pilihan.
    """
    sid = s["id"]
    keluar: list[tuple[str, str]] = []

    utama = _baca(
        s.get("soalan") if rujuk_arab else s.get("rumi"), rujuk_arab
    )
    if utama:
        keluar.append((f"q-{sid}", utama))

    def tambah(teks: str | None) -> None:
        """Tambah satu klip `o-` bagi teks yang dipaparkan.

        Kunci dibina daripada teks **mentah** (yang app pegang), manakala klip
        dibaca daripada teks yang sudah dibersihkan. Dua teks berbeza yang
        berbunyi sama tetap berkongsi satu fail (lihat `nama_fail`), tetapi
        kuncinya kekal berasingan supaya carian app tidak pernah terlepas.
        """
        mentah = (teks or "").strip()
        bunyi = _baca(teks, rujuk_arab)
        # Teks yang hanya mengandungi tanda baca (contohnya "!") tidak boleh
        # disebut. edge-tts menolaknya, dan kunci tanpa fail akan tergantung
        # dalam manifest.
        if not _ADA_HURUF.search(bunyi):
            return
        if mentah and bunyi:
            keluar.append((f"o-{mentah}", bunyi))

    for it in s.get("item") or []:
        # Ayat kecil di bawah soalan berbilang item (contoh: bulat, tempat
        # kosong, betul/salah). Soalan satu item biasanya sudah mempunyai ayat
        # itu pada `soalan`, jadi teks kosong dilangkau.
        tambah(it.get("teks") if rujuk_arab else it.get("rumi"))
        for p in it.get("pilihan") or []:
            if isinstance(p, dict):
                tambah(p.get("teks") if rujuk_arab else p.get("rumi"))
            else:
                tambah(str(p))

    for p in s.get("pasangan") or []:
        tambah(p.get("kiri") if rujuk_arab else p.get("kiriRumi"))
        tambah(p.get("kanan") if rujuk_arab else p.get("kananRumi"))

    for u in s.get("urutan") or []:
        tambah(u if isinstance(u, str) else u.get("teks"))

    for i, k in enumerate(s.get("bank") or []):
        if rujuk_arab:
            tambah(k)
        else:
            rumi = (s.get("bankRumi") or [])
            tambah(rumi[i] if i < len(rumi) else None)

    # Pembetulan jawapan bagi soalan **bertulis** sahaja.
    #
    # Panel "Pembetulan — jawapan sebenar" memaparkan jawapan contoh panjang
    # yang murid sepatutnya tulis. Soalan lain tidak memerlukan klip di sini
    # kerana jawapan betulnya masih terpapar di skrin dengan butang speaker
    # sendiri — menjana klip untuknya hanya mengulang bunyi yang sedia ada
    # dalam ratusan variasi teks yang hampir serupa.
    if s.get("jenis") in ("tulis", "huraian"):
        if rujuk_arab:
            contoh = s.get("jawapanContoh") or []
        else:
            contoh = s.get("jawapanContohRumi") or s.get("jawapanContoh") or []
        # Teks mesti sepadan **tepi demi tepi** dengan `jawapanPenuhDengar`
        # dalam app, kerana kunci diperoleh daripada teks mentah itu sendiri.
        # Dart menyertai `join('\n')` tanpa menapis baris kosong, jadi Python
        # turut berbuat demikian — menapis di sini akan menghasilkan kunci
        # yang tidak dapat dijumpai oleh app.
        tambah("\n".join(contoh).strip())

    return [(k, v) for k, v in keluar if v]


def kumpul_kerja(penapis: set[str] | None = None) -> list[tuple[str, str, str]]:
    """Bina senarai (kunci, teks, suara) untuk setiap ayat yang perlu disebut."""
    with open(FOLDER_SUBJEK, encoding="utf-8") as f:
        subjek = json.load(f)["subjek"]

    kerja: list[tuple[str, str, str]] = []
    for kunci, teks in AYAT_TETAP.items():
        kerja.append((kunci, teks, SUARA))

    for s in subjek:
        sid_subjek = s["id"]
        if penapis and sid_subjek not in penapis:
            continue
        laluan = os.path.join(FOLDER_BANK, f"{sid_subjek}.json")
        if not os.path.exists(laluan):
            print(f"  (bank {sid_subjek} tiada — dilangkau)")
            continue

        with open(laluan, encoding="utf-8") as f:
            bank = json.load(f)

        rujuk_arab = sid_subjek in SUBJEK_ARAB
        suara = SUARA_ARAB if rujuk_arab else SUARA

        for soalan in bank.get("soalan") or []:
            for kunci, teks in _teks(soalan, rujuk_arab):
                kerja.append((kunci, teks, suara))

    # Pembetulan sebutan dijalankan di sini supaya nama fail audio sentiasa
    # sepadan dengan teks yang benar-benar disebut.
    return [(k, sebutan(t), v) for k, t, v in kerja]


def senarai_suara() -> None:
    hasil = subprocess.run(
        [sys.executable, "-m", "edge_tts", "--list-voices"],
        capture_output=True, text=True,
    )
    for baris in hasil.stdout.splitlines():
        if "ms-MY" in baris or "ar-SA" in baris:
            print(baris)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--paksa", action="store_true", help="jana semula fail yang sudah ada")
    parser.add_argument("--kerja", type=int, default=4, help="bilangan tugasan selari")
    parser.add_argument("--subjek", nargs="*", help="hadkan kepada subjek ini sahaja")
    parser.add_argument("--senarai", action="store_true", help="senarai suara Melayu/Arab edge-tts")
    args = parser.parse_args()

    if args.senarai:
        senarai_suara()
        return 0

    os.makedirs(KELUARAN, exist_ok=True)

    penapis = set(args.subjek) if args.subjek else None
    kerja = kumpul_kerja(penapis)

    # Satu teks (dengan suara yang sama) = satu fail.
    ikut_teks: dict[tuple[str, str], list[str]] = {}
    for kunci, teks, suara in kerja:
        ikut_teks.setdefault((teks, suara), []).append(kunci)

    unik = sorted(ikut_teks.items(), key=lambda p: p[0][0])
    perlu = []
    for (teks, suara), _kunci in unik:
        laluan = os.path.join(KELUARAN, nama_fail(teks, suara))
        if args.paksa or not os.path.exists(laluan):
            perlu.append((teks, laluan, suara))

    print(f"Suara Melayu    : {SUARA} ({KADAR})")
    print(f"Suara Arab      : {SUARA_ARAB}")
    print(f"Jumlah ayat unik: {len(unik)}")
    print(f"Perlu dijana    : {len(perlu)}")

    gagal: list[tuple[str, str]] = []
    if perlu:
        with ThreadPoolExecutor(max_workers=args.kerja) as kolam:
            futures = {
                kolam.submit(jana_satu, teks, laluan, suara): teks
                for teks, laluan, suara in perlu
            }
            siap = 0
            for fut in futures:
                siap += 1
                try:
                    fut.result()
                except Exception as e:  # noqa: BLE001
                    gagal.append((futures[fut][:60], str(e)[:200]))
                if siap % 25 == 0 or siap == len(perlu):
                    print(f"  {siap}/{len(perlu)}", flush=True)

    # Manifest: kunci app -> nama fail. Manifest lama dibaca dahulu supaya
    # menjana satu subjek sahaja (--subjek) tidak memadam klip subjek lain.
    peta: dict[str, str] = {}
    if os.path.exists(MANIFEST):
        try:
            with open(MANIFEST, encoding="utf-8") as f:
                lama = json.load(f)
            peta.update(lama.get("fail") or {})
        except Exception:  # noqa: BLE001
            pass

    for (teks, suara), kunci in unik:
        fail = nama_fail(teks, suara)
        for k in kunci:
            peta[k] = fail

    # Buang kunci yang failnya tidak wujud — teks tanda baca yang ditolak
    # edge-tts, atau teks yang sudah dibetulkan ejaannya.
    peta = {
        k: v
        for k, v in peta.items()
        if os.path.exists(os.path.join(KELUARAN, v))
    }

    with open(MANIFEST, "w", encoding="utf-8") as f:
        json.dump(
            {
                "versi": 3,
                "suara": SUARA,
                "suaraArab": SUARA_ARAB,
                "kadar": KADAR,
                "bilangan": len(peta),
                "fail": peta,
            },
            f,
            ensure_ascii=False,
            indent=1,
        )

    # Buang fail audio yang tidak lagi dirujuk oleh manifest — contohnya selepas
    # teks soalan dibetulkan. Menjaga saiz app.
    digunakan = set(peta.values())
    lapuk = [
        f for f in os.listdir(KELUARAN)
        if f.endswith(".m4a") and f not in digunakan
    ]
    for f in lapuk:
        os.remove(os.path.join(KELUARAN, f))
    if lapuk:
        print(f"Buang {len(lapuk)} fail lapuk")

    saiz = sum(
        os.path.getsize(os.path.join(KELUARAN, f))
        for f in os.listdir(KELUARAN)
        if f.endswith(".m4a")
    )
    bilangan_fail = len([f for f in os.listdir(KELUARAN) if f.endswith(".m4a")])
    print(f"\nSiap. {bilangan_fail} fail audio, {saiz / 1048576:.1f} MB")
    print(f"Manifest: {os.path.relpath(MANIFEST, AKAR)}")

    if gagal:
        print(f"\n{len(gagal)} ayat gagal:")
        for teks, ralat in gagal[:10]:
            print(f"  - {teks}: {ralat}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
