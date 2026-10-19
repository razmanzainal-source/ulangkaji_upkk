#!/usr/bin/env python3
"""Pengesah bank soalan Ulangkaji UPKK.

Skrip ini memeriksa fail bank soalan **sebelum** ia dimasukkan ke dalam app.
Ia menangkap kesilapan yang paling merosakkan paparan dan paling senang
terselit semasa menulis teks Jawi yang panjang:

1. **Huruf Latin dalam medan Jawi** — kesilapan paling ketara. Satu huruf
   Latin dalam ayat Jawi menjadikan ayat itu tidak boleh dibaca, dan ia tidak
   kelihatan dalam pemeriksaan mata yang pantas kerana bentuk hurufnya hampir
   sama pada saiz kecil.
2. **Medan Rumi kosong** — baris Rumi ialah panduan bacaan; soalan tanpa Rumi
   tidak boleh disemak oleh ibu bapa yang belum lancar Jawi.
3. **Markah tidak sepadan** — `bulat`/`objektif`/`betul_salah` mesti ada satu
   markah bagi setiap item; `suai` satu markah bagi setiap pasangan;
   `tempat_kosong` satu markah bagi setiap `____`; `tulis`/`huraian` satu
   markah bagi setiap idea dalam rubrik.
4. **Kunci jawapan hilang atau di luar julat** — setiap soalan mesti ada
   jawapan yang boleh diperiksa mesin.
5. **Bilangan item yang tidak munasabah** untuk bahagian kertas (contohnya
   `objektif` dengan lebih daripada satu item, atau `suai` dengan dua pasangan).

Guna:
    python3 tools/semak_bank.py                 # semak semua fail dalam kerja/bank
    python3 tools/semak_bank.py kerja/bank/x.json
"""

from __future__ import annotations

import json
import os
import re
import sys

AKAR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FOLDER_BANK = os.path.join(AKAR, "kerja", "bank")

# Julat Unicode yang sah untuk tulisan Jawi/Arab, beserta tanda baca yang
# memang digunakan dalam kertas UPKK.
JULAT_JAWI = (
    (0x0600, 0x06FF),  # Arab
    (0x0750, 0x077F),  # Arab tambahan
    (0x08A0, 0x08FF),  # Arab tambahan lanjutan
    (0xFB50, 0xFDFF),  # Bentuk persembahan Arab A
    (0xFE70, 0xFEFF),  # Bentuk persembahan Arab B
)

# Watak bukan Jawi yang dibenarkan dalam medan Jawi.
BENAR_BUKAN_JAWI = set(' \t\n.,;:!?()[]{}<>«»"\'-–—/\\%+=*&@#°’‘“”…\u200f\u200e_')
# Garis bawah dibenarkan kerana penanda tempat kosong dalam bank ialah `____`.
# Tanda betul/salah dan bintang memang tercetak pada kertas UPKK.
BENAR_BUKAN_JAWI |= set('✓✗✔✘★☆●○')
BENAR_DIGIT = set('0123456789٠١٢٣٤٥٦٧٨٩')

# Medan yang mesti ditulis dalam Jawi.
MEDAN_JAWI = ("soalan", "teks", "kiri", "kanan", "arahan")

JENIS_SAH = {
    "bulat", "kariyes", "suai", "padan", "betul_salah", "objektif",
    "tempat_kosong", "susun", "tulis", "huraian", "senarai",
}


# Nombor roman dalam kurungan, seperti `(i)`, `(ii)`, `(iv)`. Kertas UPKK
# memang menggunakannya di dalam arahan Jawi, jadi ia bukan pencemaran.
ROMAWI = re.compile(r"\((?:x{0,3})(?:ix|iv|v?i{0,3})\)", re.IGNORECASE)

# Petikan huruf atau bunyi Latin di dalam «...». Lihat [aksara_asing].
PETIKAN_LATIN = re.compile(r"«[^»]*»")


def sah_jawi(teks: str) -> bool:
    """Adakah setiap huruf dalam [teks] tergolong dalam tulisan Jawi?"""
    return not aksara_asing(teks)


def aksara_asing(teks: str) -> list[str]:
    """Senarai aksara bukan Jawi dalam [teks], tanpa pendua.

    Dua perkara dikecualikan sebelum pemeriksaan, kerana kedua-duanya **sengaja**
    ada dalam kertas Jawi sebenar:

      * nombor roman dalam kurungan — `(i)`, `(ii)`, `(iv)` — yang digunakan
        sebagai penanda bahagian dalam arahan;
      * huruf Latin yang dipetik di dalam «...» — contohnya soalan ejaan yang
        berbunyi "Bunyi «ng» ditulis dengan huruf nga." Petikan itu ialah bahan
        pengajaran, bukan huruf yang terselit tersalah.
    """
    teks = ROMAWI.sub(" ", teks)
    teks = PETIKAN_LATIN.sub(" ", teks)
    keluar = []
    for aksara in teks:
        if aksara in BENAR_BUKAN_JAWI or aksara in BENAR_DIGIT:
            continue
        if aksara.isspace():
            continue
        kod = ord(aksara)
        if any(mula <= kod <= akhir for mula, akhir in JULAT_JAWI):
            continue
        if aksara not in keluar:
            keluar.append(aksara)
    return keluar


class Pemeriksa:
    def __init__(self, laluan: str):
        self.laluan = laluan
        self.nama = os.path.basename(laluan)
        self.ralat: list[str] = []
        self.amaran: list[str] = []
        self.bilangan_bahagian: dict[str, int] = {}
        self.markah_bahagian: dict[str, int] = {}

    # --- Laporan -------------------------------------------------------------

    def ralat_tambah(self, mesej: str) -> None:
        self.ralat.append(mesej)

    def amaran_tambah(self, mesej: str) -> None:
        self.amaran.append(mesej)

    def semak_medan_jawi(self, nilai: object, tempat: str) -> None:
        if not isinstance(nilai, str):
            return
        asing = aksara_asing(nilai)
        if asing:
            self.ralat_tambah(
                f"{tempat}: huruf bukan Jawi {asing!r} dalam teks Jawi: "
                f"{nilai[:60]!r}"
            )

    def semak_medan_rumi(self, nilai: object, tempat: str, jawi: str = "") -> None:
        if not isinstance(nilai, str) or not nilai.strip():
            self.ralat_tambah(f"{tempat}: medan Rumi kosong (Jawi: {jawi[:40]!r})")
            return
        if re.search(r"[ء-ي]", nilai):
            self.amaran_tambah(
                f"{tempat}: medan Rumi mengandungi huruf Arab: {nilai[:60]!r}"
            )

    # --- Semakan satu soalan -------------------------------------------------

    def semak_soalan(self, s: dict, indeks: int) -> None:
        tempat = f"soalan[{indeks}]"
        bahagian = s.get("bahagian", "")
        jenis = s.get("jenis", "")
        if bahagian:
            self.bilangan_bahagian[bahagian] = self.bilangan_bahagian.get(bahagian, 0) + 1

        if jenis not in JENIS_SAH:
            self.ralat_tambah(f"{tempat}: jenis tidak dikenali {jenis!r}")

        teks_soalan = (s.get("soalan") or "").strip()
        self.semak_medan_jawi(s.get("soalan", ""), f"{tempat}.soalan")
        if teks_soalan:
            self.semak_medan_rumi(
                s.get("rumi", ""), f"{tempat}.rumi", teks_soalan
            )
        elif not (s.get("item") or s.get("pasangan") or s.get("urutan")):
            self.ralat_tambah(f"{tempat}: teks soalan kosong dan tiada item")

        item = s.get("item") or []
        pasangan = s.get("pasangan") or []
        bank = s.get("bank") or []
        idea = s.get("idea") or []

        # --- item ---
        for j, it in enumerate(item):
            tempat_item = f"{tempat}.item[{j}]"
            teks_item = (it.get("teks") or "").strip()
            self.semak_medan_jawi(it.get("teks", ""), f"{tempat_item}.teks")
            # Item bagi soalan objektif selalunya kosong: teks penuh sudah ada
            # pada `soalan`, dan item hanya memegang senarai pilihan. Rumi hanya
            # diwajibkan apabila item itu benar-benar dipaparkan.
            if teks_item:
                self.semak_medan_rumi(
                    it.get("rumi", ""), f"{tempat_item}.rumi", teks_item
                )

            pilihan = it.get("pilihan") or []
            for k, p in enumerate(pilihan):
                if isinstance(p, dict):
                    self.semak_medan_jawi(p.get("teks", ""), f"{tempat_item}.pilihan[{k}]")
                    self.semak_medan_rumi(
                        p.get("rumi", ""), f"{tempat_item}.pilihan[{k}].rumi",
                        p.get("teks", ""),
                    )
                elif isinstance(p, str):
                    self.semak_medan_jawi(p, f"{tempat_item}.pilihan[{k}]")

            angka = it.get("jawapan", -1)
            if pilihan:
                dijangka = 4 if jenis == "objektif" else 2 if jenis == "bulat" else 0
                if dijangka and len(pilihan) != dijangka:
                    self.amaran_tambah(
                        f"{tempat_item}: {len(pilihan)} pilihan "
                        f"(biasanya {dijangka} untuk {jenis})"
                    )
                if not (0 <= angka < len(pilihan)):
                    self.ralat_tambah(
                        f"{tempat_item}: indeks jawapan {angka} di luar julat "
                        f"(0..{len(pilihan) - 1})"
                    )
            elif angka != -1:
                self.amaran_tambah(
                    f"{tempat_item}: jawapan={angka} tetapi tiada pilihan"
                )

        # --- kunci mengikut jenis ---
        if jenis == "objektif" and len(item) != 1:
            self.amaran_tambah(
                f"{tempat}: objektif dengan {len(item)} item "
                "(kertas UPKK menggunakan satu soalan satu item)"
            )

        if jenis == "betul_salah":
            if not item:
                self.ralat_tambah(f"{tempat}: betul_salah tanpa item")
            for j, it in enumerate(item):
                if it.get("betul") is None:
                    self.ralat_tambah(f"{tempat}.item[{j}]: medan 'betul' tiada")

        if jenis == "suai":
            if len(pasangan) < 2:
                self.ralat_tambah(f"{tempat}: suai memerlukan sekurang-kurangnya 2 pasangan")
            for j, p in enumerate(pasangan):
                self.semak_medan_jawi(p.get("kiri", ""), f"{tempat}.pasangan[{j}].kiri")
                self.semak_medan_jawi(p.get("kanan", ""), f"{tempat}.pasangan[{j}].kanan")
                self.semak_medan_rumi(
                    p.get("kiriRumi", ""), f"{tempat}.pasangan[{j}].kiriRumi", p.get("kiri", "")
                )
                self.semak_medan_rumi(
                    p.get("kananRumi", ""), f"{tempat}.pasangan[{j}].kananRumi", p.get("kanan", "")
                )
            kanan = [p.get("kanan", "") for p in pasangan]
            if len(set(kanan)) != len(kanan):
                self.amaran_tambah(f"{tempat}: ada lajur kanan yang berulang")

        if jenis == "tempat_kosong":
            kosong = sum((it.get("teks", "") or "").count("____") for it in item)
            if not bank:
                self.ralat_tambah(f"{tempat}: tempat_kosong tanpa bank perkataan")
            if kosong != len(bank):
                self.ralat_tambah(
                    f"{tempat}: {kosong} tempat kosong tetapi {len(bank)} perkataan bank"
                )
            for j, k in enumerate(bank):
                self.semak_medan_jawi(k, f"{tempat}.bank[{j}]")
            bankRumi = s.get("bankRumi") or []
            if bank and len(bankRumi) != len(bank):
                self.ralat_tambah(
                    f"{tempat}: bankRumi {len(bankRumi)} perkataan, bank {len(bank)}"
                )
            if len(set(bank)) != len(bank):
                self.ralat_tambah(f"{tempat}: bank mengandungi perkataan berulang")

        if jenis == "susun":
            urutan = s.get("urutan") or []
            if len(urutan) < 2:
                self.ralat_tambah(f"{tempat}: susun memerlukan sekurang-kurangnya 2 perkataan")
            for j, u in enumerate(urutan):
                self.semak_medan_jawi(u, f"{tempat}.urutan[{j}]")
            if len(set(urutan)) != len(urutan):
                self.ralat_tambah(
                    f"{tempat}: perkataan berulang dalam urutan — PapanSusun "
                    "memerlukan label unik"
                )
            urutanRumi = s.get("urutanRumi") or []
            if urutan and len(urutanRumi) != len(urutan):
                self.ralat_tambah(
                    f"{tempat}: urutanRumi {len(urutanRumi)}, urutan {len(urutan)}"
                )

        # --- markah ---
        if jenis in ("tulis", "huraian"):
            dijangka = len(idea)
            markah = s.get("markah", 0)
            if dijangka == 0:
                self.amaran_tambah(
                    f"{tempat}: {jenis} tanpa rubrik 'idea' — jawapan tidak "
                    "boleh ditanda"
                )
            elif markah != dijangka:
                self.ralat_tambah(
                    f"{tempat}: markah {markah} tetapi rubrik mempunyai {dijangka} idea"
                )
            for j, id in enumerate(idea):
                if not (id.get("maksud") or "").strip():
                    self.ralat_tambah(f"{tempat}.idea[{j}]: maksud idea kosong")
                kata = id.get("kata") or []
                if not kata:
                    self.ralat_tambah(f"{tempat}.idea[{j}]: tiada kata kunci")
        else:
            markah = s.get("markah", 0)
            boleh = {
                "bulat": len(item), "objektif": len(item),
                "betul_salah": len(item), "suai": len(pasangan),
                "tempat_kosong": sum(
                    (it.get("teks", "") or "").count("____") for it in item
                ),
                "susun": len(s.get("urutan") or []),
            }.get(jenis, markah)
            if boleh and markah != boleh:
                self.amaran_tambah(
                    f"{tempat}: markah ditulis {markah}, sepatutnya {boleh} "
                    f"({len(item)} item / {len(pasangan)} pasangan)"
                )

    # --- Semakan fail --------------------------------------------------------

    def semak_fail(self) -> None:
        try:
            with open(self.laluan, encoding="utf-8") as f:
                data = json.load(f)
        except Exception as e:  # noqa: BLE001
            self.ralat_tambah(f"fail tidak dapat dibaca: {e}")
            return

        soalan = data.get("soalan") if isinstance(data, dict) else data
        if not isinstance(soalan, list):
            self.ralat_tambah("medan 'soalan' tiada atau bukan senarai")
            return

        for i, s in enumerate(soalan):
            if not isinstance(s, dict):
                self.ralat_tambah(f"soalan[{i}] bukan objek JSON")
                continue
            self.semak_soalan(s, i)

        id_dilihat: dict[str, int] = {}
        for i, s in enumerate(soalan):
            if isinstance(s, dict) and s.get("id"):
                if s["id"] in id_dilihat:
                    self.ralat_tambah(
                        f"id '{s['id']}' berulang pada soalan[{id_dilihat[s['id']]}] "
                        f"dan soalan[{i}]"
                    )
                id_dilihat[s["id"]] = i

        # Kunci jawapan Bahagian B tidak sepatutnya mengikut corak mudah diteka.
        kunci = [
            s["item"][0].get("jawapan")
            for s in soalan
            if isinstance(s, dict)
            and s.get("jenis") == "objektif"
            and s.get("item")
            and s["item"][0].get("pilihan")
        ]
        if len(kunci) >= 8:
            berturut = sum(1 for a, b in zip(kunci, kunci[1:]) if a == b)
            if berturut > len(kunci) * 0.3:
                self.amaran_tambah(
                    f"Bahagian B: {berturut} kunci berturut-turut sama — "
                    "mudah diteka"
                )

    def laporkan(self) -> bool:
        jumlah = sum(self.bilangan_bahagian.values())
        print(f"\n=== {self.nama} — {jumlah} soalan ===")
        if self.bilangan_bahagian:
            pecahan = ", ".join(
                f"{k}: {v}" for k, v in sorted(self.bilangan_bahagian.items())
            )
            print(f"  bahagian: {pecahan}")
        if self.ralat:
            print(f"  RALAT ({len(self.ralat)}):")
            for m in self.ralat:
                print(f"    ✗ {m}")
        if self.amaran:
            print(f"  amaran ({len(self.amaran)}):")
            for m in self.amaran[:20]:
                print(f"    ! {m}")
            if len(self.amaran) > 20:
                print(f"    … dan {len(self.amaran) - 20} amaran lagi")
        if not self.ralat and not self.amaran:
            print("  ✓ bersih")
        return not self.ralat


def main() -> int:
    if len(sys.argv) > 1:
        fail = sys.argv[1:]
    else:
        if not os.path.isdir(FOLDER_BANK):
            print(f"Folder bank tidak dijumpai: {FOLDER_BANK}")
            return 1
        fail = sorted(
            os.path.join(FOLDER_BANK, n)
            for n in os.listdir(FOLDER_BANK)
            if n.endswith(".json") and not n.startswith("_")
        )

    if not fail:
        print("Tiada fail bank untuk diperiksa.")
        return 0

    semua_ok = True
    jumlah_ralat = 0
    for laluan in fail:
        p = Pemeriksa(laluan)
        p.semak_fail()
        if not p.laporkan():
            semua_ok = False
        jumlah_ralat += len(p.ralat)

    print()
    print(f"Fail diperiksa: {len(fail)}")
    print(f"Jumlah ralat: {jumlah_ralat}")
    print("SEMUA LULUS" if semua_ok else "ADA RALAT — perlu dibetulkan")
    return 0 if semua_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
