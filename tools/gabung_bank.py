#!/usr/bin/env python3
"""Gabungkan potongan bank soalan menjadi satu fail setiap subjek.

Soalan ditulis dalam potongan (`kerja/bank/<subjek>-ab.json`,
`kerja/bank/<subjek>-cd.json`) supaya beberapa penulis boleh bekerja serentak.
App hanya membaca `assets/content/bank/<subjek>.json`, jadi potongan itu perlu
digabungkan, diperiksa dan diberi nombor yang berterusan.

Yang dilakukan oleh skrip ini:

1. Membaca setiap potongan mengikut susunan bahagian (A → B → C → D → E).
2. Membuang **soalan pendua** — dua soalan yang teks Jawinya sama selepas
   dinormalkan (ruang, tanda baca dan huruf besar diabaikan). Penjana kertas
   memilih soalan secara berputar, jadi soalan pendua menjadikan satu kertas
   berulang soalan yang sama.
3. Memberi setiap soalan `id` yang stabil dan unik: `<subjek>-<bahagian><nombor>`.
4. Menyemak kewujudan Bahagian B yang cukup untuk bilangan versi kertas, dan
   memaklumkan bilangan soalan setiap bahagian.
5. Menulis `assets/content/bank/<subjek>.json`.

Guna:
    python3 tools/gabung_bank.py            # gabung semua subjek yang lengkap
    python3 tools/gabung_bank.py adab        # gabung satu subjek sahaja
"""

from __future__ import annotations

import json
import os
import re
import sys

AKAR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FOLDER_KERJA = os.path.join(AKAR, "kerja", "bank")
FOLDER_KELUARAN = os.path.join(AKAR, "assets", "content", "bank")

SUBJEK = ["adab", "akidah", "arab", "ibadah", "jawi", "sirah"]

# Potongan dibaca mengikut urutan ini supaya penomboran bahagian tersusun.
POTONGAN = ["ab", "cd"]

# Susunan bahagian dalam satu kertas UPKK.
SUSUNAN_BAHAGIAN = ["A", "B", "C", "D", "E"]


def normalkan(teks: str) -> str:
    """Bentuk bandingan bagi teks Jawi — buang tanda baca dan ruang berlebihan."""
    teks = re.sub(r"[\u064B-\u0652\u0670\u06D6-\u06ED]", "", teks)  # harakat
    teks = re.sub(r"[^\w\u0600-\u06FF]+", "", teks)
    return teks.strip().lower()


def kunci_soalan(s: dict) -> str:
    """Kunci pendua bagi satu soalan.

    Teks `soalan` sahaja **tidak cukup**: banyak soalan Bahagian A berkongsi
    arahan yang sama ("Tandakan betul atau salah."), jadi membandingkan arahan
    sahaja akan membuang soalan yang sebenarnya berbeza. Kunci mesti merangkumi
    kandungan yang menjadikan soalan itu unik — iaitu item, pasangan, urutan dan
    bank perkataannya.
    """
    bahagian_bahan: list[str] = [normalkan(s.get("soalan") or "")]
    bahagian_bahan.append(s.get("jenis") or "")

    for it in s.get("item") or []:
        bahagian_bahan.append(normalkan(it.get("teks") or ""))
        pilihan = it.get("pilihan") or []
        if pilihan:
            teks_pilihan = [
                normalkan(p.get("teks") if isinstance(p, dict) else p)
                for p in pilihan
            ]
            # Susunan pilihan tidak menjadikan soalan berbeza, jadi susun dahulu.
            bahagian_bahan.append("|".join(sorted(teks_pilihan)))

    for p in s.get("pasangan") or []:
        bahagian_bahan.append(normalkan(p.get("kiri") or ""))
        bahagian_bahan.append(normalkan(p.get("kanan") or ""))

    for u in s.get("urutan") or []:
        bahagian_bahan.append(normalkan(u))

    for b in s.get("bank") or []:
        bahagian_bahan.append(normalkan(b))

    return "¬".join(x for x in bahagian_bahan if x)


def baca_potongan(subjek: str) -> tuple[list[dict], list[str]]:
    soalan: list[dict] = []
    nota: list[str] = []
    for potong in POTONGAN:
        laluan = os.path.join(FOLDER_KERJA, f"{subjek}-{potong}.json")
        if not os.path.exists(laluan):
            nota.append(f"potongan '{potong}' tiada — {os.path.basename(laluan)}")
            continue
        with open(laluan, encoding="utf-8") as f:
            data = json.load(f)
        bahagian = data.get("soalan") or []
        if not isinstance(bahagian, list):
            raise SystemExit(f"{laluan}: medan 'soalan' bukan senarai")
        soalan.extend(bahagian)
        nota.append(f"potongan '{potong}': {len(bahagian)} soalan")
    return soalan, nota


def susun_dan_buang_pendua(soalan: list[dict]) -> tuple[list[dict], int]:
    """Susun ikut bahagian, kemudian buang soalan yang teks Jawinya berulang."""
    susun: list[dict] = []
    for bahagian in SUSUNAN_BAHAGIAN:
        kumpulan = [s for s in soalan if (s.get("bahagian") or "").upper() == bahagian]
        # Soalan asal sudah tersusun; kekalkan urutan itu supaya nombor stabil
        # selagi tiada soalan baharu diselitkan di tengah.
        susun.extend(kumpulan)

    dilihat: dict[str, dict] = {}
    bersih: list[dict] = []
    pendua = 0
    for s in susun:
        kunci = kunci_soalan(s)
        if kunci and kunci in dilihat:
            pendua += 1
            continue
        if kunci:
            dilihat[kunci] = s
        bersih.append(s)
    return bersih, pendua


def main() -> int:
    dipilih = sys.argv[1:] or SUBJEK
    os.makedirs(FOLDER_KELUARAN, exist_ok=True)

    ada_masalah = False
    for subjek in dipilih:
        soalan, nota = baca_potongan(subjek)
        if not soalan:
            print(f"\n=== {subjek} ===")
            print("  tiada potongan — dilangkau")
            ada_masalah = True
            continue

        soalan, pendua = susun_dan_buang_pendua(soalan)

        # Nombor berterusan dalam setiap bahagian.
        pembilang: dict[str, int] = {}
        for s in soalan:
            bahagian = (s.get("bahagian") or "A").upper()
            pembilang[bahagian] = pembilang.get(bahagian, 0) + 1
            s["id"] = f"{subjek}-{bahagian.lower()}{pembilang[bahagian]}"

        bilangan: dict[str, int] = {}
        markah: dict[str, int] = {}
        for s in soalan:
            bahagian = (s.get("bahagian") or "A").upper()
            bilangan[bahagian] = bilangan.get(bahagian, 0) + 1
            markah[bahagian] = markah.get(bahagian, 0) + int(s.get("markah") or 0)

        laluan = os.path.join(FOLDER_KELUARAN, f"{subjek}.json")
        with open(laluan, "w", encoding="utf-8") as f:
            json.dump(
                {
                    "id": subjek,
                    "versi": 1,
                    "bilangan": len(soalan),
                    "soalan": soalan,
                },
                f,
                ensure_ascii=False,
                indent=1,
            )

        print(f"\n=== {subjek} ===")
        for n in nota:
            print(f"  {n}")
        if pendua:
            print(f"  soalan pendua dibuang: {pendua}")
        pecahan = ", ".join(
            f"{b}: {bilangan.get(b, 0)} soalan / {markah.get(b, 0)} markah"
            for b in SUSUNAN_BAHAGIAN
            if bilangan.get(b)
        )
        print(f"  bahagian: {pecahan}")
        print(f"  jumlah: {len(soalan)} soalan")
        print(f"  ditulis: {os.path.relpath(laluan, AKAR)}")

    return 1 if ada_masalah else 0


if __name__ == "__main__":
    raise SystemExit(main())
