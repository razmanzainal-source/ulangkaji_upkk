#!/usr/bin/env python3
"""Ganti soalan "kata lawan" Bahasa Arab dengan topik Mudhakkar/Mu'annath.

Guru KAFA memaklumkan sukatan 2026 tiada topik kata lawan. Tujuh soalan yang
menggunakan topik itu (a7, b59, b60, c18, c19, d2, d14) diganti dengan
Mudhakkar/Mu'annath — bilangan soalan, jenis dan markah kekal sama.

Nota reka bentuk: kata nama mudhakkar yang dipilih **empat huruf** sahaja.
Enjin pemarkahan membenarkan satu huruf tersilap bagi perkataan lima huruf ke
atas, jadi «طالب» (5 huruf) akan diterima sebagai «طالبة». Dengan memilih kata
empat huruf, membuang «ة» menjadikan jawapan itu tidak lagi sepadan — iaitu
tepat dengan apa yang soalan ini uji.
"""
import json
import pathlib

BARU = {
    # ---------- A7: bulat, 4 markah, 4 item ----------
    "arab-a7": {
        "jenis": "bulat",
        "markah": 4,
        "soalan": "اخْتَرْ مُؤَنَّثَ الْكَلِمَةِ الصَّحِيحَ.",
        "rumi": "Pilih kata mu'annath (perempuan) yang betul.",
        "item": [
            ("مُؤَنَّثُ «مُعَلِّم» هُوَ ____.", "Mu'annath bagi «mu'allim» ialah ____.",
             [("مُعَلِّمَة", "mu'allimah"), ("مُعَلِّمُون", "mu'allimun")], 0),
            ("مُؤَنَّثُ «مُسْلِم» هُوَ ____.", "Mu'annath bagi «muslim» ialah ____.",
             [("مُسْلِمَة", "muslimah"), ("مُسْلِمُون", "muslimun")], 0),
            ("مُؤَنَّثُ «كَاتِب» هُوَ ____.", "Mu'annath bagi «katib» ialah ____.",
             [("كَاتِبَة", "katibah"), ("كَاتِبُون", "katibun")], 0),
            ("مُؤَنَّثُ «طَبِيب» هُوَ ____.", "Mu'annath bagi «tabib» ialah ____.",
             [("طَبِيبَة", "tabibah"), ("أَطِبَّاء", "atibba'")], 0),
        ],
    },
    # ---------- B59: objektif, 1 markah ----------
    "arab-b59": {
        "jenis": "objektif",
        "markah": 1,
        "soalan": "أَيُّ الْكَلِمَاتِ الْآتِيَةِ مُؤَنَّثٌ؟",
        "rumi": "Yang manakah mu'annath (perempuan)?",
        "item": [
            ("", "",
             [("مُعَلِّمَة", "mu'allimah"), ("كِتَاب", "kitab"),
              ("قَلَم", "qalam"), ("بَاب", "bab")], 0),
        ],
    },
    # ---------- B60: objektif, 1 markah ----------
    "arab-b60": {
        "jenis": "objektif",
        "markah": 1,
        "soalan": "أَيُّ الْكَلِمَاتِ الْآتِيَةِ مُذَكَّرٌ؟",
        "rumi": "Yang manakah mudhakkar (lelaki)?",
        "item": [
            ("", "",
             [("مَدْرَسَة", "madrasah"), ("حَدِيقَة", "hadiqah"),
              ("كِتَاب", "kitab"), ("مِلْعَقَة", "mil'aqah")], 2),
        ],
    },
    # ---------- C18: tulis, 4 markah ----------
    "arab-c18": {
        "jenis": "tulis",
        "markah": 4,
        "soalan": "اكْتُبْ مُؤَنَّثَ الْكَلِمَاتِ الْآتِيَةِ: مُعَلِّم، مُسْلِم، كَاتِب، طَبِيب.",
        "rumi": "Tulis mu'annath bagi perkataan: mu'allim, muslim, katib, tabib.",
        "jawapanContoh": ["مُعَلِّمَةٌ، مُسْلِمَةٌ، كَاتِبَةٌ، طَبِيبَةٌ"],
        "idea": [
            ("mu'allim -> mu'allimah", ["معلمة", "muallimah"]),
            ("muslim -> muslimah", ["مسلمة", "muslimah"]),
            ("katib -> katibah", ["كاتبة", "katibah"]),
            ("tabib -> tabibah", ["طبيبة", "tabibah"]),
        ],
    },
    # ---------- C19: tulis, 4 markah ----------
    "arab-c19": {
        "jenis": "tulis",
        "markah": 4,
        "soalan": "اكْتُبْ مُؤَنَّثَ الْكَلِمَاتِ الْآتِيَةِ: تَاجِر، نَجَّار، خَبَّاز، حَارِس.",
        "rumi": "Tulis mu'annath bagi perkataan: tajir, najjar, khabbaz, haris.",
        "jawapanContoh": ["تَاجِرَةٌ، نَجَّارَةٌ، خَبَّازَةٌ، حَارِسَةٌ"],
        "idea": [
            ("tajir -> tajirah", ["تاجرة", "tajirah"]),
            ("najjar -> najjarah", ["نجارة", "najjarah"]),
            ("khabbaz -> khabbazah", ["خبازة", "khabbazah"]),
            ("haris -> harisah", ["حارسة", "harisah"]),
        ],
    },
    # ---------- D2: huraian, 7 markah ----------
    "arab-d2": {
        "jenis": "huraian",
        "markah": 7,
        "soalan": ("اكْتُبْ مُؤَنَّثَ الْكَلِمَاتِ الْآتِيَةِ: مُعَلِّم، مُسْلِم، كَاتِب، "
                   "طَبِيب، تَاجِر، نَجَّار، فَلَّاح."),
        "rumi": ("Tulis mu'annath bagi perkataan: mu'allim, muslim, katib, tabib, "
                 "tajir, najjar, fallah."),
        "jawapanContoh": [
            "مُعَلِّمَةٌ، مُسْلِمَةٌ، كَاتِبَةٌ، طَبِيبَةٌ، تَاجِرَةٌ، نَجَّارَةٌ، فَلَّاحَةٌ"
        ],
        "idea": [
            ("mu'allim -> mu'allimah", ["معلمة", "muallimah"]),
            ("muslim -> muslimah", ["مسلمة", "muslimah"]),
            ("katib -> katibah", ["كاتبة", "katibah"]),
            ("tabib -> tabibah", ["طبيبة", "tabibah"]),
            ("tajir -> tajirah", ["تاجرة", "tajirah"]),
            ("najjar -> najjarah", ["نجارة", "najjarah"]),
            ("fallah -> fallahah", ["فلاحة", "fallahah"]),
        ],
    },
    # ---------- D14: huraian, 7 markah (tukar ayat) ----------
    "arab-d14": {
        "jenis": "huraian",
        "markah": 7,
        "soalan": ("حَوِّلِ الْجُمَلَ الْآتِيَةَ إِلَى الْمُؤَنَّثِ: "
                   "هَذَا مُعَلِّمٌ نَشِيطٌ. هَذَا مُسْلِمٌ صَالِحٌ. "
                   "هَذَا كَاتِبٌ مَشْهُورٌ. هَذَا طَبِيبٌ مَاهِرٌ. "
                   "هَذَا تَاجِرٌ غَنِيٌّ. هَذَا نَجَّارٌ حَاذِقٌ. "
                   "هَذَا فَلَّاحٌ نَشِيطٌ."),
        "rumi": ("Tukar ayat-ayat berikut kepada bentuk mu'annath: "
                 "Ini guru lelaki yang rajin. Ini muslim lelaki yang soleh. "
                 "Ini penulis lelaki yang terkenal. Ini doktor lelaki yang mahir. "
                 "Ini peniaga lelaki yang kaya. Ini tukang kayu lelaki yang cekap. "
                 "Ini petani lelaki yang rajin."),
        "jawapanContoh": [
            "هَذِهِ مُعَلِّمَةٌ نَشِيطَةٌ، هَذِهِ مُسْلِمَةٌ صَالِحَةٌ، "
            "هَذِهِ كَاتِبَةٌ مَشْهُورَةٌ، هَذِهِ طَبِيبَةٌ مَاهِرَةٌ، "
            "هَذِهِ تَاجِرَةٌ غَنِيَّةٌ، هَذِهِ نَجَّارَةٌ حَاذِقَةٌ، "
            "هَذِهِ فَلَّاحَةٌ نَشِيطَةٌ"
        ],
        "idea": [
            ("mu'allim -> mu'allimah", ["معلمة", "muallimah"]),
            ("muslim -> muslimah", ["مسلمة", "muslimah"]),
            ("katib -> katibah", ["كاتبة", "katibah"]),
            ("tabib -> tabibah", ["طبيبة", "tabibah"]),
            ("tajir -> tajirah", ["تاجرة", "tajirah"]),
            ("najjar -> najjarah", ["نجارة", "najjarah"]),
            ("fallah -> fallahah", ["فلاحة", "fallahah"]),
        ],
    },
}


def main():
    p = pathlib.Path("assets/content/bank/arab.json")
    data = json.loads(p.read_text())
    ditukar = 0
    for q in data["soalan"]:
        if q["id"] not in BARU:
            continue
        r = BARU[q["id"]]
        q["jenis"] = r["jenis"]
        q["markah"] = r["markah"]
        q["soalan"] = r["soalan"]
        q["rumi"] = r["rumi"]
        q.pop("jawapanContoh", None)
        q.pop("idea", None)
        q.pop("pasangan", None)

        if "item" in r:
            items = []
            for teks, rumi, pilihan, jawapan in r["item"]:
                items.append({
                    "teks": teks,
                    "rumi": rumi,
                    "pilihan": [{"teks": a, "rumi": b} for a, b in pilihan],
                    "jawapan": jawapan,
                })
            q["item"] = items
        else:
            q.pop("item", None)
            q["jawapanContoh"] = r["jawapanContoh"]
            q["idea"] = [{"maksud": m, "kata": k} for m, k in r["idea"]]

        ditukar += 1
        print(f"  {q['id']}: {r['jenis']} {r['markah']} markah — diganti")

    p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    print(f"\n{ditukar} soalan diganti kepada topik Mudhakkar/Mu'annath")


if __name__ == "__main__":
    main()
