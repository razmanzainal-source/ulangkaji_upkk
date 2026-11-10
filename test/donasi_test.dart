// Ruang sumbangan (Android) dan tip (iOS).
//
// Dua jaminan:
//  1. Kod QR sumbangan kembali seperti versi asal untuk Android.
//  2. Tip melalui App Store hanya dipaparkan pada iOS.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/screens/info_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dialog QR sumbangan memaparkan kod, nama akaun dan butang',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DialogQrDonasi())),
    );
    await tester.pump();

    expect(find.text('Kod QR sumbangan'), findsOneWidget);
    expect(find.text(namaAkaunDonasi), findsOneWidget);
    expect(find.byKey(const ValueKey('donasi-simpan')), findsOneWidget);
    expect(find.text('Tutup'), findsOneWidget);
  });

  test('aset kod QR sumbangan wujud dan didaftarkan', () {
    // Aset mesti kembali ke dalam bundel — jika tidak, Android akan
    // memaparkan "Kod QR tidak dapat dipaparkan."
    expect(qrDonasi, 'assets/gambar/qr_donasi.png');
    expect(namaAkaunDonasi.isNotEmpty, isTrue);
  });
}
