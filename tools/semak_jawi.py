#!/usr/bin/env python3
"""Laporkan ejaan Jawi yang mencurigakan dalam bank soalan.

Penggunaan:
    python3 tools/semak_jawi.py            # ringkasan
    python3 tools/semak_jawi.py --penuh    # senarai penuh (untuk dibetulkan)
    python3 tools/semak_jawi.py --kata guru# nyatakan   # siasat perkataan

Skrip ini tidak mengubah apa-apa. Ia mengumpul setiap pasangan (Rumi, Jawi)
daripada bank — soalan, item, pilihan, pasangan, bank kata dan urutan — dan
melaporkan:

  1. pelanggaran peraturan huruf (lihat `tools/jawi.py`);
  2. perkataan Rumi yang mempunyai **lebih daripada satu** ejaan Jawi, iaitu
     tanda paling kuat bahawa sekurang-kurangnya satu daripadanya salah.
"""

from __future__ import annotations

import argparse
import collections
import difflib
import glob
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import jawi  # noqa: E402

AKAR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BANK = os.path.join(AKAR, "assets", "content", "bank")
PINJAMAN = os.path.join(AKAR, "tools", "kata_pinjaman_arab.txt")


def pasangan_bank():
    """Hasilkan (subjek, id, jawi, rumi) bagi setiap teks dwibahasa."""
    for fail in sorted(glob.glob(os.path.join(BANK, "*.json"))):
        subjek = os.path.basename(fail)[:-5]
        with open(fail, encoding="utf-8") as f:
            data = json.load(f)
        for s in data.get("soalan") or []:
            sid = s.get("id") or "?"
            yield subjek, sid, s.get("soalan", ""), s.get("rumi", "")
            for it in s.get("item") or []:
                yield subjek, sid, it.get("teks", ""), it.get("rumi", "")
                for p in it.get("pilihan") or []:
                    if isinstance(p, dict):
                        yield subjek, sid, p.get("teks", ""), p.get("rumi", "")
            for p in s.get("pasangan") or []:
                yield subjek, sid, p.get("kiri", ""), p.get("kiriRumi", "")
                yield subjek, sid, p.get("kanan", ""), p.get("kananRumi", "")
            for a, b in zip(s.get("bank") or [], s.get("bankRumi") or []):
                yield subjek, sid, a, b
            for a, b in zip(s.get("urutan") or [], s.get("urutanRumi") or []):
                yield subjek, sid, a, b


def kumpul() -> tuple[dict[str, dict[str, list[str]]], list[tuple[str, str, str]]]:
    """Peta rumi → {ejaan jawi → [contoh id]}, dan senarai ayat tidak sepadan.

    Perkataan dipadankan dengan `difflib` dan bukan mengikut kedudukan: ayat
    Rumi dan Jawi kadangkala tidak mempunyai bilangan perkataan yang sama
    (contohnya "di dalam masjid" lawan "دالم مسجد"), dan pemadanan mengikut
    kedudukan akan melaporkan perkataan yang betul sebagai salah.
    """
    peta: dict[str, dict[str, list[str]]] = collections.defaultdict(
        lambda: collections.defaultdict(list)
    )
    tidak_sepadan: list[tuple[str, str, str]] = []

    for subjek, sid, jw, rumi in pasangan_bank():
        # Subjek Bahasa Arab ditulis dalam **tulisan Arab**, bukan Jawi: kaf
        # Arab (ك), hamzah (أ) dan ta marbutah (ة) betul di sana. Semakan
        # ejaan Jawi tidak terpakai.
        if subjek == "arab":
            continue
        rw = jawi.token_rumi(rumi)
        jw_t = [jawi.normalisasi(t) for t in jawi.token_jawi(jw)]
        jw_t = [t for t in jw_t if t]
        if not rw and not jw_t:
            continue
        if len(rw) == len(jw_t):
            for r, j in zip(rw, jw_t):
                if not any("\u0600" <= ch <= "\u06FF" for ch in j):
                    # Token bukan Arab (angka, "iv", "✓") bukan ejaan Jawi.
                    continue
                peta[r][j].append(f"{subjek}:{sid}")
        else:
            tidak_sepadan.append((f"{subjek}:{sid}", rumi, jw))
    return peta, tidak_sepadan


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--penuh", action="store_true", help="senarai penuh")
    ap.add_argument("--kata", nargs="*", help="siasat perkataan tertentu")
    ap.add_argument("--had", type=int, default=60)
    args = ap.parse_args()

    pinjaman = jawi.baca_pinjaman(PINJAMAN)
    peta, tidak_sepadan = kumpul()

    if args.kata:
        for k in args.kata:
            k = k.lower()
            if k not in peta:
                print(f"{k}: tiada dalam bank")
                continue
            print(f"\n{k}:")
            for ejaan, contoh in sorted(
                peta[k].items(), key=lambda kv: -len(kv[1])
            ):
                masalah = jawi.semak(k, ejaan, pinjaman)
                tanda = ("  ← " + "; ".join(masalah)) if masalah else ""
                print(f"  {ejaan:20} {len(contoh):4}x  {contoh[0]}{tanda}")
        return 0

    masalah_peta: dict[str, list[tuple[str, int, list[str], list[str]]]] = {}
    for r, ejaan in peta.items():
        baris = []
        for j, contoh in ejaan.items():
            m = jawi.semak(r, j, pinjaman)
            if m:
                baris.append((j, len(contoh), m, contoh))
        if baris:
            masalah_peta[r] = sorted(baris, key=lambda x: -x[1])

    # Kata pinjaman Arab dikesan daripada data: jika ejaan yang paling kerap
    # menggunakan huruf Arab sahaja (ص ض ط ظ ع ة ...), perkataan itu memang
    # ditulis dalam ejaan Arab dan bukan kesilapan Jawi Melayu.
    pinjaman = set(pinjaman)
    for r, ejaan in peta.items():
        utama, contoh = max(ejaan.items(), key=lambda kv: len(kv[1]))
        jumlah = sum(len(v) for v in ejaan.values())
        if len(contoh) / jumlah >= 0.8 and set(utama) & jawi.ARAB_SAHAJA:
            pinjaman.add(r)

    bercanggah = {
        r: e for r, e in peta.items() if len(e) > 1 and r not in pinjaman
    }

    jumlah_kata = len(peta)
    print(f"perkataan Rumi unik : {jumlah_kata}")
    print(f"ayat tidak sepadan  : {len(tidak_sepadan)}")
    print(f"pelanggaran peraturan: {len(masalah_peta)}")
    print(f"ejaan bercanggah    : {len(bercanggah)}")
    print()

    if args.penuh:
        for r, baris in sorted(masalah_peta.items(), key=lambda x: -sum(b[1] for b in x[1])):
            print(f"{r}:")
            for j, n, m, contoh in baris:
                print(f"   {j:20} {n:4}x  {contoh[0]}  ← {'; '.join(m)}")
        print("\n=== bercanggah (tanpa pelanggaran huruf) ===")
        for r, ejaan in sorted(
            bercanggah.items(), key=lambda x: -sum(len(v) for v in x[1].values())
        ):
            if r in masalah_peta:
                continue
            print(f"{r:16} {dict(ejaan)}")
        return 0

    print("--- pelanggaran paling kerap ---")
    for r, baris in sorted(
        masalah_peta.items(), key=lambda x: -sum(b[1] for b in x[1])
    )[: args.had]:
        j, n, m, contoh = baris[0]
        print(f"{r:16} {j:20} {n:4}x  ← {'; '.join(m)}")

    print("\n--- ejaan bercanggah paling kerap ---")
    for r, ejaan in sorted(
        bercanggah.items(), key=lambda x: -sum(len(v) for v in x[1].values())
    )[: args.had]:
        if r in masalah_peta:
            continue
        print(f"{r:16} {dict(ejaan)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
