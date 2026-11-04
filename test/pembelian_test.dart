// Gerbang ibu bapa dan kunci Versi Penuh.
//
// Apple (Kids Category) membenarkan peluang pembelian dalam app kanak-kanak
// hanya di belakang gerbang ibu bapa. Ujian ini memastikan gerbang itu benar-
// benar menghalang, dan bahawa jawapan salah tidak membuka kedai.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/screens/ibu_bapa_screen.dart';
import 'package:ulangkaji_upkk/services/pembelian.dart';
import 'package:ulangkaji_upkk/tema.dart';

Widget _balut(Widget anak) => MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: anak,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Pembelian.instance.tetapkanUntukUjian(terbuka: false);
  });

  testWidgets('belum beli: gerbang ibu bapa dipaparkan, bukan kedai',
      (tester) async {
    await tester.pumpWidget(_balut(Builder(
      builder: (context) => TextButton(
        onPressed: () => pastikanVersiPenuh(context),
        child: const Text('Buka'),
      ),
    )));

    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();

    expect(find.text('Kawasan khas ibu bapa'), findsOneWidget);
    expect(find.byKey(const ValueKey('beli-penuh')), findsNothing);
  });

  testWidgets('jawapan salah tidak membuka kedai', (tester) async {
    await tester.pumpWidget(_balut(const IbuBapaScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('gerbang-jawapan')), '1');
    await tester.tap(find.byKey(const ValueKey('gerbang-teruskan')));
    await tester.pumpAndSettle();

    expect(find.text('Jawapan tidak tepat. Cuba lagi.'), findsOneWidget);
    expect(find.byKey(const ValueKey('beli-penuh')), findsNothing);
  });

  testWidgets('jawapan betul membuka kedai Versi Penuh', (tester) async {
    await tester.pumpWidget(_balut(const IbuBapaScreen()));
    await tester.pumpAndSettle();

    // Baca soalan yang dijana: "Berapakah 14 × 7 ?"
    final teks = tester
        .widgetList<Text>(find.textContaining('Berapakah'))
        .first
        .data!;
    final nombor = RegExp(r'(\d+)\s*×\s*(\d+)').firstMatch(teks)!;
    final jawapan =
        (int.parse(nombor.group(1)!) * int.parse(nombor.group(2)!)).toString();

    await tester.enterText(
        find.byKey(const ValueKey('gerbang-jawapan')), jawapan);
    await tester.tap(find.byKey(const ValueKey('gerbang-teruskan')));
    // Maskot berdenyut tanpa henti, jadi `pumpAndSettle` tidak boleh dipakai.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Versi Penuh'), findsOneWidget);
    expect(find.byKey(const ValueKey('beli-penuh')), findsOneWidget);
    expect(find.byKey(const ValueKey('pulihkan-pembelian')), findsOneWidget);
  });

  testWidgets('sudah beli: tiada gerbang dipaparkan', (tester) async {
    Pembelian.instance.tetapkanUntukUjian(terbuka: true);
    bool? hasil;

    await tester.pumpWidget(_balut(Builder(
      builder: (context) => TextButton(
        onPressed: () async {
          hasil = await pastikanVersiPenuh(context);
        },
        child: const Text('Buka'),
      ),
    )));

    await tester.tap(find.text('Buka'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(hasil, isTrue);
    expect(find.text('Kawasan khas ibu bapa'), findsNothing);
  });

  test('ID produk kedua-dua kedai sama', () {
    expect(Pembelian.idProduk, 'ulangkaji_upkk_full');
    expect(Pembelian.kunciSimpan, 'pembelian_penuh');
  });

  test('warna tema tersedia untuk skrin pembelian', () {
    expect(Warna.utama, isNotNull);
  });
}
