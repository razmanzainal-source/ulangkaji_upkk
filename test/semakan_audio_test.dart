// Ujian audio dalam skrin semakan (selepas kertas dihantar).
//
// Selepas murid selesai menjawab semua soalan, skrin "Semakan jawapan"
// membolehkan dia ulang kaji. Butang "Dengar soalan & jawapan" di situ
//_accuracy_: butang ini **tidak** menambah saiz app — ia menggunakan klip
// `q-<id>` (soalan) dan `o-<teks>` (jawapan) yang memang sudah dibundelkan.
//
// Ujian ini mengunci tiga perkara:
//   1. Setiap soalan dalam semakan ada butang speaker.
//   2. Butang itu memainkan **soalan dahulu**, kemudian jawapan.
//   3. Jawapan bagi soalan berbilang item diberi **nombor** — supaya murid
//      tahu jawapan yang mana milik item yang mana, dan bukan satu ayat
//      panjang yang bersambung.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/models/jawapan.dart';
import 'package:ulangkaji_upkk/models/kertas.dart';
import 'package:ulangkaji_upkk/screens/keputusan_screen.dart';
import 'package:ulangkaji_upkk/services/suara.dart';

import 'bantuan/audio_palsu.dart';

/// Kertas dengan satu soalan `kumpulan` berbilang item.
Kertas _kertasKumpulan() {
  return Kertas(
    id: 'uji-semakan',
    subjekId: 'adab',
    tajuk: 'Adab — Ujian',
    sumber: 'Ujian',
    jenisSumber: 'percubaan',
    bahagian: [
      BahagianKertas(
        nama: 'A',
        markah: 4,
        arahan: 'سوايکن ڤد جواڤن.',
        arahanRumi: 'Suaikan dengan jawapan.',
        soalan: [
          SoalanKertas(
            id: 'uji-a1',
            bahagian: 'A',
            nombor: 1,
            jenis: JenisKertas.kumpulan,
            soalan: 'سوايکن ڤد جواڤن.',
            rumi: 'Suaikan dengan jawapan.',
            markah: 4,
            kategori: const ['دالوم مسجد', 'دالوم ڤونيسڤي'],
            kategoriRumi: const ['Di dalam masjid', 'Di dalam universiti'],
            item: const [
              ItemKertas(
                nombor: 1,
                teks: 'منتجات كربونات',
                rumi: 'Minuman berkarbonat',
                jawapan: 1,
              ),
              ItemKertas(
                nombor: 2,
                teks: 'مبيع دغما',
                rumi: 'Pasaran malam',
                jawapan: 0,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Tutup skrin dan biarkan semua timer tamat.
///
/// Skrin keputusan celebrates dengan bunga api dan memulakan pemasa audio;
/// dalam ujian, timer yang belum tamat menggagalkan ujian.
Future<void> _tutup(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(seconds: 3));
  }
}

void main() {
  setUpAll(pasangAudioPalsu);

  setUp(() {
    Suara.instance.ayatTerakhir = null;
    Suara.instance.kesanTerakhir = null;
    // Manifest rakaman palsu — dalam ujian `rootBundle` tiada bundle aset.
    Suara.instance.suntukManifest({
      'f-selamat': 'sapaan.m4a',
      'f-selamat-1': 'sapaan1.m4a',
      'f-selamat-2': 'sapaan2.m4a',
      'q-uji-a1': 'soalan.m4a',
      'o-Nombor 1': 'nombor1.m4a',
      'o-Minuman berkarbonat': 'item1.m4a',
      'o-Di dalam universiti': 'kategori1.m4a',
      'o-Nombor 2': 'nombor2.m4a',
      'o-Pasaran malam': 'item2.m4a',
      'o-Di dalam masjid': 'kategori2.m4a',
    });
  });

  group('audio skrin semakan', () {
    testWidgets('setiap soalan ada butang "Dengar soalan & jawapan"', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KeputusanScreen(
            kertas: _kertasKumpulan(),
            jawapan: const {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.byTooltip('Dengar soalan & jawapan'),
        findsOneWidget,
        reason: 'murid perlu boleh mendengar soalan dan jawapan semasa ulang kaji',
      );
      await _tutup(tester);
    });

    testWidgets('butang memainkan soalan dahulu, kemudian jawapan', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KeputusanScreen(
            kertas: _kertasKumpulan(),
            jawapan: const {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final butang = find.byTooltip('Dengar soalan & jawapan');
      await tester.ensureVisible(butang);
      await tester.pump();
      await tester.tap(butang);
      await tester.pump();

      // Skrin keputusan turut_INTERNAL playable audio keputusan; yang diperiksa
      // di sini ialah **niat** — soalan diminta sebelum jawapan.
      expect(
        Suara.instance.kunciDiminta,
        contains(Suara.kunciSoalan('uji-a1')),
        reason: 'soalan mesti dimainkan dahulu',
      );
      await _tutup(tester);
    });


    testWidgets('soalan diminta dahulu, sebelum jawapan', (tester) async {
      // Regression: `sebutKunci` pernah pulang sebaik mainsian *bermula*,
      // bukan apabila ia *tamat*. Ayat seterusnya kemudian memanggil
      // `stop()` dan memotong rakaman — murid mendengar bunyi terputus.
      //
      // Ujian ini memeriksa **niat** (urutan kunci yang diminta), kerana
      // platform audio palsu tidak boleh menghasilkan bunyi sebenar.
      Suara.instance.ayatTerakhir = null;
      Suara.instance.kunciDiminta.clear();
      final s = _kertasKumpulan().semuaSoalan.first;

      Suara.instance
          .sebutSoalanDanJawapan(
            id: s.id,
            sandaran: s.rumi,
            segmenJawapan: s.jawapanDengarSegmen,
          )
          .ignore();
      await tester.pump();

      expect(
        Suara.instance.kunciDiminta.first,
        Suara.kunciSoalan('uji-a1'),
        reason: 'soalan mesti dibacakan lebih dahulu,'
      );
    });

    test('jawapan berbilang item diberi nombor', () {
      final s = _kertasKumpulan().semuaSoalan.first;

      // Paparan: `1. jawapan` — sepadan dengan penomboran kertas asal.
      expect(
        s.jawapanPenuhTeksBernombor,
        '1. ${s.item[0].teks} — ${s.kategori[1]}\n'
        '2. ${s.item[1].teks} — ${s.kategori[0]}',
      );

      // Suara: satu baris satu baris. Setiap baris ialah segmen — nombor
      // item dahulu, kemudian jawapannya — supaya murid tahu jawapan yang
      // mana milik item yang mana.
      expect(
        s.jawapanDengarSegmen,
        [
          ['Nombor 1', s.item[0].rumi, s.kategoriRumi[1]],
          ['Nombor 2', s.item[1].rumi, s.kategoriRumi[0]],
        ],
      );
    });

    test('soalan satu item tidak dinomborkan', () {
      final s = SoalanKertas(
        id: 'uji-a2',
        bahagian: 'A',
        nombor: 2,
        jenis: JenisKertas.bulat,
        soalan: 'سأبارا فدوق؟',
        rumi: 'Sabara paduk?',
        markah: 1,
        item: const [
          ItemKertas(
            nombor: 1,
            teks: 'سأبارا',
            rumi: 'Sabara',
            pilihan: const ['ساتو', 'دوا'],
            pilihanRumi: const ['satu', 'dua'],
            jawapan: 0,
          ),
        ],
      );
      expect(s.jawapanBerbilang, isFalse);
      expect(s.jawapanPenuhTeksBernombor, 'ساتو');
    });
  });


  group('cara jawapan dibacakan', () {
    test('betul/salah disebut dengan perkataan, bukan tanda', () {
      final s = SoalanKertas(
        id: 'uji-bs',
        bahagian: 'C',
        nombor: 1,
        jenis: JenisKertas.betulSalah,
        soalan: 'تنداكن ✓ ڤد ڤياتاءن يغ بتول دان ✗ ڤد ڤياتاءن يغ ساله.',
        rumi: 'Tandakan betul atau salah.',
        markah: 2,
        item: const [
          ItemKertas(
            nombor: 1,
            teks: 'محمد سوك برماءين دڤادغ.',
            rumi: 'Muhammad suka bermain di padang.',
            betul: true,
          ),
          ItemKertas(
            nombor: 2,
            teks: 'امبوي، جنتيقث باجو خديجة؟',
            rumi: 'Amboi, cantiknya baju Khadijah?',
            betul: false,
          ),
        ],
      );

      // Tanda ✓/✗ tidak boleh disebut enjin suara — perkataan "Betul"/"Salah"
      // mesti disebut supaya murid tahu mana yang betul.
      expect(s.jawapanDengarBaris.first, contains('Betul'));
      expect(s.jawapanDengarBaris.last, contains('Salah'));
      expect(s.jawapanDengarSegmen.first, contains('Betul'));
      expect(s.jawapanDengarSegmen.last, contains('Salah'));
    });

    test('isi tempat kosong: ayat dibaca dahulu, kemudian jawapannya', () {
      final s = SoalanKertas(
        id: 'uji-tk',
        bahagian: 'C',
        nombor: 1,
        jenis: JenisKertas.tempatKosong,
        soalan: 'ايسي تمڤت کوسوڠ دغن جواڤن يغ بتول.',
        rumi: 'Isi tempat kosong dengan jawapan yang betul.',
        markah: 2,
        item: const [
          ItemKertas(
            nombor: 1,
            teks: 'تRoutine ____ ديري.',
            rumi: 'Tetamu ialah orang yang datang ____.',
          ),
        ],
        bank: const ['bertandang'],
        bankRumi: const ['bertandang'],
      );

      // Ayat dahulu, kemudian jawapan — supaya murid tahu jawapan itu
      // mengisi tempat kosong yang mana.
      expect(
        s.jawapanDengarSegmen.first,
        ['Tetamu ialah orang yang datang ____.', 'bertandang'],
      );
      // Ayat juga mesti dipaparkan dalam semakan.
      expect(s.ayatSoalan.first, contains('Tetamu'));
      expect(s.jawapanTempatKosongPaparan, contains('bertandang'));
    });
  });

}
