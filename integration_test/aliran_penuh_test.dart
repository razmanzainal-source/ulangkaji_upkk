// Ujian hujung-ke-hujung: satu perjalanan penuh melalui app.
//
// Ujian unit memeriksa bahagian satu demi satu, tetapi ia tidak pernah melihat
// app **berjalan**. Ujian ini membuka app sebenar pada emulator dan melalui
// jalan yang dilalui murid: beri nama, pilih subjek, jawab latih tubi, hantar,
// dan kongsi keputusan. Ia menangkap perkara yang tidak dapat dilihat oleh
// ujian unit — skrin yang tersekat, butang yang tidak boleh ditekan, papan
// kekunci yang tidak muncul, dan penangkapan gambar yang gagal pada peranti.
//
// Jalankan pada emulator:
//     flutter test integration_test/aliran_penuh_test.dart -d <peranti>
//
// Nota penting: `pumpAndSettle` **tidak boleh** dipakai dalam app ini. Maskot
// Upik berdenyut tanpa henti, jadi pokok widget tidak pernah "tenang" dan
// `pumpAndSettle` akan tamat masa. Semua penantian di sini memajukan masa
// mengikut bingkai.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulangkaji_upkk/main.dart' as app;
import 'package:ulangkaji_upkk/services/suara.dart';
import 'package:ulangkaji_upkk/widgets/butang_pilihan.dart';
import 'package:ulangkaji_upkk/widgets/papan_betul_salah.dart';
import 'package:ulangkaji_upkk/widgets/papan_kekunci_tulisan.dart';
import 'package:ulangkaji_upkk/widgets/papan_padan.dart';
import 'package:ulangkaji_upkk/widgets/papan_susun.dart';
import 'package:ulangkaji_upkk/widgets/papan_taip.dart';
import 'package:ulangkaji_upkk/widgets/papan_tempat_kosong.dart';

/// Satu bingkai ujian (120 ms).
const Duration _bingkai = Duration(milliseconds: 120);

/// Majukan [bilangan] bingkai.
Future<void> _tunggu(WidgetTester tester, [int bilangan = 8]) async {
  for (var i = 0; i < bilangan; i++) {
    await tester.pump(_bingkai);
  }
}

/// Majukan masa sehingga [cari] muncul, atau sehingga [maksimum] bingkai habis.
///
/// Menunggu keadaan lebih kukuh daripada tidur tetap: memuatkan bank soalan di
/// dalam emulator mengambil masa yang berbeza-beza, dan ujian yang menunggu
/// "cukup lama" akan gagal pada mesin yang perlahan.
Future<bool> _tungguSehingga(
  WidgetTester tester,
  Finder cari, {
  int maksimum = 200,
}) async {
  for (var i = 0; i < maksimum; i++) {
    if (cari.evaluate().isNotEmpty) return true;
    await tester.pump(_bingkai);
  }
  return cari.evaluate().isNotEmpty;
}

/// Pastikan [cari] kelihatan, kemudian tekan.
Future<void> _tekan(WidgetTester tester, Finder cari, {String? sebab}) async {
  expect(cari, findsWidgets, reason: sebab ?? 'butang tidak dijumpai');
  await tester.ensureVisible(cari.first);
  await _tunggu(tester);
  await tester.tap(cari.first, warnIfMissed: false);
  await _tunggu(tester);
}

/// Tekan beberapa elemen boleh tekan di dalam satu papan jawapan.
///
/// Soalan kertas UPKK ada enam jenis papan (pilihan, betul/salah, padan,
/// susun, tempat kosong, taip). Daripada menulis enam jalan berasingan, ujian
/// ini menekan sehingga empat elemen boleh tekan di dalam papan itu — cukup
/// untuk membuktikan papan itu **hidup** dan boleh dijawab.
Future<void> _cubaJawab(WidgetTester tester) async {
  const papan = <Type>[
    PapanBetulSalah,
    PapanPadan,
    PapanSusun,
    PapanTempatKosong,
  ];

  // Tekan [cari] selepas memastikan ia benar-benar kelihatan.
  //
  // `ensureVisible` bukan hiasan: papan jawapan boleh lebih tinggi daripada
  // skrin, dan menekan unsur di luar viewport menghantar ketukan itu ke **bar
  // navigasi** di bawah — "Sebelum" atau "Seterusnya" ikut tertekan dan
  // halaman melompat ke belakang, menyebabkan ujian berpusing tanpa habis.
  Future<void> tekan(Finder cari) async {
    if (cari.evaluate().isEmpty) return;
    await tester.ensureVisible(cari.first);
    await _tunggu(tester, 2);
    await tester.tap(cari.first, warnIfMissed: false);
    await _tunggu(tester, 3);
  }

  for (final jenis in papan) {
    final dalam = find.descendant(
      of: find.byType(jenis),
      matching: find.byType(InkWell),
    );
    if (dalam.evaluate().isEmpty) continue;

    // Bilangan elemen boleh tekan **berubah** semasa menjawab: papan padan
    // membuang pasangan yang sudah dipadankan. Jadi kiraan diambil semula
    // pada setiap pusingan, bukan sekali di awal.
    for (var i = 0; i < 4; i++) {
      if (i >= dalam.evaluate().length) break;
      await tekan(dalam.at(i));
    }
    return;
  }

  // Aneka pilihan: tekan pilihan pertama sahaja (pilihan seterusnya akan
  // menggantikannya, jadi menekan banyak kali tidak berguna).
  await tekan(find.byType(ButangPilihan));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('perjalanan penuh murid: nama, latih tubi, keputusan, kongsi', (
    tester,
  ) async {
    // Mulakan dari keadaan bersih: tiada nama, tiada rekod kemajuan. Tanpa ini
    // ujian bergantung pada data yang tertinggal daripada larian sebelumnya.
    SharedPreferences.setMockInitialValues({});

    app.main();

    // --- 1. Nama ---------------------------------------------------------
    final dialogMuncul = await _tungguSehingga(
      tester,
      find.text('Mula belajar'),
    );
    expect(
      dialogMuncul,
      isTrue,
      reason: 'dialog nama sepatutnya muncul kali pertama app dibuka',
    );

    await tester.enterText(find.byType(TextField).first, 'Aisyah');
    await _tekan(tester, find.text('Mula belajar'));

    expect(
      await _tungguSehingga(tester, find.text('Assalamualaikum, Aisyah!')),
      isTrue,
      reason: 'kepala halaman patut menyapa murid dengan namanya',
    );

    // --- 2. Pilih subjek dan mula latih tubi ------------------------------
    expect(
      find.text('Latih tubi'),
      findsWidgets,
      reason: 'kad subjek patut menawarkan latih tubi',
    );
    await _tekan(tester, find.text('Latih tubi'));

    expect(
      await _tungguSehingga(tester, find.text('Mula menjawab')),
      isTrue,
      reason: 'kulit kertas latih tubi patut muncul',
    );
    await _tekan(tester, find.text('Mula menjawab'));

    // --- 3. Jawab soalan -------------------------------------------------
    // Bilangan soalan tidak dipasak: gelung berhenti apabila halaman semakan
    // muncul, jadi perubahan bilangan soalan latih tubi tidak memecahkan ujian.
    for (var soalan = 1; soalan <= 15; soalan++) {
      if (find.text('Semak jawapan').evaluate().isNotEmpty) break;

      // Soalan bertulis mesti membuka papan kekunci Jawi/Arab **tanpa** murid
      // perlu menekan medan jawapan dahulu — murid Tahun 5 tidak sepatutnya
      // terpaksa meneka cara menaip Jawi.
      if (find.byType(PapanTaip).evaluate().isNotEmpty) {
        expect(
          find.byType(PapanKekunciTulisan),
          findsOneWidget,
          reason: 'soalan bertulis $soalan patut membuka papan kekunci sendiri',
        );

        // Semua `InkWell` di dalam papan kekunci ialah kekunci (huruf, tukar
        // halaman, hapus, siap) — kepala papan kekunci dengan butang tutup
        // berada di luarnya, jadi menekan yang pertama tidak menutupnya.
        final kekunci = find.descendant(
          of: find.byType(PapanKekunciTulisan),
          matching: find.byType(InkWell),
        );
        await tester.tap(kekunci.at(0), warnIfMissed: false);
        await _tunggu(tester, 3);
        await tester.tap(kekunci.at(1), warnIfMissed: false);
        await _tunggu(tester, 3);
        // "Siap" menyerahkan jawapan. Ketika inilah nada ceria dan bunga api
        // dimainkan — dalam latih tubi sahaja.
        await tester.tap(find.text('سياڤ').first, warnIfMissed: false);
        await _tunggu(tester, 6);
      } else {
        await _cubaJawab(tester);
      }

      final seterusnya = find.text('Seterusnya');
      if (seterusnya.evaluate().isEmpty) break;
      await _tekan(tester, seterusnya);
    }

    // --- 4. Semak dan hantar ---------------------------------------------
    // "Semak jawapan" muncul dua kali: sebagai sari kata bar atas, dan sebagai
    // tajuk halaman. Jadi bilangan widget tidak boleh dituntut.
    expect(find.text('Semak jawapan'), findsWidgets);
    expect(find.text('Hantar kertas'), findsOneWidget);
    await _tekan(tester, find.text('Hantar kertas'));

    // Kertas yang belum lengkap meminta pengesahan dahulu; kertas yang lengkap
    // terus dihantar. Kedua-duanya mesti berfungsi.
    if (await _tungguSehingga(
      tester,
      find.text('Hantar kertas?'),
      maksimum: 10,
    )) {
      await _tekan(tester, find.text('Hantar'));
    }

    // --- 5. Keputusan -----------------------------------------------------
    expect(
      await _tungguSehingga(tester, find.text('Keputusan')),
      isTrue,
      reason: 'skrin keputusan patut muncul selepas kertas dihantar',
    );
    // Kad markah berbunyi "X daripada Y markah". (Kertas latih tubi bukan
    // kertas penuh 70 markah, jadi jumlahnya tidak boleh dituntut.)
    expect(find.textContaining('daripada'), findsWidgets);

    // --- 6. Kongsi --------------------------------------------------------
    // Butang kongsi berada di **hujung** senarai keputusan. `ListView` hanya
    // membina anak yang hampir kelihatan, jadi butang itu belum wujud dalam
    // pokok widget dan tidak boleh dicari terus — ia mesti digulung masuk
    // dahulu, sama seperti yang dilakukan oleh murid.
    final butangKongsi = find.text('Kongsi keputusan');
    await tester.dragUntilVisible(
      butangKongsi,
      find.byType(ListView).first,
      const Offset(0, -300),
      maxIteration: 40,
    );
    expect(
      butangKongsi,
      findsOneWidget,
      reason: 'butang kongsi patut muncul selepas senarai digulung',
    );

    // Langkah ini menangkap kad keputusan sebagai gambar pada peranti sebenar —
    // bahagian yang paling senang rosak, dan yang tidak dapat diuji oleh ujian
    // widget kerana `dart:ui` tidak melukis dalam ujian unit.
    await _tekan(tester, butangKongsi);

    expect(
      await _tungguSehingga(tester, find.text('Simpan gambar'), maksimum: 80),
      isTrue,
      reason: 'skrin kongsi patut memaparkan gambar keputusan yang ditangkap',
    );
    expect(find.text('Kongsi'), findsOneWidget);
    expect(
      find.byType(Image),
      findsWidgets,
      reason: 'gambar kad keputusan patut benar-benar dilukis',
    );

    // Rakaman ayat keputusan masih berbunyi pada ketika ini (ia 6 saat). Hentikan
    // sebelum ujian tamat: `audioplayers` menyimpan pembantu kedudukan yang
    // menjadualkan bingkai selagi audio bermain, dan bingkai yang tinggal selepas
    // widget dibuang menggagalkan ujian. Dalam app sebenar `Suara` hidup
    // sepanjang hayat app, jadi ini hanya kemasan ujian.
    await Suara.instance.berhenti();
    await tester.pump(const Duration(milliseconds: 300));
  });
}
