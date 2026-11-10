// Menjana tangkapan skrin skrin tip untuk "Review Information" App Store
// Connect (setiap in-app purchase mesti ada screenshot semasa semakan).
//
// Jalankan:
//   flutter test tool/tangkap_tip_test.dart
// Hasil: edaran/store/play/tip-review.png (1290 x 2796)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/screens/ibu_bapa_screen.dart';
import 'package:ulangkaji_upkk/services/pembelian.dart';

const _keluar = 'edaran/store/play/tip-review.png';

Future<void> _muatFon(String keluarga, List<String> calon) async {
  for (final laluan in calon) {
    final f = File(laluan);
    if (!f.existsSync()) continue;
    final bytes = f.readAsBytesSync();
    final loader = FontLoader(keluarga)
      ..addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
    await loader.load();
    return;
  }
}

const _fonSdk = '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('jana tip-review.png', (tester) async {
    await _muatFon('Roboto', [
      '$_fonSdk/Roboto-Regular.ttf',
      '/System/Library/Fonts/Supplemental/Arial.ttf',
    ]);
    await _muatFon('MaterialIcons', [
      '$_fonSdk/MaterialIcons-Regular.otf',
    ]);

    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // Produk palsu supaya tiga butang tip dipaparkan seperti selepas produk
    // tip diluluskan di kedai.
    Pembelian.instance.idAktif.value = {
      3: 'com.razmanzainal.ulangkajiUpkk.tip3',
      5: 'com.razmanzainal.ulangkajiUpkk.tip5',
      10: 'com.razmanzainal.ulangkajiUpkk.tip10',
    };
    Pembelian.instance.harga.value = {
      '3': 'RM 3.00',
      '5': 'RM 5.00',
      '10': 'RM 10.00',
    };
    Pembelian.instance.kedaiTersedia.value = true;
    addTearDown(() {
      Pembelian.instance.idAktif.value = {};
      Pembelian.instance.harga.value = {};
      Pembelian.instance.kedaiTersedia.value = false;
    });

    final kunci = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: RepaintBoundary(
          key: kunci,
          child: const IbuBapaScreen(),
        ),
      ),
    );
    await tester.pump();

    // Lepasi gerbang matematik.
    final teks = tester
        .widgetList<Text>(find.textContaining('Berapakah'))
        .first
        .data!;
    final m = RegExp(r'(\d+)\s*\+\s*(\d+)').firstMatch(teks)!;
    final jawapan =
        (int.parse(m.group(1)!) + int.parse(m.group(2)!)).toString();
    await tester.enterText(
        find.byKey(const ValueKey('gerbang-jawapan')), jawapan);
    await tester.tap(find.byKey(const ValueKey('gerbang-teruskan')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }

    final boundary =
        kunci.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final imej = await boundary.toImage(pixelRatio: 3.0);
    final data = await imej.toByteData(format: ui.ImageByteFormat.png);
    final fail = File(_keluar);
    fail.parent.createSync(recursive: true);
    fail.writeAsBytesSync(data!.buffer.asUint8List());
    // ignore: avoid_print
    print('Ditulis: ${fail.absolute.path} (${data.lengthInBytes} bait)');

    // Hentikan animasi maskot supaya ujian boleh tamat.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
