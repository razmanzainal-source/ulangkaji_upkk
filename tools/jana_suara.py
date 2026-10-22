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
import wave
from concurrent.futures import ThreadPoolExecutor

AKAR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FOLDER_SUBJEK = os.path.join(AKAR, "assets", "content", "subjek.json")
FOLDER_BANK = os.path.join(AKAR, "assets", "content", "bank")
FOLDER_SEBENAR = os.path.join(AKAR, "assets", "content", "sebenar")
KELUARAN = os.path.join(AKAR, "assets", "bunyi", "suara")
MANIFEST = os.path.join(KELUARAN, "manifest.json")

# Suara perempuan. `SUARA` dan `SUARA_ARAB` boleh ditukar melalui pemboleh ubah
# persekitaran jika mahu mencuba suara lain.
SUARA = os.environ.get("SUARA", "ms-MY-YasminNeural")
SUARA_ARAB = os.environ.get("SUARA_ARAB", "ar-SA-ZariyahNeural")

# Kadar bacaan: sedikit perlahan daripada biasa supaya murid Tahun 5 sempat
# mengikuti. edge-tts menerima bentuk seperti "-10%".
# Kadar dan pitch suara Melayu.
#
# Tiada suara kanak-kanak dalam edge-tts bagi Bahasa Melayu (hanya Yasmin
# perempuan dan Osman lelaki). Untuk mendapatkan bunyi kanak-kanak perempuan
# yang ceria, suara Yasmin dinaikkan pitch-nya dan sedikit dipercepat — pitch
# yang lebih tinggi kedengaran muda, dan kadar yang sedikit laju kedengaran
# ceria berbanding tempo perlahan yang dibaca oleh orang dewasa.
KADAR = os.environ.get("KADAR", "+4%")
PITCH = os.environ.get("PITCH", "+24Hz")

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

# Penanda bagi klip yang disintesis daripada beberapa segmen berlainan suara.
# Ini bukan suara sebenar: ia memberitahu `jana_satu` bahawa `teks` mengandungi
# kod segmen (lihat `gabung_segmen`), bukan ayat yang perlu disebut terus.
#
# Klip sebegini perlu menjadi **satu fail** kerana app hanya mengenal kunci
# seperti `q-<id>` — tiada mekanisme memainkan beberapa fail berurutan. Dengan
# menyambung segmen menjadi satu fail, senarai kunci dan manifest kekal tepat
# seperti biasa dan tiada perubahan langsung pada app.
SUARA_CAMPURAN = "campuran"

# Awalan mod `audio`, ditulis berserta penanda: `"pisah" + <penanda>`.
# Contoh `"pisah:"` bermaksud bahagikan pada titik dua, dan `"pisah—"`
# bahagikan pada em dash. Awalan sengaja tanpa tanda dua sendiri supaya
# penanda `:` tidak bertindih dengan penanda mod.
PISAH = "pisah"

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
    # Sapaan pembuka. Nama murid **disebut** di tengah sapaan, jadi sapaan
    # dipecahkan kepada dua rakaman dan nama di muchísimo diletakkan di
    # antara (lihat `Suara.sebutSalam`).
    "f-selamat": "Assalamualaikum, jom ulangkaji KAFA bersama Raz.",
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
    cap = hashlib.sha1(
        f"{suara}\u0000{KADAR}\u0000{PITCH}\u0000{teks}".encode("utf-8")
    ).hexdigest()[:16]
    return cap + ".m4a"


def _edge_tts(teks: str, mp3: str, suara: str) -> None:
    """Rakam satu segmen dengan edge-tts menjadi fail mp3 sementara."""
    for cuba in range(CUBAAN):
        try:
            hasil = subprocess.run(
                [
                    sys.executable, "-m", "edge_tts",
                    "--voice", suara,
                    f"--rate={KADAR}",
                    f"--pitch={PITCH}",
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
            return
        if cuba == CUBAAN - 1:
            raise RuntimeError(
                "edge-tts gagal: "
                + (hasil.stderr.strip()[:200] or hasil.stdout.strip()[:200])
            )
        time.sleep(1.5 * (cuba + 1))


def _ke_m4a(sumber: str, laluan: str) -> None:
    """Tukar audio kepada AAC mono 48 kbps (format yang app gunakan)."""
    subprocess.run(
        [
            "afconvert", "-f", "m4af", "-d", "aac", "-b", BITRATE,
            "-c", "1", sumber, laluan,
        ],
        check=True,
        capture_output=True,
    )


def gabung_segmen(segmen: list[tuple[str, str]]) -> str:
    """Kodkan senarai (suara, teks) menjadi satu kerja tunggal.

    Digunakan apabila satu klip perlu bertutur dalam dua bahasa: contohnya
    arahan Bahasa Arab (`ar-SA-ZariyahNeural`) diikuti senarai perkataan Jawi
    yang ialah bahasa Melayu (`ms-MY-YasminNeural`). Membaca keseluruhan ayat
    dengan satu suara akan menyebut perkataan Jawi dengan sebutan Arab.
    """
    return json.dumps([[v, t] for v, t in segmen], ensure_ascii=False)


def baca_segmen(kod: str) -> list[tuple[str, str]]:
    """Songsang `gabung_segmen`."""
    return [(v, t) for v, t in json.loads(kod)]


def jana_segmen(segmen: list[tuple[str, str]], laluan: str) -> None:
    """Sintesis setiap segmen dengan suaranya sendiri, kemudian sambung.

    Tiada `ffmpeg` dalam persekitaran ini, jadi penyambungan dibuat melalui
    WAV PCM: setiap segmen ditukar kepada WAV mono 16-bit 44.1 kHz (format
    seragam, jadi bingkai boleh disalin terus), dan bingkai digabungkan
    berturut-turut sebelum ditukar kepada m4a seperti klip biasa.
    """
    with tempfile.TemporaryDirectory() as td:
        jalur: list[str] = []
        for i, (suara, teks) in enumerate(segmen):
            mp3 = os.path.join(td, f"seg{i}.mp3")
            wav = os.path.join(td, f"seg{i}.wav")
            _edge_tts(teks, mp3, suara)
            subprocess.run(
                # Sintaks `afconvert` untuk PCM ialah `[-][BE|LE]{F|I|UI}{bit}`
                # — `LEI16` (little-endian, integer bertanda, 16-bit). Nama
                # ringkas `leas16` hanya sah untuk codec, bukan PCM.
                ["afconvert", "-f", "WAVE", "-d", "LEI16@44100", "-c", "1", mp3, wav],
                check=True,
                capture_output=True,
            )
            jalur.append(wav)

        sambung = os.path.join(td, "sambung.wav")
        params: tuple[int, int, int] | None = None
        with wave.open(sambung, "wb") as luar:
            for w in jalur:
                with wave.open(w, "rb") as dalam:
                    p = dalam.getparams()
                    if params is None:
                        params = (p.nchannels, p.sampwidth, p.framerate)
                        luar.setnchannels(p.nchannels)
                        luar.setsampwidth(p.sampwidth)
                        luar.setframerate(p.framerate)
                    # Rehat pendek antara bahagian supaya arahan Arab dan
                    # senarai Melayu tidak bertindih antara satu sama lain.
                    senyap = b"\x00" * (p.framerate // 8) * p.sampwidth * p.nchannels
                    luar.writeframes(senyap)
                    luar.writeframes(dalam.readframes(dalam.getnframes()))

        _ke_m4a(sambung, laluan)


def jana_satu(teks: str, laluan: str, suara: str) -> None:
    """Jana satu klip: edge-tts -> mp3, kemudian afconvert -> m4a (AAC mono)."""
    if suara == SUARA_CAMPURAN:
        jana_segmen(baca_segmen(teks), laluan)
        return
    with tempfile.TemporaryDirectory() as td:
        mp3 = os.path.join(td, "a.mp3")
        _edge_tts(teks, mp3, suara)
        _ke_m4a(mp3, laluan)


def _baca(teks: str | None, rujuk_arab: bool) -> str:
    """Teks yang benar-benar disebut bagi satu teks yang dipaparkan.

    Subjek Bahasa Arab dibaca daripada tulisan Arab; subjek lain dibaca
    daripada baris Rumi, kerana enjin suara Melayu tidak boleh membaca Jawi.
    """
    if rujuk_arab:
        return _bersih_arab(teks or "")
    return bersih(teks or "")


def _teks_pilihan(pilihan) -> list[str]:
    """Senarai teks pilihan — boleh jadi rentetan atau objek {teks, rumi}."""
    keluar = []
    for x in pilihan or []:
        if isinstance(x, dict):
            keluar.append(x.get("teks", ""))
        else:
            keluar.append(str(x))
    return keluar


JENIS_BERBILANG = {"kumpulan", "suai", "betul_salah"}


def nombor_baris(s: dict, baris: list[str], gaya: str) -> str:
    """Cermin `_nomborkanBaris` dalam Dart.

    Paparan: `1. jawapan`. Suara: `Soalan 1, jawapan` — supaya nombor
    kedengaran dengan jelas sebelum jawapan dibaca.
    """
    jenis = s.get("jenis")
    if jenis not in JENIS_BERBILANG:
        return "\n".join(baris)
    n = len(s.get("pasangan") or []) if jenis == "suai" else len(s.get("item") or [])
    if n < 2 or len(baris) < 2:
        return "\n".join(baris)
    if gaya == "papar":
        return "\n".join(f"{i + 1}. {b}" for i, b in enumerate(baris))
    return "\n".join(f"Soalan {i + 1}, {b}" for i, b in enumerate(baris))


def jawapan_penuh_teks(s: dict) -> str:
    """Cermin `SoalanKertas.jawapanPenuhTeks` dalam Dart (tulisan asal)."""
    jc = s.get("jawapanContoh") or []
    if jc:
        return "\n".join(jc)
    jenis = s.get("jenis")
    if jenis in ("bulat", "objektif"):
        keluar = []
        for it in s.get("item") or []:
            pil = _teks_pilihan(it.get("pilihan"))
            jaw = it.get("jawapan", -1)
            if isinstance(jaw, int) and 0 <= jaw < len(pil):
                keluar.append(pil[jaw])
        return ", ".join(keluar)
    if jenis == "betul_salah":
        keluar = []
        for it in s.get("item") or []:
            tanda = "\u2713" if it.get("betul") is True else "\u2717"
            keluar.append(f"{it.get('teks', '')} ({tanda})")
        return "\n".join(keluar)
    if jenis == "suai":
        return "\n".join(
            f"{p.get('kiri', '')} \u2014 {p.get('kanan', '')}"
            for p in s.get("pasangan") or []
        )
    if jenis == "susun":
        return " ".join(s.get("urutan") or [])
    if jenis == "tempat_kosong":
        return ", ".join(s.get("bank") or [])
    if jenis == "kumpulan":
        kategori = s.get("kategori") or []
        keluar = []
        for it in s.get("item") or []:
            jaw = it.get("jawapan", -1)
            if isinstance(jaw, int) and 0 <= jaw < len(kategori):
                keluar.append(f"{it.get('teks', '')} \u2014 {kategori[jaw]}")
            else:
                keluar.append(it.get("teks", ""))
        return "\n".join(keluar)
    return ""


def jawapan_dengar_segmen(s: dict, rujuk_arab: bool) -> list[list[str]]:
    """Cermin `SoalanKertas.jawapanDengarSegmen` dalam Dart.

    Setiap baris jawapan ialah senarai segmen: **nombor item dahulu**,
    kemudian jawapannya. Nombor dan jawapan adalah klip berasingan supaya
    nombor yang sama dikongsi semua soalan — saiz app tidak melonjak.

    Teks jawapan sendiri kebetulan sudah ada sebagai klip `o-` (medan item,
    pasangan, pilihan, bank), jadi hanya nombor dan kategori yang baharu.
    """
    keluar: list[list[str]] = []
    awalan = "رقم" if rujuk_arab else "Nombor"

    def pelayan(arab: list[str], rumi: list[str]) -> str | None:
        if rujuk_arab:
            return "\n".join(arab) if arab else None
        return "\n".join(rumi) if rumi else None

    jenis = s.get("jenis")
    if jenis in ("bulat", "objektif"):
        for it in s.get("item") or []:
            pil = _teks_pilihan(it.get("pilihan") if rujuk_arab else it.get("pilihanRumi"))
            jaw = it.get("jawapan", -1)
            if isinstance(jaw, int) and 0 <= jaw < len(pil):
                keluar.append([pil[jaw]])
    elif jenis == "kumpulan":
        kategori = s.get("kategori") if rujuk_arab else s.get("kategoriRumi")
        kategori = kategori or []
        for it in s.get("item") or []:
            jaw = it.get("jawapan", -1)
            asal = it.get("teks", "") if rujuk_arab else it.get("rumi", "")
            if isinstance(jaw, int) and 0 <= jaw < len(kategori):
                keluar.append([asal, kategori[jaw]])
            else:
                keluar.append([asal])
    elif jenis == "suai":
        for pr in s.get("pasangan") or []:
            if rujuk_arab:
                keluar.append([pr.get("kiri", ""), pr.get("kanan", "")])
            else:
                keluar.append([pr.get("kiriRumi", ""), pr.get("kananRumi", "")])
    elif jenis == "betul_salah":
        for it in s.get("item") or []:
            asal = it.get("teks", "") if rujuk_arab else it.get("rumi", "")
            # Tanda ✓/✗ tidak boleh disebut — ayat diikuti "Betul"/"Salah".
            keluar.append([asal, "Betul" if it.get("betul") is True else "Salah"])
    elif jenis == "tempat_kosong":
        # Ayat dibaca dahulu, kemudian jawapan bagi tempat kosong itu.
        bank_rumi = s.get("bankRumi") or []
        n = 0
        for it in s.get("item") or []:
            ayat = it.get("teks", "") if rujuk_arab else it.get("rumi", "")
            for _ in range(str(ayat).count("____")):
                jawapan = bank_rumi[n] if n < len(bank_rumi) else ""
                n += 1
                if not str(jawapan).strip():
                    continue
                keluar.append([str(ayat), jawapan])
    elif jenis == "susun":
        satu = pelayan(s.get("bank") or [], s.get("bankRumi") or [])
        if satu is not None:
            keluar.append([satu])
    elif jenis in ("tulis", "huraian"):
        isi = s.get("idea") or []
        if isi:
            keluar.extend([[i.get("maksud", "")] for i in isi])
        else:
            senarai = pelayan(s.get("jawapanContoh") or [], s.get("jawapanContohRumi") or [])
            if senarai is not None:
                keluar.extend([[b] for b in senarai.split("\n") if b.strip()])
    elif jenis == "senarai":
        senarai = pelayan(s.get("jawapanContoh") or [], s.get("jawapanContohRumi") or [])
        if senarai is not None:
            keluar.extend([[b] for b in senarai.split("\n") if b.strip()])

    keluar = [[seg for seg in baris if seg.strip()] for baris in keluar]
    keluar = [baris for baris in keluar if baris]
    if not keluar:
        return keluar

    # Nombor hanya perlu dibaca apabila soalan memang berbilang item.
    n_item = len(s.get("pasangan") or []) if jenis == "suai" else len(s.get("item") or [])
    perlu_nombor = jenis in ("kumpulan", "suai", "betul_salah", "senarai", "tulis", "huraian") or (
        jenis in ("bulat", "objektif") and n_item > 1
    )
    if not perlu_nombor:
        return keluar
    return [[f"{awalan} {i + 1}"] + baris for i, baris in enumerate(keluar)]


def _teks(s: dict, rujuk_arab: bool) -> list[tuple[str, str, str]]:
    """Senarai (kunci, teks yang disebut, suara) bagi satu soalan.

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

    Medan pilihan ``audio`` pada soalan menukar suara bagi klip tertentu.
    Tiga mod wujud:

      * ``"melayu"`` — baca daripada baris Rumi dengan suara Melayu. Digunakan
        apabila jawapan contoh ialah ayat **Melayu** yang ditulis dalam huruf
        Jawi; enjin suara Arab akan menyebutnya dengan sebutan Arab yang salah.
      * ``"pisah<delim>"`` — bahagikan teks Arab dan baris Rumi pada
        ``<delim>``: bahagian sebelumnya dibaca suara subjek (Arab), bahagian
        selepasnya suara Melayu. Digunakan bagi ayat seperti
        ``اكتب بالعربية: رومه، سکوله`` di mana arahan ialah Arab tulen tetapi
        senarai selepas titik dua ialah perkataan Melayu dalam tulisan Jawi.
      * tiada — tingkah laku asal, satu suara subjek bagi keseluruhan teks.

    Walaupun bunyinya dua suara, klip kekal menjadi **satu kunci dan satu
    fail** (lihat `gabung_segmen`) kerana app meminta satu kunci sahaja bagi
    setiap soalan.
    """
    sid = s["id"]
    suara_subjek = SUARA_ARAB if rujuk_arab else SUARA
    audio = s.get("audio") or {}
    keluar: list[tuple[str, str, str]] = []

    # --- ayat soalan --------------------------------------------------
    utama: str | None = None
    utama_suara = suara_subjek
    mod_soalan = audio.get("soalan")

    if mod_soalan == "melayu":
        utama = sebutan(bersih(s.get("rumi") or ""))
        utama_suara = SUARA
    elif mod_soalan and mod_soalan.startswith(PISAH):
        dl = mod_soalan[len(PISAH):]
        ar = s.get("soalan") or ""
        rm = s.get("rumi") or ""
        if dl not in ar or dl not in rm:
            raise ValueError(f"{sid}: audio.soalan={mod_soalan!r} tidak sepadan")
        seg = [
            (suara_subjek, sebutan(_bersih_arab(ar.split(dl, 1)[0]))),
            (SUARA, sebutan(bersih(rm.split(dl, 1)[1]))),
        ]
        seg = [(v, t) for v, t in seg if t]
        if seg:
            keluar.append((f"q-{sid}", gabung_segmen(seg), SUARA_CAMPURAN))
    elif mod_soalan:
        raise ValueError(f"{sid}: mod audio.soalan tidak dikenali {mod_soalan!r}")
    else:
        utama = _baca(
            s.get("soalan") if rujuk_arab else s.get("rumi"), rujuk_arab
        )

    if utama:
        keluar.append((f"q-{sid}", utama, utama_suara))

    def tambah(
        teks: str | None,
        *,
        bunyi: str | None = None,
        suara: str | None = None,
    ) -> None:
        """Tambah satu klip `o-` bagi teks yang dipaparkan.

        Kunci dibina daripada teks **mentah** (yang app pegang), manakala klip
        dibaca daripada teks yang sudah dibersihkan. Dua teks berbeza yang
        berbunyi sama tetap berkongsi satu fail (lihat `nama_fail`), tetapi
        kuncinya kekal berasingan supaya carian app tidak pernah terlepas.

        ``bunyi`` dan ``suara`` boleh dihantar sendiri apabila bacaan bukan
        datang daripada teks yang sama dengan kunci — itulah kes jawapan
        contoh Melayu-dalam-Jawi dan ayat bercampur suara.
        """
        mentah = (teks or "").strip()
        bunyi_teks = bunyi if bunyi is not None else _baca(teks, rujuk_arab)
        suara_teks = suara if suara is not None else suara_subjek
        # Teks yang hanya mengandungi tanda baca (contohnya "!") tidak boleh
        # disebut. edge-tts menolaknya, dan kunci tanpa fail akan tergantung
        # dalam manifest.
        if not _ADA_HURUF.search(bunyi_teks or ""):
            return
        if mentah and bunyi_teks:
            keluar.append((f"o-{mentah}", bunyi_teks, suara_teks))

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
        # Kunci mesti sepadan **tepi demi tepi** dengan `jawapanPenuhDengar`
        # dalam app. Dart menyertai `join('\n')` tanpa menapis baris kosong,
        # jadi Python turut berbuat demikian — menapis di sini akan
        # menghasilkan kunci yang tidak dapat dijumpai oleh app.
        #
        # Subjek Arab: `jawapanPenuhDengar` memulangkan teks mentah
        # `jawapanContoh`. Subjek lain: baris Rumi.
        kunci_teks = "\n".join(
            (s.get("jawapanContoh") or [])
            if rujuk_arab
            else (s.get("jawapanContohRumi") or s.get("jawapanContoh") or [])
        ).strip()

        if not kunci_teks:
            pass
        elif audio.get("jawapanContoh") == "melayu":
            # Jawapan contoh ini ayat **Melayu** sepenuhnya yang ditulis dalam
            # huruf Jawi (bukan jawapan Bahasa Arab), jadi dibaca terus daripada
            # baris Rumi dengan suara Melayu.
            jawi_mentah = "\n".join(s.get("jawapanContoh") or []).strip()
            rumi = "\n".join(s.get("jawapanContohRumi") or []).strip()
            if not rumi:
                raise ValueError(f"{sid}: mod melayu tanpa jawapanContohRumi")
            tambah(jawi_mentah, bunyi=sebutan(bersih(rumi)), suara=SUARA)
        elif audio.get("jawapanContoh", "").startswith(PISAH):
            mod = audio["jawapanContoh"]
            dl = mod[len(PISAH):]
            jawi_mentah = "\n".join(s.get("jawapanContoh") or []).strip()
            ar = s.get("jawapanContoh") or []
            rm = s.get("jawapanContohRumi") or []
            if len(ar) != len(rm):
                raise ValueError(f"{sid}: jawapanContoh berbeza panjang")
            seg: list[tuple[str, str]] = []
            for a, r in zip(ar, rm):
                if dl not in a or dl not in r:
                    raise ValueError(f"{sid}: {dl!r} tiada pada {a!r}")
                seg.append((suara_subjek, sebutan(_bersih_arab(a.split(dl, 1)[0]))))
                seg.append((SUARA, sebutan(bersih(r.split(dl, 1)[1]))))
            seg = [(v, t) for v, t in seg if t]
            if seg:
                tambah(jawi_mentah, bunyi=gabung_segmen(seg), suara=SUARA_CAMPURAN)
        elif audio.get("jawapanContoh"):
            raise ValueError(
                f"{sid}: mod audio.jawapanContoh tidak dikenali "
                f"{audio['jawapanContoh']!r}"
            )
        else:
            tambah(kunci_teks)

    # Jawapan panel pembetulan — **satu klip satu baris**.
    #
    # Butang "Dengar soalan & jawapan" meminta kunci `o-<baris>` bagi
    # setiap baris. Satu baris satu klip membolehkan app menambah jeda
    # antara baris — tanpa jeda, jawapan berbilang kedengaran seperti satu
    # karangan panjang.
    for baris in jawapan_dengar_segmen(s, rujuk_arab):
        for segmen in baris:
            tambah(segmen)

    return [(k, v, su) for k, v, su in keluar if v]


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

        for soalan in bank.get("soalan") or []:
            # `_teks` sudah memilih suara bagi setiap klip, jadi suara subjek
            # tidak lagi ditetapkan di sini.
            kerja.extend(_teks(soalan, rujuk_arab))

    # Kertas sebenar — satu fail bagi setiap kertas (`adab-2025.json`, …).
    # Nama fail membawa id subjek: `<subjek>-<tahun>`. Soalan sebenar mesti
    # mendengar suara Yasmin yang sama seperti bank; tanpa ini, kertas sebenar
    # jatuh kepada TTS peranti yang selalunya tiada suara Melayu.
    if os.path.isdir(FOLDER_SEBENAR):
        for nama_fail_json in sorted(os.listdir(FOLDER_SEBENAR)):
            if not nama_fail_json.endswith(".json"):
                continue
            sid_subjek = nama_fail_json[:-5].rsplit("-", 1)[0]
            if penapis and sid_subjek not in penapis:
                continue
            with open(os.path.join(FOLDER_SEBENAR, nama_fail_json),
                      encoding="utf-8") as f:
                kertas = json.load(f)
            rujuk_arab = sid_subjek in SUBJEK_ARAB
            for bahagian in kertas.get("bahagian") or []:
                for soalan in bahagian.get("soalan") or []:
                    kerja.extend(_teks(soalan, rujuk_arab))

    # Pembetulan sebutan dijalankan di sini supaya nama fail audio sentiasa
    # sepadan dengan teks yang benar-benar disebut. Klip bercampur suara
    # dikodkan sebagai JSON dan sudah pun dibetulkan segmen demi segmen
    # semasa dibina — menjalankannya melalui `sebutan` sekali lagi akan
    # memproses teks kod dan bukan ayat yang sebenar.
    hasil: list[tuple[str, str, str]] = []
    for kunci, teks, suara in kerja:
        hasil.append((kunci, teks, suara) if suara == SUARA_CAMPURAN
                     else (kunci, sebutan(teks), suara))
    return hasil


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

    # Manifest: kunci app -> nama fail.
    #
    # Jana **penuh** (tanpa `--subjek`) membina manifest dari kosong —klip
    # yang tidak lagi digunakan dibuang supaya saiz app tidak melonjak
    # setiap kali data berubah. Jana satu subjek sahaja perlu membaca
    # manifest lama, supaya klip subjek lain tidak dipadam.
    peta: dict[str, str] = {}
    if penapis is not None and os.path.exists(MANIFEST):
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
