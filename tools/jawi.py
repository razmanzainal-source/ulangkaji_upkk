"""Peraturan ejaan Jawi untuk menyemak kandungan app.

Fail ini **bukan** penjana kandungan. Ia menyemak ejaan yang sudah ada, dan
hanya melaporkan — pembetulan dibuat dalam fail bank selepas disemak manusia.

Sebab ia wujud: teks Jawi dalam bank ditulis oleh model bahasa, dan model
bahasa boleh menghasilkan ejaan yang *kelihatan* betul tetapi salah pada satu
dua huruf. Kesilapan itu tidak kelihatan kepada pembaca yang belum lancar
Jawi, tetapi ia diajar kepada murid — jadi ia mesti ditangkap secara
sistematik, bukan dengan mata.

Peraturan yang disemak di sini ialah peraturan yang **tidak boleh dipertikaikan**
dalam ejaan Jawi Melayu:

    /p/  = ڤ      /g/  = ݢ      /ng/ = ڠ      /ny/ = ڽ
    /c/  = چ      /v/  = ۏ      /k/  = ک      /f/  = ف

Huruf Arab (ث ذ ص ض ط ظ ع ة ى ؤ ئ أ إ) hanya sah dalam kata pinjaman Arab.
Alif hanya ditulis bagi /a/ dalam suku kata terbuka; suku kata tertutup tidak
menerima alif (`makan` = ماکن, `kambing` = کمبيڠ).
"""

from __future__ import annotations

import re

# Harakat, tasydid, sukun, tatweel — dibuang sebelum semakan.
_HARAKAT = dict.fromkeys(
    map(
        ord,
        "\u064B\u064C\u064D\u064E\u064F\u0650\u0651\u0652\u0653\u0654\u0655"
        "\u0670\u0640",
    ),
    None,
)

# Tanda baca yang boleh melekat pada perkataan.
_TANDA = re.compile(r"[\u060C\u061B\u061F.,!?؟:;\"'()\[\]«»–—\-…_]")

# Huruf yang hanya muncul dalam kata pinjaman Arab.
ARAB_SAHAJA = set("ثذصضطظعةىؤئأإ")

# Huruf Arab yang sering tersalah guna untuk bunyi Melayu.
SALAH_HURUF = {
    "\u0643": ("ک", "kaf Arab (ك) — Jawi Melayu guna ک"),
    "\u06AF": ("ݢ", "gaf Parsi (گ) — Jawi Melayu guna ݢ"),
    "\u067E": ("ڤ", "peh Parsi (پ) — Jawi Melayu guna ڤ"),
    "\u06CC": ("ي", "yeh Parsi (ی) — Jawi Melayu guna ي"),
}

# Pemetaan bunyi Melayu → huruf Jawi yang wajib ada.
_WAJIB = [
    ("p", "ڤ", "p"),
    ("g", "ݢ", "g"),
    ("ng", "ڠ", "ng"),
    ("ny", "ڽ", "ny"),
    ("c", "چ", "c"),
    ("v", "ۏ", "v"),
]


def normalisasi(teks: str) -> str:
    """Buang harakat, tatweel dan tanda baca; kembalikan token tunggal."""
    teks = teks.translate(_HARAKAT)
    teks = _TANDA.sub("", teks)
    return teks.strip()


def token_jawi(teks: str) -> list[str]:
    """Pecahkan teks Jawi kepada token (tanda baca dibuang)."""
    teks = teks.translate(_HARAKAT)
    teks = _TANDA.sub(" ", teks)
    return [t for t in teks.split() if t]


def token_rumi(teks: str) -> list[str]:
    """Pecahkan teks Rumi kepada token huruf kecil."""
    return [t.lower() for t in re.findall(r"[A-Za-z][A-Za-z'’-]*", teks)]


def _bunyi(rumi: str) -> dict[str, int]:
    """Kira bunyi yang perlu ada dalam ejaan Jawi bagi satu perkataan Rumi."""
    r = rumi.lower()
    kira: dict[str, int] = {}
    for bunyi, _huruf, nama in _WAJIB:
        # 'ng' dan 'ny' dikira sebagai satu bunyi; 'g' dalam 'ng' tidak dikira.
        if bunyi == "g":
            n = len(re.findall(r"g(?!h)", r.replace("ng", "")))
        elif bunyi == "ny":
            n = r.count("ny")
            # Akar "sembunyi" dieja سمبوني dengan ني, bukan ڽ. Hanya satu /ny/
            # yang perlu ڽ (contohnya "menyembunyikan" = مڽمبونيکن).
            if "sembunyi" in r:
                n -= 1
        elif bunyi == "ng":
            n = r.count(bunyi)
        else:
            n = r.count(bunyi)
        if n:
            kira[nama] = n
    return kira


def semak(rumi: str, jawi: str, kata_pinjaman: set[str]) -> list[str]:
    """Kembalikan senarai masalah bagi satu pasangan (rumi, jawi).

    [kata_pinjaman] ialah set perkataan Rumi yang memang berasal daripada Arab;
    perkataan itu dikecualikan daripada semakan huruf Arab-sahaja.
    """
    masalah: list[str] = []
    j = normalisasi(jawi)
    r = rumi.lower().strip()
    if not j or not r:
        return masalah

    for salah, (betul, sebab) in SALAH_HURUF.items():
        if salah in j:
            masalah.append(f"huruf {sebab}")

    for bunyi, huruf, nama in _WAJIB:
        perlu = _bunyi(r).get(nama, 0)
        if perlu and j.count(huruf) < perlu:
            masalah.append(f"bunyi /{bunyi}/ tiada {huruf}")

    if r in kata_pinjaman:
        return masalah

    # Kata Melayu asli tidak menggunakan huruf Arab sahaja.
    asing = sorted(set(j) & ARAB_SAHAJA)
    # 'ة' dibenarkan pada kata seperti 'rakaat', 'nikmat'? Tidak — Jawi Melayu
    # menulis ه. Semua huruf dalam senarai ini dilaporkan.
    if asing:
        masalah.append("huruf Arab dalam kata Melayu: " + " ".join(asing))

    return masalah


def baca_pinjaman(laluan: str) -> set[str]:
    """Baca senarai kata pinjaman Arab (satu perkataan setiap baris)."""
    try:
        with open(laluan, encoding="utf-8") as f:
            return {
                baris.strip().lower()
                for baris in f
                if baris.strip() and not baris.startswith("#")
            }
    except FileNotFoundError:
        return set()
