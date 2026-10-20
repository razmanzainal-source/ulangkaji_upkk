// Ujian **latih tubi** sebagai modul latihan — bukan kertas percubaan.
//
// Empat peraturan dikunci di sini kerana semuanya mudah hilang semasa kod
// lain diubah, dan semuanya mengubah pengalaman murid:
//
//   * latih tubi boleh **ditinggalkan bila-bila masa** tanpa dialog "Keluar
//     kertas?" — ia bukan kertas, jadi tiada jawapan yang "hilang";
//   * latihan yang tamat berakhir pada skrin **tanpa markah, peratus atau
//     gred** — menanda latihan menjadikan latihan terasa seperti ujian;
//   * setiap pilihan jawapan ada **butang speaker**, dan bunyinya hanya
//     bermula apabila butang itu ditekan (memilih jawapan tidak berbunyi);
//   * kertas percubaan **tiada** butang speaker langsung: kertas sebenar tidak
//     membacakan soalan atau pilihan kepada murid.
//
// Ujian tidak boleh mendengar audio, jadi ia memeriksa niat yang direkod oleh
// `Suara.ayatTerakhir`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/models/kertas.dart';
import 'package:ulangkaji_upkk/screens/kertas_screen.dart';
import 'package:ulangkaji_upkk/screens/latihan_selesai_screen.dart';
import 'package:ulangkaji_upkk/services/suara.dart';
import 'package:ulangkaji_upkk/widgets/butang_pilihan.dart';

import 'bantuan/audio_palsu.dart';
import 'bantuan/saiz_telefon.dart';

/// Kertas dua soalan; pilihan pertama setiap soalan ialah jawapan betul.
///
/// [jenisSumber] menentukan mod: `latihan` (latih tubi) atau `percubaan`.
Kertas _kertas({required String jenisSumber, int bilangan = 2}) {
  return Kertas(
    id: 'uji-latihan',
    subjekId: 'adab',
    tajuk: 'Adab — Ujian',
    sumber: 'Ujian',
    jenisSumber: jenisSumber,
    bahagian: [
      BahagianKertas(
        nama: 'A',
        markah: bilangan * 5,
        arahan: 'بولا تکن جوافن',
        arahanRumi: 'Bulatkan jawapan',
        soalan: [
          for (var i = 0; i < bilangan; i++)
            SoalanKertas(
              id: 'uji-a${i + 1}',
              bahagian: 'A',
              nombor: i + 1,
              jenis: JenisKertas.bulat,
              soalan: 'سأبارا فدوق؟',
              rumi: 'Sabara paduk?',
              markah: 5,
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

/// Lepaskan widget supaya pemasa kertas dan pemasa audio berhenti.
Future<void> _tutup(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(seconds: 3));
  }
}

/// Buka kertas sebagai **laluan baharu** di atas skrin lain.
///
/// Laluan diperlukan untuk menguji butang kembali: tanpa halaman di bawahnya,
/// `pageBack` tiada tempat untuk pulang.
Future<void> _bukaSebagaiLaluan(WidgetTester tester, Kertas kertas) async {
  gunaSaizTelefon(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (konteks) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(konteks).push(
                MaterialPageRoute<void>(
                  builder: (_) => KertasScreen(kertas: kertas),
                ),
              ),
              child: const Text('buka kertas'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('buka kertas'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Tekan "Mula menjawab", jawab soalan pertama dengan pilihan [pilihan].
Future<void> _jawabSatu(WidgetTester tester, {int pilihan = 0}) async {
  await tester.tap(find.text('Mula menjawab'));
  await tester.pump();
  await tester.tap(find.byType(ButangPilihan).at(pilihan));
  await tester.pump();
}

void main() {
  setUpAll(pasangAudioPalsu);

  setUp(() {
    Suara.instance.ayatTerakhir = null;
    Suara.instance.kesanTerakhir = null;
  });

  group('keluar', () {
    testWidgets('latih tubi boleh ditinggalkan tanpa dialog', (tester) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));

      // Latih tubi memaparkan butang X, bukan anak panah kembali: ia bukan
      // kertas yang perlu dihantar. Satu ketukan terus keluar.
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      // Animasi keluar laluan (300 ms) perlu beberapa bingkai sebelum widget
      // benar-benar ditanggalkan daripada pokok.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(
        find.text('Keluar kertas?'),
        findsNothing,
        reason: 'latih tubi bukan kertas — tiada apa yang perlu disahkan',
      );
      expect(
        find.byType(KertasScreen),
        findsNothing,
        reason: 'skrin latihan sepatutnya terus tertutup',
      );
      await _tutup(tester);
    });

    testWidgets('kertas percubaan masih bertanya sebelum keluar', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'percubaan'));

      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('Keluar kertas?'),
        findsOneWidget,
        reason: 'jawapan kertas percubaan yang separuh siap akan hilang',
      );
      await _tutup(tester);
    });

    testWidgets('latih tubi ada butang tutup di bar atas', (tester) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      await _tutup(tester);
    });
  });

  group('tamat latihan', () {
    testWidgets('butang terakhir ialah "Selesai", bukan "Hantar kertas"', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      await _jawabSatu(tester);

      await tester.tap(find.text('Seterusnya'));
      await tester.pump();
      await tester.tap(find.byType(ButangPilihan).at(0));
      await tester.pump();
      await tester.tap(find.text('Seterusnya'));
      await tester.pump();

      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Hantar kertas'), findsNothing);
      await _tutup(tester);
    });

    testWidgets('"Selesai" membuka penutup latihan tanpa markah atau gred', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      await _jawabSatu(tester);

      await tester.tap(find.text('Seterusnya'));
      await tester.pump();
      // Soalan kedua dijawab **salah** supaya skrin penutup ada dua nombor.
      await tester.tap(find.byType(ButangPilihan).at(1));
      await tester.pump();
      await tester.tap(find.text('Seterusnya'));
      await tester.pump();

      await tester.tap(find.text('Selesai'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('Hantar kertas?'),
        findsNothing,
        reason: 'latihan tidak sepatutnya meminta pengesahan seperti kertas',
      );
      expect(find.byType(LatihanSelesaiScreen), findsOneWidget);
      expect(find.text('1 daripada 2 soalan betul'), findsOneWidget);

      // Tiada markah, tiada peratus, tiada cop gred, tiada kad kongsi.
      expect(find.text('GRED'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.text('Kongsi keputusan'), findsNothing);
      expect(find.text('Keputusan'), findsNothing);
      expect(find.textContaining('daripada 70 markah'), findsNothing);
      await _tutup(tester);
    });

    testWidgets('skrin penutup menyenaraikan soalan untuk diulang', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      await _jawabSatu(tester);
      await tester.tap(find.text('Seterusnya'));
      await tester.pump();
      await tester.tap(find.byType(ButangPilihan).at(1));
      await tester.pump();
      await tester.tap(find.text('Seterusnya'));
      await tester.pump();
      await tester.tap(find.text('Selesai'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Soalan untuk diulang'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      await _tutup(tester);
    });
  });

  group('bantuan suara pilihan jawapan', () {
    testWidgets('latih tubi: memilih jawapan tidak berbunyi', (tester) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      await _jawabSatu(tester);

      expect(
        Suara.instance.ayatTerakhir,
        isNull,
        reason: 'memilih jawapan tidak sepatutnya membacakan pilihan itu',
      );
      await _tutup(tester);
    });

    testWidgets('latih tubi: butang speaker membaca pilihan yang ditekan', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();

      final kedua = find.byType(ButangPilihan).at(1);
      final speaker = find.descendant(
        of: kedua,
        matching: find.byIcon(Icons.volume_up_rounded),
      );
      expect(
        speaker,
        findsOneWidget,
        reason: 'setiap pilihan patut ada butang speaker dalam latih tubi',
      );

      await tester.tap(speaker);
      await tester.pump();

      expect(Suara.instance.ayatTerakhir, Suara.kunciPilihan('dua'));
      await _tutup(tester);
    });

    testWidgets('kertas percubaan: tiada butang speaker langsung', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'percubaan'));
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();

      expect(
        find.byIcon(Icons.volume_up_rounded),
        findsNothing,
        reason: 'kertas sebenar tidak membacakan soalan atau pilihan',
      );
      await _tutup(tester);
    });

    testWidgets('kertas percubaan: kunci pilihan tidak pernah diminta', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'percubaan'));
      await _jawabSatu(tester);

      expect(Suara.instance.ayatTerakhir, isNull);
      await _tutup(tester);
    });
  });
}
