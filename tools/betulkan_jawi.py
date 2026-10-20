#!/usr/bin/env python3
"""Betulkan ejaan Jawi dalam bank soalan.

Setiap pembetulan di bawah disemak terhadap dua sumber:

  1. **Peraturan ejaan Jawi** (`tools/jawi.py`) — huruf yang tidak boleh
     dipertikaikan (`ڤ` untuk /p/, `ڠ` untuk /ng/, `ڽ` untuk /ny/, `ݢ` untuk
     /g/, `چ` untuk /c/, `ک` untuk /k/).
  2. **Kertas UPKK sebenar 2024/2025** yang diimbas dalam `assets/kertas/` —
     ejaan yang digunakan oleh lembaga peperiksaan, contohnya `اياله`,
     `انتارا`, `ڤرکارا`, `برايکوت`, `صلاة`.

Dua jadual digunakan:

  * `GLOBAL` — ejaan yang **tidak pernah betul** dalam konteks app ini, jadi ia
    boleh diganti di mana-mana sahaja.
  * `PASANGAN` — ejaan yang betul bagi satu perkataan tetapi mungkin betul bagi
    perkataan lain; ia hanya diganti apabila pasangan Rumi-nya sepadan.

Penggunaan:
    python3 tools/betulkan_jawi.py --semak     # tunjuk apa yang akan berubah
    python3 tools/betulkan_jawi.py             # tulis perubahan
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import jawi  # noqa: E402

AKAR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BANK = os.path.join(AKAR, "assets", "content", "bank")

# Ejaan salah → ejaan betul. Selamat diganti tanpa melihat Rumi.
GLOBAL: dict[str, str] = {
    # /p/ ditulis ڤ, bukan ف
    "کفد": "کڤد",
    "سلفس": "سلڤس",
    "سلفسڽ": "سلڤسڽ",
    "باف": "باڤ",
    "فيوتيه": "ڤوتيه",
    "ڤوتي": "ڤوتيه",
    "ڤوته": "ڤوتيه",
    "فينسيل": "ڤينسيل",
    "ڤنسيل": "ڤينسيل",
    "فارس": "ڤرسي",
    "چوکو": "چوکوڤ",
    "اوفايا": "اوڤاي",
    "دجوموت": "دجومڤوت",
    "سيافاکه": "سياڤاکه",
    "کواسا": "کماڤوان",
    # /ng/ ditulis ڠ, bukan غ
    "تاغن": "تاڠن",
    "تاعن": "تاڠن",
    "توغکل": "توڠݢل",
    "بينتن": "بينتڠ",
    "بيتڠ": "بينتڠ",
    "بينتاڠ": "بينتڠ",
    "سياء": "سيڠ",
    "سنت": "سنڠ",
    "کينچي": "کنچيڠ",
    "اينݢين": "ايڠين",
    "بربالق": "ڤولڠ",
    "کتنترمن": "کتنڠن",
    "کمنأڠن": "کمنڠن",
    "ممݢنتيکن": "مڠݢنتيکن",
    "ترڠݢو": "ترݢڠݢو",
    # /ny/ ditulis ڽ
    "نياتکن": "ڽاتاکن",
    "ستيائڤ": "ستياڤ",
    "ستياف": "ستياڤ",
    "مڠمباکن": "مڽمڤايکن",
    "مڠياڤ": "مڽاڤو",
    "مڠساڤ": "مڽاڤو",
    "مڠسوروهکن": "مڽوروهکن",
    "مڽمبونييکن": "مڽمبونيکن",
    "مڠيڠݢکن": "مڽيمڤن",
    "ڤرسيمڤنن": "ڤرسيمڤنن",
    "برسيمڤن": "برسيمڤني",
    "مونيت": "موڽيت",
    "مڠونيڠ": "مڠوڽه",
    "بيلڠن": "بيلڠڽ",
    # /g/ ditulis ݢ, bukan ک atau گ atau غ
    "کورو": "ݢورو",
    "ݢرو": "ݢورو",
    "ݢورور": "ݢورو",
    "بکيندا": "بݢيندا",
    "انگک": "اڠک",
    "برکأندهق": "برکهندق",
    # /c/ ditulis چ
    "کوجيڠ": "کوچيڠ",
    "کوسيڠ": "کوچيڠ",
    "کوچڠ": "کوچيڠ",
    "ترݢلينق": "ترݢلينچير",
    "چاءير": "چچاءير",
    "هرقل": "هرکوليس",
    # kaf Melayu (ک) bukan kaf Arab (ك)
    "ڤركاتاءن": "ڤرکاتاءن",
    "برايكوت": "برايکوت",
    "كتاب": "کتاب",
    "بانك": "بڠک",
    "سوكر": "سوکر",
    "توكر": "توکر",
    "بوكيت": "بوکيت",
    "دباليك": "دبالک",
    "مالك": "مالک",
    "منكر": "منکر",
    "نكير": "ناکير",
    "ربك": "ربک",
    "تبوك": "تابک",
    "شكرا": "شکرا",
    "يكتب": "يکتب",
    "تسكن": "تسکن",
    "كل": "کل",
    "بك": "بک",
    "كتابي": "کتابي",
    "نفسك": "نفسک",
    "جوابك": "جوابک",
    "اسمك": "اسمک",
    "كيف": "کيف",
    "حالك": "حالک",
    "كبير": "کبير",
    "الكلب": "الکلب",
    "البنك": "البنک",
    "الكتاب": "الکتاب",
    "الكرسي": "الکرسي",
    "المكان": "المکان",
    "الفواكه": "الفواکه",
    "الديك": "الديک",
    "السمك": "السمک",
    "كلام": "کلام",
    "كلامه": "کلامه",
    "حكمه": "حکمه",
    "كلمة": "کليمه",
    "ميكائيل": "ميکائيل",
    "شيريك": "شريک",
    "بركوربان": "برکوربن",
    # Pinjaman Arab: Jawi Melayu membuang hamzah awal
    "إسلام": "اسلام",
    "إمام": "امام",
    "أذان": "اذان",
    "أحمد": "احمد",
    "أحد": "احد",
    "إنجيل": "انجيل",
    "إحرام": "احرام",
    "إسرافيل": "اسرافيل",
    "إقامة": "اقامه",
    "أمانة": "امانه",
    "امانة": "امانه",
    "أمانه": "امانه",
    "هجرة": "هجره",
    "مكة": "مکه",
    "مکة": "مکه",
    "مدينة": "مدينه",
    "برجماعة": "برجماعه",
    "کليمة": "کليمه",
    "داؤد": "داود",
    "إذا": "جک",
    "کأوم": "قوم",
    # Ejaan salah lain yang tidak boleh dipertikaikan
    "اداله": "اياله",
    "مسجيد": "مسجد",
    "داري": "دري",
    "تيدا": "تيدق",
    "ادا": "اد",
    "ماکان": "ماکن",
    "مکان": "ماکن",
    "ماچن": "ماکن",
    "دسوبت": "دسبوت",
    "دسي بوت": "دسبوت",
    "دسيبوت": "دسبوت",
    "ديسبوت": "دسبوت",
    "لاءين": "لاين",
    "هوايکن": "هوارايکن",
    "انتار": "انتارا",
    "ملائكة": "ملايکة",
    "اينم": "انم",
    "نم": "انم",
    "بائيک": "باءيق",
    "بايق": "باءيق",
    "کباءيکن": "کباءيقن",
    "دجݢ": "دجاݢ",
    "ممبهرسيکن": "ممبرسيهکن",
    "ممبريسهکن": "ممبرسيهکن",
    "مڠسيهي": "مڠاسيهي",
    "ملاڤکن": "ملوڤاکن",
    "مڠمبيل": "مڠامبيل",
    "دڤرچاءاي": "دڤرچاي",
    "رکنڽ": "راکنڽ",
    "ليوات": "لوات",
    "قديم": "قيدم",
    "راقيب": "رقيب",
    "لبيب": "لبه",
    "اداڤنڽ": "ادبڽ",
    "هوشڤيتل": "هوسڤيتل",
    "کلس": "کلاس",
    "هريماو": "هاريماو",
    "لاڤظ": "لفظ",
    "بلا": "بولا",
    "کدو": "کدوا",
    "کدا": "کدوا",
    "سسو": "سوسو",
    "شوسو": "سوسو",
    "سوسوو": "سوسو",
    "دو": "دوا",
    "ڤرپاتاءن": "ڤرڽاتاءن",
    "ڤتاتاءن": "ڤرڽاتاءن",
    "ڤرڤاتاءن": "ڤرڽاتاءن",
    "ڤرکات": "ڤرکاتاءن",
    "کايتن": "کاءيتن",
    "باءيت": "باءيت",
    "ووقد": "وقوف",
    "بردوءا": "بردعاء",
    "منريما": "منريم",
    "تند": "تندا",
    "ليما": "ليم",
}

# (rumi, ejaan salah) → ejaan betul. Hanya digunakan apabila pasangan sepadan.
PASANGAN: dict[tuple[str, str], str] = {
    ("perkataan", "ڤرکات"): "ڤرکاتاءن",
    ("pernyataan", "ڤرپاتاءن"): "ڤرڽاتاءن",
    ("pernyataan", "ڤتاتاءن"): "ڤرڽاتاءن",
    ("pernyataan", "ڤرڤاتاءن"): "ڤرڽاتاءن",
    ("ialah", "اداله"): "اياله",
    ("lima", "ليما"): "ليم",
    ("tiga", "٣"): "تيݢ",
    ("empat", "٤"): "امڤت",
    ("enam", "٦"): "انم",
    ("sembilan", "٩"): "سمبيلن",
    ("betul", "✓"): "بتول",
    ("salah", "✗"): "ساله",
    ("guru", "کورو"): "ݢورو",
    ("guru", "ݢرو"): "ݢورو",
    ("guru", "ݢورور"): "ݢورو",
    ("guru", "____"): "ݢورو",
    ("bapa", "باف"): "باڤ",
    ("tangan", "تاغن"): "تاڠن",
    ("tangan", "تاعن"): "تاڠن",
    ("kepada", "ک"): "کڤد",
    ("dalam", "ددالم"): "ددالم",
    ("di", "د"): "د",
    ("kucing", "کوجيڠ"): "کوچيڠ",
    ("kambing", "کبي"): "کمبيڠ",
    ("monyet", "مونيت"): "موڽيت",
    ("putih", "فيوتيه"): "ڤوتيه",
    ("tunggal", "توغکل"): "توڠݢل",
    ("menyampaikan", "مڠمباکن"): "مڽمڤايکن",
    ("sebanyak", "سبݢاي"): "سباڽق",
    ("disebut", "دسوبت"): "دسبوت",
    ("disebut", "ديسبوت"): "دسبوت",
    ("disebut", "دسيبوت"): "دسبوت",
    ("islam", "إسلام"): "اسلام",
    ("imam", "إمام"): "امام",
    ("azan", "أذان"): "اذان",
    ("uhud", "أحد"): "احد",
    ("ahmad", "أحمد"): "احمد",
    ("injil", "إنجيل"): "انجيل",
    ("ihram", "إحرام"): "احرام",
    ("israfil", "إسرافيل"): "اسرافيل",
    ("iqamah", "إقامة"): "اقامه",
    ("amanah", "أمانة"): "امانه",
    ("amanah", "امانة"): "امانه",
    ("amanah", "أمانه"): "امانه",
    ("hijrah", "هجرة"): "هجره",
    ("berhijrah", "هجرة"): "هجره",
    ("mekah", "مكة"): "مکه",
    ("mekah", "مکة"): "مکه",
    ("madinah", "مدينة"): "مدينه",
    ("berjemaah", "برجماعة"): "برجماعه",
    ("kalimah", "كلمة"): "کليمه",
    ("kalimah", "کليمة"): "کليمه",
    ("daud", "داؤد"): "داود",
    ("kaum", "کأوم"): "قوم",
    ("kemenangan", "کمنأڠن"): "کمنڠن",
    ("berkehendak", "برکأندهق"): "برکهندق",
    ("masjid", "مسجيد"): "مسجد",
    ("ialah", "اياله"): "اياله",
    ("pergi", "ݢي"): "ڤرݢي",
    ("mengambil", "مڠمبيل"): "مڠامبيل",
    ("mengunyah", "مڠونيڠ"): "مڠوڽه",
    ("persembunyian", "ڤرسيمڤنن"): "ڤرسيمڤنن",
    ("bersembunyi", "برسيمڤن"): "برسيمڤني",
    ("bilangannya", "بيلڠن"): "بيلڠڽ",
    ("menggantikan", "ممݢنتيکن"): "مڠݢنتيکن",
    ("ketenangan", "کتنترمن"): "کتنڠن",
    ("terganggu", "ترڠݢو"): "ترݢڠݢو",
    ("cukup", "چوکو"): "چوکوڤ",
    ("cecair", "چاءير"): "چچاءير",
    ("tergelincir", "ترݢلينق"): "ترݢلينچير",
    ("siapakah", "سيافاکه"): "سياڤاکه",
    ("dijemput", "دجوموت"): "دجومڤوت",
    ("upaya", "اوفايا"): "اوڤاي",
    ("kemampuan", "کواسا"): "کماڤوان",
    ("penjaga", "منجاݢ"): "ڤنجاݢ",
    ("persi", "فارس"): "ڤرسي",
    ("parsi", "فارس"): "ڤرسي",
    ("sah", "سح"): "صح",
    ("lafaz", "لاڤظ"): "لفظ",
    ("maksud", "مكسود"): "مقصود",
    ("mutlak", "مطلق"): "مطلق",
    ("wukuf", "ووقد"): "وقوف",
    ("seseorang", "سأورڠ"): "سسأورڠ",
    ("naik", "نايق"): "ناءيق",
    ("harimau", "هريماو"): "هاريماو",
    ("bola", "بلا"): "بولا",
    ("gigi", "ݢݢي"): "ݢيݢي",
    ("nasi", "نسي"): "ناسي",
    ("roti", "رتي"): "روتي",
    ("meja", "مجا"): "ميجا",
    ("kelas", "کلس"): "کلاس",
    ("membatalkan", "ممبطلكن"): "ممبطلکن",
    ("sebanyak", "سبݢاي"): "سباڽق",
    ("pernyataan", "ڤرکاتاءن"): "ڤرڽاتاءن",
    ("bunyi", "بونيي"): "بوڽي",
    ("gantang", "ݢنتن"): "ݢنتڠ",
    ("penjaga", "منجاݢ"): "ڤنجاݢ",
    ("bilangannya", "بيلاڠن"): "بيلڠڽ",
    ("ikan", "ايكت"): "ايکن",
    ("pergi", "ݢي"): "ڤرݢي",
    ("persembunyian", "ڤرسيمڤنن"): "ڤرسيمڤنن",
    ("bersembunyi", "برسيمڤني"): "برسمبوني",
    ("membatalkan", "ممبطلكن"): "ممبطلکن",
    ("tiada", "تيدق"): "تياد",
    ("seseorang", "سأورڠ"): "سسأورڠ",
    ("sebahagian", "بهاݢين"): "سبهاݢين",
    ("daripada", "دري"): "درڤد",
    ("kepada", "ک"): "کڤد",
    ("bunyi", "بونيي"): "بوڽي",
    ("persembunyian", "ڤرسيمڤنن"): "ڤرسيمڤنن",
    ("bersembunyi", "برسيمڤني"): "برسمبوني",
    ("pergi", "ݢي"): "ڤرݢي",
    ("bagi", "بݢي"): "باݢي",
    ("puasa", "ڤواس"): "ڤواسا",
    ("digunakan", "ديݢوناکن"): "دݢوناکن",
    ("sebagai", "سبݢاي"): "سباݢاي",
    ("makanan", "ماکن"): "ماکنن",
    ("rakan", "رکن"): "راکن",
    ("ikan", "اکن"): "ايکن",
    ("tempat", "تيمڤت"): "تمڤت",
    ("rukun", "رکون"): "رکن",
    ("air", "اءير"): "اير",
    ("ulat", "اوله"): "اولت",
    ("mengikuti", "مڠيکوت"): "مڠيکوتي",
    ("bilangannya", "بيلاڠن"): "بيلڠڽ",
}

# Ejaan yang tidak bergantung pada maksud — salah dalam semua konteks.
GLOBAL.update({
    "أكبر": "اكبر",
    "هاث": "هاڽ",
    "ڤرسيمڤنن": "ڤرسمبونين",
    "ڤنجنترا": "ڤنچادڠ",
    "برسمبوني": "برسمبوڽي",
    "برسمبونيي": "برسمبوڽي",
})

GLOBAL.update({
    # --- pusingan kedua: ejaan kanonik selepas semakan kertas sebenar ---
    "برايکن": "بريکن",
    "سبلاوم": "سبلوم",
    "بولةکن": "بولتکن",
    "حکمة": "حکمه",
    "مڽمبونيکن": "مڽمبوڽيکن",
    "بکو": "بوکو",
    "بواکو": "بوکو",
    "بوکوا": "بوکو",
    "کوچيل": "کچيل",
    "لڤن": "لاڤن",
    "بتو": "باتو",
    "ماندي": "مندي",
    "تامو": "تتامو",
    "سکولا": "سکوله",
    "سکولح": "سکوله",
    "سکولاه": "سکوله",
    "موريک": "موريد",
    "شرݢ": "شورݢ",
    "منچاتت": "منچتت",
    "بيلڠڽ": "بيلاڠن",
    "ايکو": "ايکن",
    "جيران": "جيرن",
    "ترنم": "تربنم",
    "سيدتينا": "سيتي",
    "برجالان": "برجالن",
    "لالکي": "للاکي",
    "لاکي": "للاکي",
    "اقامة": "اقامه",
    "نايق": "ناءيق",
    "کاءوم": "قوم",
    "کبيڠ": "کمبيڠ",
    "کامبيڠ": "کمبيڠ",
    "موطلق": "مطلق",
    "دسنةکن": "دسنتکن",
    "درجه": "درجت",
    "حديبية": "هدايبه",
    "ستياس": "سنتياس",
    "دݢالکن": "دݢالقکن",
    "ماءنا": "مقصود",
    "مکسود": "مقصود",
    "ترواخير": "تراخير",
    "سساورڠ": "سسأورڠ",
    "ڤينسيله": "ڤينسيل",
    "اولط": "اولت",
    "اولث": "اولت",
    "هيجو": "هيجاو",
    "هيجا": "هيجاو",
    "هيجاوو": "هيجاو",
    "مڠرجاءکن": "مڠرجاکن",
    "اڤال": "اول",
    "برکايتن": "برکاءيتن",
    "واڠ": "واءڠ",
    "دجاءوهي": "دجاوهي",
    "دمولاءي": "دمولاکن",
    "کوت": "کوات",
    "دچمڤور": "دچامڤور",
    "تليسن": "توليسن",
    "ساتوس": "سيراتوس",
    "سلاولو": "سلالو",
    "نينيق": "نيني",
    "مڠڠکت": "مڠاڠکت",
    "برمولى": "برمولا",
    "ممڤوڽائي": "ممڤوڽاءي",
})


def _pecah(teks: str) -> list[str]:
    """Pecahkan teks kepada perkataan dan pemisah (pemisah dikekalkan)."""
    keluar: list[str] = []
    semasa = ""
    for ch in teks:
        if ch.isspace() or ch in "،؛؟.,!?؟:;\"'()[]«»–—-…":
            if semasa:
                keluar.append(semasa)
                semasa = ""
            keluar.append(ch)
        else:
            semasa += ch
    if semasa:
        keluar.append(semasa)
    return keluar


SEPARATOR = set("،؛؟.,!?؟:;\"'()[]«»–—-…_ ")


def _betulkan(teks: str, rumi: str | None) -> tuple[str, int]:
    """Betulkan satu teks Jawi; kembalikan (teks baharu, bilangan perubahan).

    Apabila [rumi] diberi dan bilangan perkataannya sepadan, setiap perkataan
    Jawi dipadankan dengan perkataan Rumi di kedudukan yang sama. Pemadanan ini
    penting untuk pembetulan yang bergantung pada maksud: `ڤرکاتاءن` betul bagi
    "perkataan" tetapi salah bagi "pernyataan".
    """
    if not teks:
        return teks, 0

    bahagian = _pecah(teks)
    indeks = [
        i
        for i, b in enumerate(bahagian)
        if len(b) > 1 and not all(ch in SEPARATOR for ch in b)
    ]
    rw = jawi.token_rumi(rumi or "")
    pasangan: list[str | None] = (
        list(rw) if len(rw) == len(indeks) else [None] * len(indeks)
    )

    # Ayat yang bilangan perkataannya berbeza (contohnya "di dalam" ditulis
    # "ددالم") tidak boleh dipadankan mengikut kedudukan. Dalam kes itu,
    # padanan dicari mengikut kehadiran perkataan Rumi di dalam ayat.
    longgar = len(rw) != len(indeks)
    set_rumi = set(rw)

    tukar = 0
    for i, r in zip(indeks, pasangan):
        asal = jawi.normalisasi(bahagian[i])
        baharu = GLOBAL.get(asal)
        if baharu is None and r:
            baharu = PASANGAN.get((r, asal))
        if baharu is None and longgar:
            for (rr, jj), betul in PASANGAN.items():
                if jj == asal and rr in set_rumi:
                    baharu = betul
                    break
        if baharu and baharu != asal:
            bahagian[i] = bahagian[i].replace(asal, baharu, 1)
            tukar += 1
    return "".join(bahagian), tukar


def _jalan(tulis: bool) -> int:
    jumlah = 0
    fail_berubah = 0
    for fail in sorted(glob.glob(os.path.join(BANK, "*.json"))):
        with open(fail, encoding="utf-8") as f:
            data = json.load(f)
        berubah = 0

        for s in data.get("soalan") or []:
            baharu, n = _betulkan(s.get("soalan", ""), s.get("rumi", ""))
            if n:
                s["soalan"] = baharu
                berubah += n
            for it in s.get("item") or []:
                baharu, n = _betulkan(it.get("teks", ""), it.get("rumi", ""))
                if n:
                    it["teks"] = baharu
                    berubah += n
                for p in it.get("pilihan") or []:
                    if not isinstance(p, dict):
                        continue
                    baharu, n = _betulkan(p.get("teks", ""), p.get("rumi", ""))
                    if n:
                        p["teks"] = baharu
                        berubah += n
            for p in s.get("pasangan") or []:
                baharu, n = _betulkan(p.get("kiri", ""), p.get("kiriRumi", ""))
                if n:
                    p["kiri"] = baharu
                    berubah += n
                baharu, n = _betulkan(p.get("kanan", ""), p.get("kananRumi", ""))
                if n:
                    p["kanan"] = baharu
                    berubah += n
            for m in ("bank", "urutan"):
                for i, teks in enumerate(s.get(m) or []):
                    rumi_senarai = s.get(f"{m}Rumi") or []
                    guna = rumi_senarai[i] if i < len(rumi_senarai) else ""
                    baharu, n = _betulkan(teks, guna)
                    if n:
                        s[m][i] = baharu
                        berubah += n

        if berubah:
            fail_berubah += 1
            jumlah += berubah
            nama = os.path.basename(fail)
            print(f"{nama:14} {berubah} pembetulan")
            if tulis:
                with open(fail, "w", encoding="utf-8") as f:
                    json.dump(data, f, ensure_ascii=False, indent=1)
                    f.write("\n")
    print(f"\n{jumlah} pembetulan dalam {fail_berubah} fail")
    if not tulis:
        print("(larian semakan — tiada fail diubah; jalankan tanpa --semak)")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--semak", action="store_true", help="jangan tulis fail")
    args = ap.parse_args()
    return _jalan(tulis=not args.semak)


if __name__ == "__main__":
    raise SystemExit(main())
