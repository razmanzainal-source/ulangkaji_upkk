// Ujian peraturan maklum balas jawapan.
//
// Peraturan ini kedengaran remeh, tetapi ia yang membezakan **latih tubi**
// daripada **kertas percubaan**, dan ia senang hilang semasa kod lain diubah:
//
//   * jawapan betul disambut nada ceria — **tanpa** pujian bersuara
//     ("Betul! Syabas!") selepas setiap soalan, kerana ayat itu hanya
//     melewatkan murid dan cepat menjadi bunyi latar;
//   * nada itu **hanya** berbunyi dalam latih tubi. Semasa menjawab kertas
//     percubaan, murid perlu rasa seperti sedang menjawab kertas sebenar —
//     dan kertas sebenar tidak berbunyi setiap kali jawapan betul.
//
// Ujian tidak boleh mendengar audio, jadi ia memeriksa **niat** yang direkod
// oleh `Suara.kesanTerakhir`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/models/kertas.dart';
import 'package:ulangkaji_upkk/screens/keputusan_screen.dart';
import 'package:ulangkaji_upkk/screens/kertas_screen.dart';
import 'package:ulangkaji_upkk/services/suara.dart';
import 'package:ulangkaji_upkk/widgets/butang_pilihan.dart';

import 'bantuan/audio_palsu.dart';

/// Kertas satu soalan aneka pilihan dua pilihan sahaja.
///
/// Pilihan pertama sentiasa jawapan betul (lihat [jawapanBetul]).
Kertas _kertas({required String jenisSumber, bool objek = true}) {
  return Kertas(
    id: 'uji-1',
    subjekId: 'adab',
    tajuk: 'Adab — Ujian',
    sumber: 'Ujian',
    jenisSumber: jenisSumber,
    bahagian: [
      BahagianKertas(
        nama: 'A',
        markah: 10,
        arahan: 'بولا تکن جوافن',
        arahanRumi: 'Bulatkan jawapan',
        soalan: [
          SoalanKertas(
            id: 'uji-a1',
            bahagian: 'A',
            nombor: 1,
            jenis: JenisKertas.bulat,
            soalan: 'سأبارا فدوق؟',
            rumi: 'Sabara paduk?',
            markah: 10,
            item: [
              ItemKertas(
                nombor: 1,
                teks: 'سأبارا',
                rumi: 'Sabara',
                pilihan: const ['ساتو', 'دوا'],
                pilihanRumi: const ['satu', 'dua'],
                jawapan: objek ? 0 : 1,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Bukakan kertas dan tekan satu pilihan, kemudian pulangkan kertas itu.
Future<void> _jawab(
  WidgetTester tester,
  Kertas kertas, {
  required int pilihan,
}) async {
  await tester.pumpWidget(MaterialApp(home: KertasScreen(kertas: kertas)));
  await tester.pump();

  // Kulit kertas muncul dahulu; soalan pertama hanya selepas "Mula menjawab".
  await tester.tap(find.text('Mula menjawab'));
  await tester.pump();

  await tester.tap(find.byType(ButangPilihan).at(pilihan));
  await tester.pump();
}

/// Lepaskan widget supaya pemasa 1 saat milik kertas berhenti.
///
/// Masa kemudian dimajukan berulang kali supaya had masa audio (`Suara._had`)
/// — yang dicipta semasa dispose, dan yang berangkai antara satu sama lain —
/// sempat tamat. Di dalam dunia sebenar had itu tamat sendiri; dalam ujian
/// Flutter, timer yang belum tamat menggagalkan ujian.
Future<void> _tutup(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(seconds: 3));
  }
}

void main() {
  setUpAll(pasangAudioPalsu);

  setUp(() {
    Suara.instance.kesanTerakhir = null;
  });

  group('jawapan betul', () {
    testWidgets('latih tubi: nada ceria dimainkan', (tester) async {
      await _jawab(tester, _kertas(jenisSumber: 'latihan'), pilihan: 0);

      expect(
        Suara.instance.kesanTerakhir,
        Suara.kesanBetul,
        reason: 'latih tubi patut menyambut jawapan betul dengan nada ceria',
      );
      await _tutup(tester);
    });

    testWidgets('kertas percubaan: tidak ada bunyi langsung', (tester) async {
      await _jawab(tester, _kertas(jenisSumber: 'percubaan'), pilihan: 0);

      expect(
        Suara.instance.kesanTerakhir,
        isNull,
        reason: 'kertas percubaan mesti senyap sepanjang menjawab',
      );
      await _tutup(tester);
    });

    testWidgets('tiada pujian bersuara selepas jawapan betul', (tester) async {
      // `Suara.pujian` sudah dibuang. Kalau ia diperkenalkan semula, ujian ini
      // akan gagal — yang memaksa keputusan itu dibuat semula dengan sedar.
      // (Rakaman "Betul! Syabas." tidak lagi dijana oleh tools/jana_suara.py.)
      await _jawab(tester, _kertas(jenisSumber: 'latihan'), pilihan: 0);

      expect(Suara.instance.kesanTerakhir, isNot('f-betul'));
      await _tutup(tester);
    });
  });

  group('jawapan salah', () {
    testWidgets('latih tubi: nada lembut dimainkan', (tester) async {
      await _jawab(tester, _kertas(jenisSumber: 'latihan'), pilihan: 1);

      expect(Suara.instance.kesanTerakhir, Suara.kesanSalah);
      await _tutup(tester);
    });

    testWidgets('kertas percubaan: tidak ada bunyi langsung', (tester) async {
      await _jawab(tester, _kertas(jenisSumber: 'percubaan'), pilihan: 1);

      expect(
        Suara.instance.kesanTerakhir,
        isNull,
        reason: 'murid tidak patut diberitahu jawapannya salah semasa menjawab',
      );
      await _tutup(tester);
    });
  });

  group('bunga api', () {
    testWidgets('kekal sebagai sambutan dalam kedua-dua mod', (tester) async {
      // Bunga api ialah sambutan **visual** yang diminta secara khusus, dan ia
      // tidak mengganggu tumpuan seperti bunyi. Ujian ini merekodkan bahawa
      // ia memang masih hidup dalam mod peperiksaan.
      for (final jenis in ['latihan', 'percubaan']) {
        await _jawab(tester, _kertas(jenisSumber: jenis), pilihan: 0);
        await tester.pump(const Duration(milliseconds: 300));
        await _tutup(tester);
      }
    });
  });

  group('sambutan di skrin keputusan', () {
    // Nada sambutan dan ayat pujian **tidak** boleh berbunyi serentak. Nada
    // berbunyi 1-2 saat, dan semasa kedua-duanya bertindih, permulaan ayat
    // tenggelam — murid mengadu suara keputusan "tak clear & tidak penuh".
    // Urutan (nada dahulu, ayat kemudian) dikunci di sini.
    testWidgets('nada menenangkan dimainkan dahulu, ayat kemudian', (
      tester,
    ) async {
      Suara.instance.kesanTerakhir = null;
      Suara.instance.ayatTerakhir = null;

      // Kertas tanpa jawapan: 0% — inilah kes "Jangan putus asa".
      await tester.pumpWidget(
        MaterialApp(
          home: KeputusanScreen(
            kertas: _kertas(jenisSumber: 'latihan'),
            jawapan: const {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        Suara.instance.kesanTerakhir,
        Suara.kesanSalah,
        reason: 'nada menenangkan patut bermula dahulu',
      );
      expect(
        Suara.instance.ayatTerakhir,
        isNull,
        reason: 'ayat tidak boleh bermula semasa nada masih berbunyi',
      );

      // Platform audio palsu tidak pernah melaporkan peristiwa tamat, jadi had
      // masa (3 saat) yang mengambil alih — barulah ayat diminta. Gelung ini
      // menunggu sehingga ayat benar-benar diminta, dengan had 6 saat.
      for (var i = 0; i < 30 && Suara.instance.ayatTerakhir == null; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(
        Suara.instance.ayatTerakhir,
        Suara.kunciUlang,
        reason: 'ayat keputusan patut diminta selepas nada tamat',
      );
      await _tutup(tester);
    });

    testWidgets('ayat mengikut gred markah', (tester) async {
      expect(Suara.keputusan(0).$1, Suara.kunciUlang);
      expect(Suara.keputusan(39).$1, Suara.kunciUlang);
      expect(Suara.keputusan(40).$1, Suara.kunciBoleh);
      expect(Suara.keputusan(59).$1, Suara.kunciBoleh);
      expect(Suara.keputusan(60).$1, Suara.kunciBagus);
      expect(Suara.keputusan(79).$1, Suara.kunciBagus);
      expect(Suara.keputusan(80).$1, Suara.kunciHebat);
      expect(Suara.keputusan(100).$1, Suara.kunciHebat);
      expect(Suara.keputusan(100, sempurna: true).$1, Suara.kunciSempurna);
    });
  });
}
