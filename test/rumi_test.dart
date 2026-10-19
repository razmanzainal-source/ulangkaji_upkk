// Ujian peraturan paparan baris Rumi.
//
// Kertas UPKK sebenar **langsung tiada** Rumi: keseluruhan kertas ditulis dalam
// Jawi, dan arahan pada kulit kertasnya berbunyi "calon dikehendaki menjawab
// semua soalan dalam tulisan Jawi". Jadi:
//
//   * **latih tubi** mengekalkan Rumi — tujuannya mengajar;
//   * **kertas percubaan** menanggalkannya — tujuannya meniru peperiksaan,
//     supaya murid benar-benar berlatih membaca Jawi.
//
// Peraturan ini senang hilang semasa kod lain diubah, jadi ia dikunci di sini.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/models/kertas.dart';
import 'package:ulangkaji_upkk/screens/kertas_screen.dart';
import 'package:ulangkaji_upkk/widgets/dwibahasa.dart';

import 'bantuan/audio_palsu.dart';
import 'bantuan/saiz_telefon.dart';

const String _jawi = 'ايسيتنجاء برمقصود';
const String _rumi = 'Istinjak bermaksud';

/// Kertas satu soalan aneka pilihan, dengan Rumi pada soalan, item dan pilihan.
Kertas _kertas({required String jenisSumber}) {
  return Kertas(
    id: 'rumi-1',
    subjekId: 'ibadah',
    tajuk: 'Ibadah — Ujian',
    sumber: 'Ujian',
    jenisSumber: jenisSumber,
    bahagian: [
      BahagianKertas(
        nama: 'A',
        markah: 3,
        arahan: 'بولا تکن جوافن',
        arahanRumi: 'Bulatkan jawapan',
        soalan: [
          SoalanKertas(
            id: 'rumi-a1',
            bahagian: 'A',
            nombor: 1,
            jenis: JenisKertas.bulat,
            soalan: _jawi,
            rumi: _rumi,
            markah: 3,
            item: [
              ItemKertas(
                nombor: 1,
                teks: 'سأبارا',
                rumi: 'Sabara',
                pilihan: const ['ساتو', 'دوا'],
                pilihanRumi: const ['satu', 'dua'],
                jawapan: 0,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Bukakan kertas sehingga soalan pertama kelihatan.
Future<void> _buka(WidgetTester tester, Kertas kertas) async {
  gunaSaizTelefon(tester);
  await tester.pumpWidget(MaterialApp(home: KertasScreen(kertas: kertas)));
  await tester.pump();
  await tester.tap(find.text('Mula menjawab'));
  await tester.pump();
}

/// Lepaskan widget supaya pemasa audio dan pemasa kertas tamat.
Future<void> _tutup(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(seconds: 3));
  }
}

/// Bilangan widget teks di dalam satu [Dwibahasa].
Finder _teksDalamDwibahasa() =>
    find.descendant(of: find.byType(Dwibahasa), matching: find.byType(Text));

void main() {
  group('Dwibahasa', () {
    Widget balut(Widget anak, {bool? tunjuk}) => MaterialApp(
      home: Scaffold(
        body: tunjuk == null ? anak : TunjukRumi(tunjuk: tunjuk, child: anak),
      ),
    );

    testWidgets('tanpa TunjukRumi, Jawi dan Rumi dipaparkan', (tester) async {
      await tester.pumpWidget(balut(const Dwibahasa(jawi: _jawi, rumi: _rumi)));

      expect(_teksDalamDwibahasa(), findsNWidgets(2));
      expect(find.text(_rumi), findsOneWidget);
    });

    testWidgets('TunjukRumi(false): Rumi dibuang, Jawi kekal', (tester) async {
      await tester.pumpWidget(
        balut(const Dwibahasa(jawi: _jawi, rumi: _rumi), tunjuk: false),
      );

      expect(_teksDalamDwibahasa(), findsOneWidget);
      expect(find.text(_jawi), findsOneWidget);
      expect(find.text(_rumi), findsNothing);
    });

    testWidgets('TunjukRumi(true): Rumi dikekalkan', (tester) async {
      await tester.pumpWidget(
        balut(const Dwibahasa(jawi: _jawi, rumi: _rumi), tunjuk: true),
      );

      expect(find.text(_rumi), findsOneWidget);
    });
  });

  group('baris Rumi pada kertas', () {
    setUpAll(pasangAudioPalsu);

    testWidgets('latih tubi: Rumi soalan dan pilihan dipaparkan', (
      tester,
    ) async {
      await _buka(tester, _kertas(jenisSumber: 'latihan'));

      expect(find.text(_rumi), findsOneWidget, reason: 'Rumi soalan');
      expect(find.text('satu'), findsOneWidget, reason: 'Rumi pilihan');
      await _tutup(tester);
    });

    testWidgets('kertas percubaan: Rumi ditanggalkan, Jawi kekal', (
      tester,
    ) async {
      await _buka(tester, _kertas(jenisSumber: 'percubaan'));

      expect(find.text(_jawi), findsOneWidget, reason: 'Jawi mesti kekal');
      expect(find.text(_rumi), findsNothing, reason: 'Rumi soalan');
      expect(find.text('satu'), findsNothing, reason: 'Rumi pilihan');
      expect(find.text('ساتو'), findsOneWidget, reason: 'pilihan Jawi kekal');
      await _tutup(tester);
    });
  });
}
