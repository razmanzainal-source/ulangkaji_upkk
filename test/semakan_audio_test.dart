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
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        Suara.instance.ayatTerakhir,
        Suara.kunciSoalan('uji-a1'),
        reason: 'soalan mesti dimainkan dahulu',
      );
      await _tutup(tester);
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

  group('sapaan pembuka', () {
    test('sapaan dipecahkan supaya nama boleh diletakkan di tengah', () {
      // "Assalamualaikum, [nama], jom ulangkaji KAFA bersama Raz." —
      // dua rakaman dengan nama di antaranya.
      expect(Suara.kunciSelamat1, 'f-selamat-1');
      expect(Suara.kunciSelamat2, 'f-selamat-2');
      expect(Suara.sapaanBer, contains('Raz'));
      expect(Suara.sapaan, contains('Assalamualaikum'));
    });
  });
}
