#!/usr/bin/env python3
"""Jana JSON kertas sebenar jawi-2024 daripada imbasan + skema rasmi."""
import json

def b(t, r, **kw):
    d = {'teks': t, 'rumi': r}
    d.update(kw)
    return d

def p(t, r):
    return {'teks': t, 'rumi': r}

kertas = {
    'id': 'jawi-2024',
    'subjek': 'jawi',
    'tajuk': 'Jawi dan Khat UPKK 2024',
    'sumber': 'Kertas soalan UPKK 2024 — imbasan rasmi',
    'jenisSumber': 'sebenar',
    'masa': 75,
    'nota': 'Jawapan diambil daripada skema rasmi (muka13). '
            'Bahagian A 10, B 10, C 15, D 25, E 10.',
    'bahagian': [
        {
            'nama': 'A', 'markah': 10,
            'arahan': 'جواب سموا سوءالن.',
            'arahanRumi': 'Jawab semua soalan.',
            'soalan': [
                {
                    'id': 'jawi-2024-a1', 'markah': 2, 'jenis': 'tulis',
                    'soalan': 'توليس حروف توغكل مڠيكوت اوروتن يغ بتول. (٢ مركه)',
                    'rumi': 'Tulis huruf tunggal mengikut urutan yang betul. (2 markah)',
                    'jawapanContoh': ['ت ة ذ س ص ط'],
                    'jawapanContohRumi': ['Ta, ta marbutah, zal, sin, sad, ta'],
                },
                {
                    'id': 'jawi-2024-a2', 'markah': 2, 'jenis': 'tulis',
                    'soalan': 'سامبوغكن حروف ٢ برايكوت منجادي ساتو ڤركاتاءن. (٢ مركه)',
                    'rumi': 'Sambungkan huruf-huruf berikut menjadi satu perkataan. (2 markah)',
                    'jawapanContoh': ['سيغا', 'سمقن'],
                    'jawapanContohRumi': ['Singa', 'Semangat?'],
                },
                {
                    'id': 'jawi-2024-a3', 'markah': 3, 'jenis': 'tulis',
                    'soalan': 'جرايكن ڤركاتاءن ٢ برايكوت كڤد حروف توغكل. (٣ مركه)',
                    'rumi': 'Ceralkan perkataan-perkataan berikut kepada huruf tunggal. (3 markah)',
                    'jawapanContoh': ['ث ل ج ي', 'ل ي م و'],
                    'jawapanContohRumi': ['Thalji', 'Limau'],
                },
                {
                    'id': 'jawi-2024-a4', 'markah': 3, 'jenis': 'tulis',
                    'soalan': 'جاويكن ڤركاتاءن ٢ برايكوت. (٣ مركه)',
                    'rumi': 'Jawikan perkataan-perkataan berikut. (3 markah)',
                    'jawapanContoh': ['تامو', 'كيكي', 'سيوا'],
                    'jawapanContohRumi': ['Tamu', 'Gigi', 'Sewa'],
                },
            ],
        },
        {
            'nama': 'B', 'markah': 10,
            'arahan': 'Soalan 1 hingga 10. Bulatkan jawapan yang betul.',
            'arahanRumi': 'Soalan 1 hingga 10. Bulatkan jawapan yang betul.',
            'soalan': [
                {
                    'id': 'jawi-2024-b1', 'markah': 1, 'jenis': 'objektif',
                    'soalan': 'احمد ____ سأيكور ايكن امس ددالم اكواريوم.',
                    'rumi': 'Ahmad ____ seekor ikan emas di dalam akuarium.',
                    'item': [b('', '', jawapan=1, pilihan=[
                        p('ترڤليهارا', 'Terpelihara'), p('ممليهارا', 'Memelihara'),
                        p('دقليهارا', 'Dipelihara'), p('ڤمليهارا', 'Pemelihara')])],
                },
                {
                    'id': 'jawi-2024-b2', 'markah': 1, 'jenis': 'objektif',
                    'soalan': 'ماناكه ڤركاتاءن برايكوت يغ مروڤاكن كات سرڤن بهاس ايڤكريس؟',
                    'rumi': 'Manakah perkataan berikut yang merupakan kata serapan bahasa Inggeris?',
                    'item': [b('', '', jawapan=0, pilihan=[
                        p('سمين', 'Semen'), p('عسكر', 'Askar'),
                        p('محكمه', 'Mahkamah'), p('مسجد', 'Masjid')])],
                },
                {
                    'id': 'jawi-2024-b3', 'markah': 1, 'jenis': 'objektif',
                    'soalan': 'كيت سڤاتوتث مندغر ____ كورو.',
                    'rumi': 'Kita sepatutnya mendengar ____ guru.',
                    'item': [b('', '', jawapan=1, pilihan=[
                        p('ناصحت', 'Nasihat'), p('نصيحت', 'Nasihat'),
                        p('ناسيحت', 'Nasihat'), p('نسيحت', 'Nasihat')])],
                },
                {
                    'id': 'jawi-2024-b4', 'markah': 1, 'jenis': 'objektif',
                    'soalan': 'امبوي، جنتيق بتول باجو اوق. اڤاكه تندا باج يغ سسواي اونتوق ايات دأتس؟',
                    'rumi': 'Amboi, cantik betul baju awak. Apakah tanda baca yang sesuai untuk ayat di atas?',
                    'item': [b('', '', jawapan=3, pilihan=[
                        p('!', 'Seru'), p('?', 'Tanya'),
                        p(',', 'Koma'), p('.', 'Noktah')])],
                },
                {
                    'id': 'jawi-2024-b5', 'markah': 1, 'jenis': 'objektif',
                    'soalan': 'داتوق ساي اياله بكس اغكوتا ____.',
                    'rumi': 'Datuk saya ialah bekas anggota ____.',
                    'item': [b('', '', jawapan=2, pilihan=[
                        p('تي. او. دي. عيم.', 'T.O.D.U.M.'),
                        p('تي. او. دي. ايم.', 'T.O.D.I.M.'),
                        p('تي. يو. دي. ايم.', 'T.U.D.I.M.'),
                        p('تي. يو. دي. عيم.', 'T.U.D.U.M.')])],
                },
                {
                    'id': 'jawi-2024-b6', 'markah': 1, 'jenis': 'objektif',
                    'soalan': 'بوروغ bangau براد دتفي ساوه. ڤيليه ايجاءن يغ بتول باكي ڤركاتاءن بركاريس دأتس.',
                    'rumi': 'Burung bangau berada di tepi sawah. Pilih ejaan yang betul bagi perkataan bergaris di atas.',
                    'item': [b('', '', jawapan=3, pilihan=[
                        p('بغو', 'Bangu'), p('باغو', 'Bagu'),
                        p('باغاو', 'Bagau'), p('بقاو', 'Bangau')])],
                },
                {
                    'id': 'jawi-2024-b7', 'markah': 1, 'jenis': 'objektif',
                    'soalan': 'ڤركاتاءن برايكوت مڠاندوغي ديفتوغ كجوالي ____.',
                    'rumi': 'Perkataan berikut mengandungi diftong, kecuali ____.',
                    'item': [b('', '', jawapan=2, pilihan=[
                        p('كاءيس', 'Kais'), p('ڤولاو', 'Pulau'),
                        p('تاوكيه', 'Tauke'), p('امبوي', 'Amboi')])],
                },
                {
                    'id': 'jawi-2024-b8', 'markah': 1, 'jenis': 'objektif',
                    'soalan': 'كامي ڤركي كملك مڠكوناكن البوه راي ____.',
                    'rumi': 'Kami pergi ke makmal menggunakan alatulis ____.',
                    'item': [b('', '', jawapan=0, pilihan=[
                        p('ڤلوس', 'Pilus'), p('ڤيلوس', 'Piluss'),
                        p('قلاس', 'Kelas'), p('ڤلس', 'Pelas')])],
                },
                {
                    'id': 'jawi-2024-b9', 'markah': 1, 'jenis': 'objektif',
                    'soalan': 'اوسهله كامو مڠهينا بودق ايت. ايات دأتس اياله ____.',
                    'rumi': 'Usahlah kamu menghina budak itu. Ayat di atas ialah ____.',
                    'item': [b('', '', jawapan=1, pilihan=[
                        p('ايات سروان', 'Ayat seruan'), p('ايات larangan', 'Ayat larangan'),
                        p('ايات تاث', 'Ayat tanya'), p('ايات ڤيات', 'Ayat penyata')])],
                },
                {
                    'id': 'jawi-2024-b10', 'markah': 1, 'jenis': 'objektif',
                    'soalan': 'ڤيليه جنيس ايات ڤرينته.',
                    'rumi': 'Pilih jenis ayat perintah.',
                    'item': [b('', '', jawapan=3, pilihan=[
                        p('i دان ii', 'i dan ii'), p('ii دان iii', 'ii dan iii'),
                        p('iii دان iv', 'iii dan iv'), p('iv دان i', 'iv dan i')])],
                },
            ],
        },
        {
            'nama': 'C', 'markah': 15,
            'arahan': 'جواب سوءالن برايکوت.',
            'arahanRumi': 'Jawab soalan berikut.',
            'soalan': [
                {
                    'id': 'jawi-2024-c1', 'markah': 5, 'jenis': 'kumpulan',
                    'soalan': 'سوايكن جواڤن قد كاتکوري يغ بتول. (٥ مركه)',
                    'rumi': 'Suaikan jawapan pada kategori yang betul. (5 markah)',
                    'kategori': ['كات سرڤن بهاس عرب', 'كات سرڤن بهاس ايڤكريس'],
                    'kategoriRumi': ['Kata serapan bahasa Arab', 'Kata serapan bahasa Inggeris'],
                    'item': [
                        b('ثلجي', 'Thalji', jawapan=0),
                        b('هديه', 'Hadiah', jawapan=0),
                        b('معمل', "Ma'mal", jawapan=0),
                        b('بيسكوت', 'Biskut', jawapan=1),
                        b('ستيسين', 'Stesen', jawapan=1),
                    ],
                },
                {
                    'id': 'jawi-2024-c2', 'markah': 5, 'jenis': 'tulis',
                    'soalan': 'ايسي تندا باج يغ بتول باكي جنيس ايات دباوه. (٥ مركه)',
                    'rumi': 'Isi tanda baca yang betul bagi jenis ayat di bawah. (5 markah)',
                    'jawapanContoh': ['؟', '!', '.', '.', '.'],
                    'jawapanContohRumi': ['Tanya', 'Seru', 'Noktah', 'Noktah', 'Noktah'],
                },
                {
                    'id': 'jawi-2024-c3', 'markah': 5, 'jenis': 'bulat',
                    'soalan': 'تنداكن ✓ ڤد ڤيليهن جنيس ايات يغ بتول. (٥ مركه)',
                    'rumi': 'Tandakan ✓ pada pilihan jenis ayat yang betul. (5 markah)',
                    'item': [
                        b('مڠاڤاكه كامو تيدق حاضير كسكوله؟',
                          'Mengapakah kamu tidak hadir ke sekolah?', jawapan=1,
                          pilihan=[p('ايات سروان', 'Ayat seruan'), p('ايات تاث', 'Ayat tanya')]),
                        b('اوس، لنتاي ايت ساڠت ليجين!',
                          'Wah, lantai itu sangat licin!', jawapan=0,
                          pilihan=[p('ايات سروان', 'Ayat seruan'), p('ايات تاث', 'Ayat tanya')]),
                        b('تولوغ امبيلكن ساي سكلس اءير مينومن.',
                          'Tolong ambilkan saya segelas air minuman.', jawapan=0,
                          pilihan=[p('ايات ڤرينته', 'Ayat perintah'), p('ايات ڤيات', 'Ayat penyata')]),
                        b('كامي مراس بڠݢ منجادي رعيت مليسيا.',
                          'Kami berasa bangga menjadi rakyat Malaysia.', jawapan=0,
                          pilihan=[p('ايات ڤيات', 'Ayat penyata'), p('ايات نفي', 'Ayat nafi')]),
                        b('بوكن حسن يغ مڠمبيل بيك ترسبوت.',
                          'Bukan Hasan yang mengambil buku tersebut.', jawapan=1,
                          pilihan=[p('ايات ڤيات', 'Ayat penyata'), p('ايات نفي', 'Ayat nafi')]),
                    ],
                },
            ],
        },
        {
            'nama': 'D', 'markah': 25,
            'arahan': 'جواب سوءالن برايکوت دڠن لڠکڤ.',
            'arahanRumi': 'Jawab soalan berikut dengan lengkap.',
            'soalan': [
                {
                    'id': 'jawi-2024-d1', 'markah': 4, 'jenis': 'tulis',
                    'soalan': 'جاويكن ڤركاتاءن دباوه. (٤ مركه)',
                    'rumi': 'Jawikan perkataan di bawah. (4 markah)',
                    'jawapanContoh': ['حاصيل كرجا', 'برلاري-لارين', 'كاون ٢', 'عالم ڤرسكولهن'],
                    'jawapanContohRumi': ['Hasil kerja', 'Berlari-larian', 'Kawan-kawan', 'Alam persekolahan'],
                },
                {
                    'id': 'jawi-2024-d2', 'markah': 6, 'jenis': 'tulis',
                    'soalan': 'بينا ايات برداسركن ڤركاتاءن دبري. (٦ مركه)',
                    'rumi': 'Bina ayat berdasarkan perkataan diberi. (6 markah)',
                    'jawapanContoh': ['هو سڤيتل ايت ساڠت بسر.', 'سيلا توتوڤ سوءيس كومڤيوتر ايت.'],
                    'jawapanContohRumi': ['Hotel itu sangat besar.', 'Sila tutup suis komputer itu.'],
                },
                {
                    'id': 'jawi-2024-d3', 'markah': 6, 'jenis': 'tulis',
                    'soalan': 'جواب سوءالن برداسركن ڤتيقن دباوه. (٦ مركه)',
                    'rumi': 'Jawab soalan berdasarkan petikan di bawah. (6 markah)',
                    'jawapanContoh': ['مڠاداكن, سمبوتن', 'Guru Jauhari Digital, Aspirasi Negara Madani'],
                    'jawapanContohRumi': ['Mengadakan, sambutan', 'Guru Jauhari Digital, Aspirasi Negara Madani'],
                },
                {
                    'id': 'jawi-2024-d4', 'markah': 5, 'jenis': 'tulis',
                    'soalan': 'جواب سوءالن بركاءيتن دڠن ڤنتون دباوه. (٥ مركه)',
                    'rumi': 'Jawab soalan berkaitan dengan pantun di bawah. (5 markah)',
                    'jawapanContoh': ['بوروغ مربوق بوروغ كديدي، هيڠݢڤ دڤو كوق تقي ساوه، جک هيدوڤ تيدق بربودي، عبارت ڤوکوق تيدق بربواه.', 'هيڠݢڤ, عبارت'],
                    'jawapanContohRumi': ['Burung merbuk burung kedidi, Hinggap di pohon kayu tepi sawah, Jika hidup tidak berbudi, Ibarat pokok tidak berbuah.', 'Hinggap, ibarat'],
                },
                {
                    'id': 'jawi-2024-d5', 'markah': 4, 'jenis': 'tulis',
                    'soalan': 'روميكن ڤركاتاءن دباوه. (٤ مركه)',
                    'rumi': 'Rumikan perkataan di bawah. (4 markah)',
                    'jawapanContoh': ['hinggap', 'ibarat'],
                    'jawapanContohRumi': ['hinggap', 'ibarat'],
                },
            ],
        },
        {
            'nama': 'E', 'markah': 10,
            'arahan': 'توليس سمولا خط برايکوت.',
            'arahanRumi': 'Tulis semula khat berikut.',
            'soalan': [
                {
                    'id': 'jawi-2024-e1', 'markah': 10, 'jenis': 'tulis',
                    'soalan': 'سالين سمولا خط يغ برايکوت.',
                    'rumi': 'Salin semula khat yang berikut.',
                    'jawapanContoh': ['تول'],
                    'jawapanContohRumi': ['Tul'],
                },
            ],
        },
    ],
}

jumlah = sum(b['markah'] for b in kertas['bahagian'])
assert jumlah == 70, jumlah

with open('assets/content/sebenar/jawi-2024.json', 'w', encoding='utf-8') as f:
    json.dump(kertas, f, ensure_ascii=False, indent=2)
    f.write('\n')
print('jawi-2024.json ditulis; jumlah markah', jumlah)
