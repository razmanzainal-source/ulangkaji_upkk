#!/usr/bin/env python3
"""Jana bunyi kesan (sound effect) untuk maklum balas jawapan.

Bunyi ini **bukan** suara — ia cuma nada. Sebab ia dijana di sini dan bukan
dimuat turun:

  * app mesti kekal 100% luar talian dan bebas lesen pihak ketiga;
  * rakaman suara sahaja tidak cukup untuk maklum balas serta-merta — nada
    pendek lebih pantas difahami kanak-kanak daripada ayat yang panjang;
  * failnya kecil (beberapa kilobait), jadi ia boleh dibundelkan tanpa
    membebankan saiz muat turun app.

Tiga nada dijana:

  * `betul`  — arpeggio menaik (C5–E5–G5–C6), loceng kecil yang menyeronokkan.
    Bunyi menaik dianggap "berjaya" dalam hampir semua budaya.
  * `salah`  — dua not menurun yang lembut (G4–D4), sengaja **tidak** tajam
    atau bising. Murid Tahun 5 yang tersalah menjawab tidak patut rasa dihukum.
  * `hebat`  — fanfar tiga not (C5–G5–C6) untuk skrin keputusan yang cemerlang.

Guna:
    python3 tools/jana_kesan.py            # jana yang belum ada
    python3 tools/jana_kesan.py --paksa    # jana semula semua

Keperluan: `afconvert` (bawaan macOS) untuk menukar WAV kepada AAC/M4A.
"""

from __future__ import annotations

import argparse
import math
import os
import struct
import subprocess
import sys
import tempfile
import wave

AKAR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KELUARAN = os.path.join(AKAR, "assets", "bunyi", "kesan")

KADAR = 22050  # Hz — memadai untuk nada ringkas, dan menjimatkan saiz fail

# Not dalam Hz.
NOT = {
    "C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.00,
    "A4": 440.00, "B4": 493.88,
    "C5": 523.25, "D5": 587.33, "E5": 659.25, "F5": 698.46, "G5": 783.99,
    "A5": 880.00, "B5": 987.77,
    "C6": 1046.50, "E6": 1318.51, "G6": 1567.98,
}


def _sampel(
    kekerapan: float,
    masa: float,
    jumlah: int,
    amplitud: float,
    serak: float,
) -> list[float]:
    """Satu not dengan sampul loceng: serangan pantas, pereputan eksponen.

    Dua harmonik tambahan digunakan (oktaf dan kuint) kerana nada sinus tulen
    berbunyi kosong dan "elektronik"; harmonik menjadikannya menyerupai loceng
    kecil.
    """
    keluar = []
    for i in range(jumlah):
        t = i / KADAR
        if t < masa:
            keluar.append(0.0)
            continue
        sejak = t - masa  # masa sejak not ini bermula
        if sejak > serak:
            keluar.append(0.0)
            continue
        serangan = min(1.0, sejak / 0.004)  # 4 ms
        pereputan = math.exp(-3.2 * (sejak / serak))
        nilai = (
            math.sin(2 * math.pi * kekerapan * t)
            + 0.32 * math.sin(4 * math.pi * kekerapan * t)
            + 0.12 * math.sin(6 * math.pi * kekerapan * t)
        )
        keluar.append(amplitud * serangan * pereputan * nilai)
    return keluar


def _campur(buf: list[float], nota: list[float], pada: int) -> None:
    """Tambah [nota] ke dalam [buf] bermula pada indeks [pada]."""
    for i, nilai in enumerate(nota):
        j = pada + i
        if j >= len(buf):
            break
        buf[j] += nilai


def bina_sampel(skrip: list[tuple[str, float]]) -> list[float]:
    """Bina bentuk gelombang daripada senarai (nama not, jarak mula dalam saat)."""
    tempoh = max(masa for _, masa in skrip) + 0.9
    jumlah = int(KADAR * tempoh)
    buf = [0.0] * jumlah
    for nama, masa in skrip:
        not_buf = _sampel(NOT[nama], masa, jumlah, amplitud=1.0, serak=0.85)
        _campur(buf, not_buf, int(masa * KADAR))
    return buf


def tulis_wav(buf: list[float], laluan: str) -> None:
    """Tulis [buf] sebagai WAV mono 16-bit dengan puncak dinormalkan."""
    puncak = max((abs(x) for x in buf), default=1.0) or 1.0
    # -3 dBFS: cukup kuat, tetapi tidak memotong (clip) selepas pengekodan AAC.
    skala = 0.71 / puncak
    with wave.open(laluan, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(KADAR)
        f.writeframes(
            b"".join(
                struct.pack("<h", int(max(-1.0, min(1.0, x * skala)) * 32767))
                for x in buf
            )
        )


# Setiap kesan: (nama, senarai (not, masa mula)).
KESAN: list[tuple[str, list[tuple[str, float]]]] = [
    # C5–E5–G5–C6: arpeggio menaik, 85 ms antara not — pantas dan ceria.
    ("betul", [("C5", 0.00), ("E5", 0.085), ("G5", 0.170), ("C6", 0.255)]),
    # G4–D4: dua not menurun, perlahan, lembut.
    ("salah", [("G4", 0.00), ("D4", 0.150)]),
    # C5–G5–C6: fanfar pendek untuk keputusan cemerlang.
    ("hebat", [("C5", 0.00), ("G5", 0.110), ("C6", 0.220), ("E6", 0.330)]),
]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--paksa", action="store_true")
    args = parser.parse_args()

    os.makedirs(KELUARAN, exist_ok=True)

    for nama, skrip in KESAN:
        akhir = os.path.join(KELUARAN, f"{nama}.m4a")
        if os.path.exists(akhir) and not args.paksa:
            print(f"  {nama}.m4a sudah ada — dilangkau")
            continue

        buf = bina_sampel(skrip)
        with tempfile.TemporaryDirectory() as td:
            wav = os.path.join(td, f"{nama}.wav")
            tulis_wav(buf, wav)
            subprocess.run(
                [
                    "afconvert", "-f", "m4af", "-d", "aac", "-b", "64000",
                    "-c", "1", wav, akhir,
                ],
                check=True,
                capture_output=True,
            )

        saiz = os.path.getsize(akhir)
        tempoh = len(buf) / KADAR
        print(f"  {nama}.m4a — {tempoh:.2f}s, {saiz / 1024:.1f} KB")

    jumlah = sum(
        os.path.getsize(os.path.join(KELUARAN, f))
        for f in os.listdir(KELUARAN)
        if f.endswith(".m4a")
    )
    print(f"\nSiap. {len(KESAN)} bunyi kesan, {jumlah / 1024:.1f} KB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
