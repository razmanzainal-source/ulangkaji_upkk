#!/usr/bin/env python3
"""Tambah kata kunci Jawi pada rubrik soalan bertulis.

**Masalah yang diselesaikan.** Soalan bertulis UPKK dijawab dalam tulisan Jawi.
Tetapi rubrik bank pada asalnya hanya mempunyai kata kunci Rumi untuk 825
daripada 1,548 idea — jadi murid yang menaip jawapan Jawi yang betul mendapat
sifar markah. Menulis kata kunci Jawi untuk 825 idea dengan tangan terlalu besar
dan senang tersilap ejaan.

**Cara penyelesaian.** Setiap soalan bertulis sudah membawa `jawapanContoh` —
jawapan penuh dalam Jawi yang ditulis oleh pengarang bank. Fail ini membaca
contoh itu, memadankannya dengan idea rubrik, dan menyalin perkataan Jawi yang
**membezakan** idea itu daripada idea lain dalam soalan yang sama.

Tiga peringkat pengambilan kata kunci:

1. **Perkataan tunggal** yang muncul dalam satu idea sahaja. Ini kes paling
   biasa dan paling tepat.
2. **Frasa dua atau tiga perkataan** yang muncul dalam satu idea sahaja.
   Diperlukan apabila idea-idea berkongsi perkataan yang sama — contohnya lima
   solat sunat rawatib semuanya bermula "دوا رکعة ... صلاة", dan hanya frasa
   "سبلوم صلاة ظهر" membezakan satu daripada yang lain.
3. **Kata Jawi selepas sengkang** dalam `maksud` idea ("Rumah — بَيْتٌ").
   Kata ini ditulis oleh pengarang bank, jadi ia pasti betul.

Kata sendi dan kata ganti dibuang sepenuhnya (lihat [HENTI]); kata isi seperti
"الله" dan "محمد" **tidak** dibuang — itulah jawapannya pada sesetengah soalan,
dan ia sudah disaring oleh peraturan "satu idea sahaja".

**Padanan contoh dengan idea.** Bilangan contoh tidak selalunya sama dengan
bilangan idea. Tiga strategi dicuba:

  1. Jika bilangan contoh sama dengan bilangan idea, padan mengikut kedudukan.
  2. Jika tidak, contoh (satu rentetan panjang) dipecahkan kepada cebis-cebis
     dengan tanda baca dan kata penghubung ("دان", "اتاو"). Jika bilangan cebis
     sama dengan bilangan idea, padan mengikut kedudukan.
  3. Jika masih tidak, cebis Rumi dipadankan dengan idea melalui kata kunci
     Rumi (yang sudah lengkap), kemudian cebis Jawi yang sejajar dengannya
     diambil.

Laporan akhir menyenaraikan soalan yang masih tidak dapat dipadankan supaya
pengarang bank boleh membetulkannya dengan tangan.

Guna:
    python3 tools/tambah_kata_jawi.py              # tulis perubahan
    python3 tools/tambah_kata_jawi.py --kering     # hanya lapor
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import re
import sys

AKAR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FOLDER_BAHAGIAN = os.path.join(AKAR, "kerja", "bank")

POLA_ARAB = re.compile(r"[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]")

# Kata sendi, kata ganti dan kata bantu — perkataan yang tidak pernah membawa
# markah.
#
# Perkataan **isi** (الله، نبي، محمد، رسول، مسلم) sengaja tidak disenaraikan di
# sini. Pada soalan "senaraikan rukun iman", "الله" dan "رسول" itulah
# jawapannya; membuangnya menjadikan jawapan Jawi yang betul tidak bermarkah.
# Perkataan sebegitu disaring oleh peraturan "muncul dalam satu idea sahaja".
HENTI = {
    # kata sendi Jawi
    "يڠ", "دان", "دڠن", "کڤد", "اکن", "دالم", "دري", "درڤد", "اوله",
    "باضي", "اونتوق", "سباݢاي", "سچارا", "کتيک", "کمودين", "يئيتو",
    "اياله", "اداله", "اده", "اتاو", "سرتا", "ايت", "اين", "ايتو",
    # kata ganti dan kata bantu
    "کيت", "کامي", "کامو", "ساي", "اکو", "دي", "مريک",
    "تله", "سوده", "بلوم", "له", "ڤد", "کي", "ني",
    # kata sendi Arab
    "في", "مع", "من", "هل", "ما", "لا", "ان", "او", "کل", "کم", "هم",
    "هي", "هو", "ذا", "ذي",
}

# Tanda baca yang memisahkan cebis dalam contoh jawapan.
#
# Angka **tidak** dijadikan pemisah: pada soalan "tukar angka kepada Jawi",
# angka itulah jawapannya. Membuangnya akan menjadikan senarai jawapan kosong.
PEMISAH = re.compile(r"[\n؛;،,.]")

# Kata penghubung yang memisahkan item dalam senarai jawapan.
#
# Contoh jawapan bagi soalan "senaraikan" ditulis sebagai satu ayat —
# "توراة، زبور، انجيل دان القرءان" — dan hanya pemisah terakhir ialah tanda
# baca. Tanpa memecah pada "دان" (dan), dua item terakhir bergabung menjadi
# satu cebis, dan padanan dengan idea rubrik gagal.
PEMISAH_KATA = re.compile(r"\s+(?:دان|اتاو|سرتا)\s+")

# Tanda baris (harakat) dan tatweel.
TANDA_BARIS = re.compile(r"[\u0640\u064B-\u065F\u0670\u06D6-\u06ED]")

# Sekurang-kurangnya satu huruf Arab — untuk mengekalkan cebis Arab yang
# keseluruhan perkataannya kata sendi (contohnya "رسول.").
POLA_HURUF_ARAB = re.compile(r"[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]+")


def ada_arab(teks: str) -> bool:
    return bool(POLA_ARAB.search(teks))


def tanggal_baris(teks: str) -> str:
    """Buang tanda baris. Pemarkah app juga mengabaikannya semasa menanda."""
    return TANDA_BARIS.sub("", teks)


# Huruf yang mewakili bunyi yang sama, sama seperti pemarkah app.
SAMA_HURUF = str.maketrans({
    "\u0643": "\u06A9",  # ك kaf Arab      -> ک kaf Jawi
    "\u06CC": "\u064A",  # ی ya Farsi      -> ي ya
    "\u0649": "\u064A",  # ى alif maksura  -> ي ya
    "\u067E": "\u06A4",  # پ peh Farsi     -> ڤ pa Jawi
    "\u06AF": "\u0762",  # گ gaf Farsi     -> ݢ ga Jawi
})

# Pemarkah hujung yang dibuang apabila membandingkan perkataan.
AKHIRAN = ("nya", "kan", "an", "i")


def normal_huruf(teks: str) -> str:
    return tanggal_baris(teks).translate(SAMA_HURUF)


def token_teks(teks: str) -> set[str]:
    """Set perkataan ternormal dalam [teks] — meniru cara app menanda."""
    return set(senarai_token(teks))


def senarai_token(teks: str) -> list[str]:
    """Perkataan ternormal dalam [teks], mengikut urutan asalnya."""
    keluar: list[str] = []
    potongan = re.split(
        r"[^a-zA-Z0-9\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]+", teks.lower()
    )
    for p in potongan:
        if p:
            keluar.append(normal_huruf(p))
    return keluar


def kata_sepadan(kata: str, token_jawapan: set[str], mentah: str) -> bool:
    """Benar apabila kata kunci [kata] ada dalam [token_jawapan]."""
    perlu = token_teks(kata)
    if not perlu:
        # Kata kunci yang hanya tanda baca ("؟") — dibandingkan terus.
        tanda = kata.strip()
        return bool(tanda) and tanda in mentah
    return perlu.issubset(token_jawapan)


def perkataan_jawi(teks: str) -> list[str]:
    """Perkataan Jawi bermakna dalam [teks], tanpa tanda baca dan kata sendi."""
    keluar = []
    potongan = re.split(r"[^\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]+", teks)
    for mentah in (tanggal_baris(p) for p in potongan):
        if len(mentah) < 2:
            # Satu huruf hampir selalu angka atau sisa tanda baca.
            continue
        if mentah in HENTI:
            continue
        keluar.append(mentah)
    return keluar


def varian_jawi(kata: str) -> list[str]:
    """Bentuk lain yang sama maksudnya dengan [kata].

    Kata nama Arab selalunya ditulis dengan kata alif-lam di hadapan. Murid
    yang menulis "مسجد" dan bukan "المسجد" menjawab soalan yang sama, jadi
    kedua-duanya diterima. "الله" dikecualikan kerana alif-lam-nya sebahagian
    daripada perkataan itu sendiri.
    """
    keluar = [kata]
    if kata.startswith("ال") and len(kata) > 3 and kata != "الله":
        keluar.append(kata[2:])
    return keluar


def perkataan_rumi(teks: str) -> set[str]:
    return {
        p
        for p in re.split(r"[^a-z0-9]+", teks.lower())
        if len(p) >= 4
    }


def cebis(teks: str) -> list[str]:
    """Pecahkan rentetan panjang kepada cebis yang bermakna."""
    serpihan: list[str] = []
    for bahagian in PEMISAH_KATA.split(teks):
        serpihan.extend(PEMISAH.split(bahagian))

    keluar = []
    for mentah in serpihan:
        s = mentah.strip()
        if not s:
            continue
        if ada_arab(s):
            # Cebis Arab dikekalkan walaupun semua perkataannya kata sendi:
            # "نبي محمد" perlu kekal sebagai satu cebis untuk idea kelima,
            # walaupun "نبي" dibuang daripada senarai kata kunci.
            if POLA_HURUF_ARAB.search(s):
                keluar.append(s)
        elif len(s) >= 3:
            keluar.append(s)
    return keluar


def padan_mengikut_kedudukan(
    idea: list[dict], contoh: list[str]
) -> list[str] | None:
    """Padan idea dengan contoh mengikut kedudukan, atau `None` jika gagal."""
    if len(contoh) == len(idea):
        return list(contoh)
    if len(contoh) == 1:
        c = cebis(contoh[0])
        if len(c) == len(idea):
            return c
    return None


def padan_mengikut_kata_kunci(
    idea: list[dict], contoh_jawi: list[str], contoh_rumi: list[str]
) -> list[str] | None:
    """Padan idea dengan cebis Jawi melalui kata kunci Rumi.

    Cebis Rumi dipadankan dengan idea yang paling banyak kata kuncinya muncul,
    kemudian cebis Jawi yang sejajar dengannya diberikan kepada idea itu.
    """
    if not contoh_jawi or not contoh_rumi:
        return None

    j = cebis(contoh_jawi[0])
    r = cebis(contoh_rumi[0])
    if not j or len(j) != len(r):
        return None

    kata_idea = [perkataan_rumi(" ".join(i.get("kata") or [])) for i in idea]
    padanan: list[str | None] = [None] * len(idea)
    dipakai: set[int] = set()

    # Setiap cebis Rumi diambil oleh idea yang paling sepadan (tamak).
    for indeks_cebis, teks_rumi in enumerate(r):
        kata_cebis = perkataan_rumi(teks_rumi)
        skor_terbaik = 0
        calon = -1
        for i, kata in enumerate(kata_idea):
            if i in dipakai:
                continue
            skor = len(kata_cebis & kata)
            if skor > skor_terbaik:
                skor_terbaik = skor
                calon = i
        if calon >= 0 and skor_terbaik > 0:
            padanan[calon] = j[indeks_cebis]
            dipakai.add(calon)

    if any(p is None for p in padanan):
        return None
    return [p for p in padanan if p is not None]


def frasa(senarai: list[str]) -> set[str]:
    """Frasa dua dan tiga perkataan yang berturutan dalam [senarai]."""
    keluar: set[str] = set()
    for n in (2, 3):
        for i in range(len(senarai) - n + 1):
            keluar.add(" ".join(senarai[i : i + n]))
    return keluar


def proses_soalan(soalan: dict) -> tuple[bool, list[str]]:
    """Tambah kata kunci Jawi pada satu soalan. Pulang (berjaya, nota)."""
    idea = soalan.get("idea") or []
    contoh = soalan.get("jawapanContoh") or []
    contoh_rumi = soalan.get("jawapanContohRumi") or []
    if not idea:
        return False, ["tiada idea"]

    padanan = padan_mengikut_kedudukan(idea, contoh)
    if padanan is None:
        padanan = padan_mengikut_kata_kunci(idea, contoh, contoh_rumi)
    if padanan is None:
        return False, [
            f"{len(idea)} idea, {len(contoh)} contoh — tidak dapat dipadankan"
        ]

    perkataan_cebis = [perkataan_jawi(c) for c in padanan]

    # Adakah contoh jawapan yang sejajar itu **sudah** dikenali oleh kata kunci
    # idea? Jika tidak, murid yang menulis jawapan contoh itu sendiri akan
    # mendapat sifar markah — dan itulah keadaan yang perlu dibetulkan.
    token_cebis = [token_teks(c) for c in padanan]
    dikenali = [
        any(kata_sepadan(k, token_cebis[i], padanan[i]) for k in (kata.get("kata") or []))
        for i, kata in enumerate(idea)
    ]

    # Cebis contoh sebagai urutan perkataan, tanpa membuang kata sendi. Ini
    # dipakai sebagai jalan terakhir: "في المسجد" membezakan idea walaupun
    # "المسجد" sahaja tidak.
    urutan_cebis = [senarai_token(c) for c in padanan]
    teks_cebis = [" ".join(u) for u in urutan_cebis]

    # Kekerapan dokumen: berapa banyak idea yang mengandungi perkataan ini.
    # Perkataan yang muncul dalam lebih daripada satu idea tidak memberitahu
    # idea mana yang murid jawab, jadi ia tidak berguna sebagai kata kunci.
    kekerapan: dict[str, int] = {}
    for senarai in perkataan_cebis:
        for p in set(senarai):
            kekerapan[p] = kekerapan.get(p, 0) + 1

    frasa_cebis = [frasa(senarai) for senarai in perkataan_cebis]
    kekerapan_frasa: dict[str, int] = {}
    for senarai in frasa_cebis:
        for f in senarai:
            kekerapan_frasa[f] = kekerapan_frasa.get(f, 0) + 1

    ditambah = 0
    for i, kata in enumerate(idea):
        asal = list(kata.get("kata") or [])
        baharu = list(asal)
        sudah = set(baharu)

        def tambah(nilai: str) -> None:
            nonlocal ditambah
            if nilai in sudah:
                return
            baharu.append(nilai)
            sudah.add(nilai)
            ditambah += 1

        # 1. Perkataan tunggal yang membezakan idea ini daripada idea lain.
        for p in perkataan_cebis[i]:
            if kekerapan[p] != 1:
                continue
            for v in varian_jawi(p):
                tambah(v)

        # 2. Frasa unik — untuk idea yang belum dikenali, dan yang berkongsi
        #    semua perkataannya dengan idea lain ("سبلوم صلاة ظهر" lawan
        #    "سلڤس صلاة ظهر"). Hanya dua frasa terpanjang diambil supaya
        #    senarai kata kunci tidak membengkak.
        if not dikenali[i]:
            dipakai = 0
            for f in sorted(frasa_cebis[i], key=len, reverse=True):
                if dipakai >= 2:
                    break
                if kekerapan_frasa[f] != 1:
                    continue
                sebelum = len(baharu)
                tambah(f)
                if len(baharu) > sebelum:
                    dipakai += 1

            # Jalan terakhir: keseluruhan cebis contoh, **termasuk** kata sendi.
            # "في المسجد" membezakan idea ini daripada idea "rumah yang dekat
            # dengan masjid", walaupun perkataan "المسجد" sendiri muncul dalam
            # kedua-duanya. Tanpa langkah ini, murid yang menulis jawapan contoh
            # itu sendiri tidak mendapat markah.
            penuh = teks_cebis[i]
            if penuh and penuh not in sudah:
                bilangan = sum(1 for t in teks_cebis if penuh in t)
                if bilangan == 1:
                    tambah(penuh)

        # 3. Kata Jawi selepas sengkang dalam maksud idea ("Rumah — بَيْتٌ").
        for mentah in re.split(r"[—–\-]", kata.get("maksud") or "")[1:]:
            for p in perkataan_jawi(mentah):
                tambah(p)

        if baharu != asal:
            kata["kata"] = baharu

    return True, [f"+{ditambah} kata Jawi"]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--kering",
        action="store_true",
        help="jangan tulis fail; hanya laporkan apa yang akan berlaku",
    )
    args = parser.parse_args()

    fail = sorted(
        f
        for f in glob.glob(os.path.join(FOLDER_BAHAGIAN, "*.json"))
        if not os.path.basename(f).startswith("_")
    )
    if not fail:
        print(f"Tiada fail bank dalam {FOLDER_BAHAGIAN}")
        return 1

    jumlah_ok = 0
    masalah: list[str] = []

    for laluan in fail:
        nama = os.path.basename(laluan)
        with open(laluan, encoding="utf-8") as f:
            data = json.load(f)
        soalan_senarai = data.get("soalan") or data
        if not isinstance(soalan_senarai, list):
            print(f"  {nama}: format tidak dikenali — dilangkau")
            continue

        ok = 0
        tambah = 0
        for s in soalan_senarai:
            if s.get("jenis") not in ("tulis", "huraian"):
                continue
            berjaya, nota = proses_soalan(s)
            if berjaya:
                ok += 1
                for n in nota:
                    m = re.match(r"\+(\d+)", n)
                    if m:
                        tambah += int(m.group(1))
            else:
                masalah.append(f"{nama}:{s.get('id')} — {nota[0]}")

        jumlah_ok += ok
        if not args.kering:
            with open(laluan, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
                f.write("\n")
        print(f"  {nama}: {ok} soalan diproses, +{tambah} kata kunci Jawi")

    print()
    print(f"Soalan diproses: {jumlah_ok}")
    print(f"Soalan bermasalah: {len(masalah)}")
    for m in masalah:
        print(f"  {m}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
