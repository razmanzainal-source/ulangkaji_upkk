#!/usr/bin/env python3
"""Tambah rubrik kata kunci pada soalan jawapan bertulis (kertas sebenar).

Setiap isi = satu `Idea`. Murid mendapat markah apabila **mana-mana** kata
kunci dalam senarai isi itu muncul dalam jawapannya. Kata kunci boleh
mengandungi beberapa perkataan — semuanya mesti ada (susunan bebas).

Perhatian: enjin mengabaikan perkataan kurang daripada 4 huruf, jadi kata
kunci pendek tidak akan pernah sepadan.
"""
import json
import pathlib

# id -> (markah, [(maksud, [kata kunci...]), ...])
RUBRIK = {
    # ---------- ADAB ----------
    "adab-2025-d1-p3": (2, [
        ("membentuk peribadi", ["ممبنتوق", "membentuk"]),
        ("akhlak yang mulia", ["اخلاق", "akhlak"]),
    ]),
    "adab-2025-d2-p3": (2, [
        ("memberi imej buruk", ["ايميج", "imej", "بوروق", "buruk"]),
        ("kepada diri sendiri", ["سنديري", "sendiri", "ديري", "diri"]),
    ]),
    # ---------- AKIDAH ----------
    "akidah-2024-c5-p2": (1, [
        ("berusaha / berikhtiar / bertawakal / reda",
         ["برأوسها", "berusaha", "براختيار", "berikhtiar",
          "برتوكل", "bertawakal", "رضا", "reda", "كتنتوان", "ketentuan"]),
    ]),
    "akidah-2024-d4-p1": (2, [
        ("nikmat yang diterima", ["نعمت", "nikmat", "دتريما", "diterima"]),
        ("semakin berkurang", ["سماکين", "semakin", "برکورݢ", "berkurang"]),
    ]),
    # ---------- BAHASA ARAB ----------
    "arab-2024-d4-p1": (4, [
        ("kata kerja يلعب", ["يلعب"]),
        ("objek الكرة", ["الكرة"]),
        ("tempat الملعب", ["الملعب"]),
    ]),
    "arab-2024-d4-p2": (1, [
        ("الشوكة على الصحن", ["الشوكة", "الصحن"]),
    ]),
    "arab-2024-d4-p3": (1, [
        ("جلس أب على الكرسي", ["الكرسي"]),
    ]),
    "arab-2024-d6-p1": (4, [
        ("kata kerja يلعب", ["يلعب"]),
        ("objek الكرة", ["الكرة"]),
        ("tempat الملعب", ["الملعب"]),
    ]),
    "arab-2024-d6-p2": (1, [
        ("حديقة الحيوانات", ["حديقة", "الحيوانات"]),
    ]),
    "arab-2024-d6-p3": (1, [
        ("جلس أب على الكرسي", ["الكرسي"]),
    ]),
    "arab-2025-d4-p1": (4, [
        ("kata kerja يلعب", ["يلعب"]),
        ("objek الكرة", ["الكرة"]),
        ("tempat الملعب", ["الملعب"]),
    ]),
    "arab-2025-d4-p2": (1, [
        ("الفراشة كثيرة في الحديقة", ["الفراشة", "كثيرة", "الحديقة"]),
    ]),
    "arab-2025-d6-p1": (4, [
        ("kata kerja يلعب", ["يلعب"]),
        ("objek الكرة", ["الكرة"]),
        ("tempat الملعب", ["الملعب"]),
    ]),
    "arab-2025-d6-p2": (1, [
        ("الفراشة كثيرة في الحديقة", ["الفراشة", "كثيرة", "الحديقة"]),
    ]),
    "arab-2025-d7-p1": (4, [
        ("kata kerja يلعب", ["يلعب"]),
        ("objek الكرة", ["الكرة"]),
        ("tempat الملعب", ["الملعب"]),
    ]),
    "arab-2025-d7-p2": (1, [
        ("الفراشة كثيرة في الحديقة", ["الفراشة", "كثيرة", "الحديقة"]),
    ]),
    # ---------- IBADAH ----------
    "ibadah-2024-d3-p1": (1, [
        ("solat Zohor tiada khutbah", ["ظهر", "خطبة"]),
    ]),
    "ibadah-2024-d3-p2": (1, [
        ("solat Jumaat didahului khutbah", ["جمعة", "خطبة"]),
    ]),
    "ibadah-2024-d6-p1": (1, [
        ("hukum tidak sah", ["تيدق", "tidak", "صح"]),
    ]),
    "ibadah-2024-d6-p2": (1, [
        ("solat jamak pada waktu yang sama", ["صلاة", "وقتو"]),
    ]),
    "ibadah-2025-d9": (1, [
        ("solat sunat dhuha dua rakaat", ["ضحى", "ركعة", "صلاة", "dhuha"]),
    ]),
    "ibadah-2025-d10": (2, [
        ("matahari terbit", ["ماتاهاري", "matahari", "تربيت", "terbit"]),
        ("satu kali tinggi", ["سقدر", "ساتو", "كاله", "تيغكي"]),
    ]),
    # ---------- JAWI ----------
    "jawi-2024-d2": (6, [
        ("kata nama dalam ayat", ["سڤيتل", "سوءيس", "كومڤيوتر", "komputer"]),
        ("kata kerja atau sifat", ["ساڠت", "sangat", "بسر", "توتوڤ"]),
    ]),
    "jawi-2024-d4": (5, [
        ("burung merbuk burung kedidi", ["مربوق", "merbuk", "كديدي", "kedidi"]),
        ("hinggap di pohon kopi", ["هيڠݢڤ", "hinggap", "دڤو"]),
        ("kalau hidup tidak bererti", ["بربودي", "bererti", "هيدوڤ", "hidup"]),
        ("ibarat pohon tidak berbuah", ["بربواه", "berbuah", "ڤوکوق", "pohon"]),
    ]),
    "jawi-2025-d2": (6, [
        ("isi ayat", ["دلارغ", "سمقه", "سوغاي", "حاضير", "ككلس"]),
        ("pelengkap ayat", ["ممبواغ", "كدالم", "تڤت", "وقتوث"]),
    ]),
    "jawi-2025-d3": (6, [
        ("tarikh kejadian", ["اڤريل", "april", "٢٠٢٥", "2025"]),
        ("kebakaran", ["كباكرن", "kebakaran"]),
        ("saluran paip", ["سالورن", "saluran", "ڤاءيڤ", "paip"]),
        ("milik Petronas", ["ميليق", "milik", "ڤيترونس", "petronas"]),
    ]),
    # ---------- SIRAH ----------
    "sirah-2024-d1": (2, [
        ("17 Ramadan", ["رمضان", "ramadan"]),
        ("tahun kedua hijrah", ["هجرة", "hijrah", "تاهون", "tahun"]),
    ]),
    "sirah-2024-d9": (1, [
        ("mengelakkan pertumpahan darah",
         ["مڠيلقكن", "mengelakkan", "ڤرتومڤهن", "داره", "darah"]),
    ]),
    "sirah-2025-d1": (2, [
        ("perjalanan pada malam hari", ["ڤرجالنن", "perjalanan", "مالم", "malam"]),
        ("Masjidil Haram ke Masjidil Aqsa", ["الحرام", "haram", "الأقصى", "aqsa"]),
    ]),
    "sirah-2025-d2": (2, [
        ("Sidratul Muntaha", ["سدرة", "المنتهى", "sidratul", "muntaha"]),
        ("langit yang tinggi", ["كلاغيت", "langit", "تيغكي", "tinggi"]),
    ]),
    "sirah-2025-d3": (2, [
        ("27 Rejab", ["رجب", "rejab"]),
        ("tahun 621 Masihi", ["٦٢١", "621", "مسيحي", "masihi"]),
    ]),
}


def main():
    root = pathlib.Path("assets/content/sebenar")
    jumlah = 0
    for fail in sorted(root.glob("*.json")):
        data = json.loads(fail.read_text())
        ubah = False
        for bahagian in data["bahagian"]:
            for soalan in bahagian.get("soalan", []):
                qid = soalan["id"]
                if qid not in RUBRIK:
                    continue
                markah, isi = RUBRIK[qid]
                if soalan.get("markah") != markah:
                    print(f"  ! {qid}: markah JSON {soalan.get('markah')} "
                          f"≠ jadual {markah}")
                soalan["idea"] = [
                    {"maksud": m, "kata": k} for m, k in isi
                ]
                ubah = True
                jumlah += 1
        if ubah:
            fail.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    print(f"{jumlah} soalan diberi rubrik")


if __name__ == "__main__":
    main()
