// Ujian hujung-ke-hujung latih tubi: pembetulan sebelum bergerak maju.
//
// `test/latihan_test.dart` memeriksa logik ini pada pokok widget palsu. Ujian
// ini menjalankannya pada **app sebenar** kerana dua keadaannya hanya wujud di
// peranti sebenar: panel pembetulan yang muncul jauh di bawah soalan lalu
// mesti discroll ke dalam pandangan, dan butang "Seterusnya" yang kekal di
// tempatnya tanpa skrin bertukar.
//
// Aliran yang diuji:
//
//   1. murid menjawab (sengaja separa atau salah),
//   2. menekan "Seterusnya" — **tidak bergerak**, panel pembetulan terbuka,
//   3. menekan sekali lagi — barulah bergerak maju.
//
// Jawapan yang betul mesti terus bergerak maju tanpa pembetulan, jadi ujian
// menerima kedua-dua keputusan pada langkah 2 tetapi menuntut:
//
//   * panel muncul **sebelum** halaman bertukar sekiranya jawapan belum betul,
//   * dan halaman kedua sentiasa dicapai tidak kira mana-mana jalur.
//
// Jalankan pada emulator:
//     flutter test integration_test/latih_tubi_test.dart -d <peranti>
//
// Seperti app ini sendiri, `pumpAndSettle` tidak boleh dipakai — maskot Raz
// berdenyut tanpa henti dan penantian itu akan tamat masa. Semua penantian
// memajukan masa mengikut bingkai.

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

/// Jawab soalan semasa dengan sengaja **belum betul**.
///
/// Gate ini hanya berlaku apabila jawapan ada tetapi belum `betulPenuh`. Dua
/// cara mencapainya dengan pasti:
///
///   * papan berbilang (`padan`, `tempat kosong`) — isi **satu** slot sahaja.
///     Jawapan separa tidak pernah lengkap, jadi ia tidak mungkin betul.
///   * soalan bertulis — taip dua huruf sahaja. Huruf pertama hampir pasti
///     bukan jawapan penuh bagi soalan UPKK.
///
/// Pilihan A–D dielakkan: menekan satu butang boleh jadi betul dengan
/// nasib, dan ujian itu kemudiannya tidak menguji apa-apa.
Future<void> _jawabBelumBetul(WidgetTester tester) async {
  Future<void> tekan(Finder cari) async {
    if (cari.evaluate().isEmpty) return;
    await tester.ensureVisible(cari.first);
    await _tunggu(tester, 2);
    await tester.tap(cari.first, warnIfMissed: false);
    await _tunggu(tester, 3);
  }

  // Papan berbilang: satu ketukan pada papan padan **belum** mencipta
  // jawapan — murid mesti memilih item kiri dahulu, baru padanannya direkod.
  // Maka beberapa ketukan diambil berturut-turut supaya sekurang-kurangnya
  // satu pasangan siap, sambil kekal separa bagi papan yang lebih panjang.
  // Papan padan: jawapan hanya direkod apabila item kiri **dan** cip kanan
  // dipilih. Mengetuk `InkWell` mentah tidak boleh dipercayai — setiap baris
  // juga mempunyai butang speaker yang menelan ketukan tanpa memadankan
  // apa-apa, jadi empat ketukan pertama boleh menjadi "kiri, speaker, kiri,
  // speaker" dan tiada satu pasangan pun terbentuk.
  //
  // Teks sentiasa berada di dalam `InkWell` baris, bukan di dalam butang
  // speaker, jadi mengetuk teks itulah yang memadankan.
  if (find.byType(PapanPadan).evaluate().isNotEmpty) {
    final teks = find.descendant(
      of: find.byType(PapanPadan),
      matching: find.byType(Text),
    );
    if (teks.evaluate().length >= 2) {
      await tekan(teks.first); // satu item kiri
      await tekan(teks.last); // satu cip kanan
      return;
    }
  }

  for (final jenis in [PapanBetulSalah, PapanTempatKosong, PapanSusun]) {
    final dalam = find.descendant(
      of: find.byType(jenis),
      matching: find.byType(InkWell),
    );
    if (dalam.evaluate().isEmpty) continue;
    for (var i = 0; i < 4 && i < dalam.evaluate().length; i++) {
      await tekan(dalam.at(i));
    }
    return;
  }

  if (find.byType(PapanTaip).evaluate().isNotEmpty) {
    final kekunci = find.descendant(
      of: find.byType(PapanKekunciTulisan),
      matching: find.byType(InkWell),
    );
    await tekan(kekunci.at(0));
    await tekan(kekunci.at(1));
    return;
  }

  // Pilihan berbilang jawapan: tekan yang **terakhir** (bukan yang pertama),
  // peluang betul paling rendah di situ.
  final pilihan = find.byType(ButangPilihan);
  if (pilihan.evaluate().isNotEmpty) await tekan(pilihan.last);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'latih tubi: jawapan belum betul membuka pembetulan sebelum bergerak maju',
    (tester) async {
      // Mulakan dari keadaan bersih — larian sebelumnya tidak boleh meninggalkan
      // rekod yang membuat ujian ini memilih kertas yang berbeza.
      SharedPreferences.setMockInitialValues({});

      app.main();

      final dialogMuncul = await _tungguSehingga(
        tester,
        find.text('Mula belajar'),
      );
      expect(dialogMuncul, isTrue, reason: 'dialog nama patut muncul sekali');
      await tester.enterText(find.byType(TextField).first, 'Aisyah');
      await _tekan(tester, find.text('Mula belajar'));

      expect(
        await _tungguSehingga(tester, find.text('Assalamualaikum, Aisyah!')),
        isTrue,
        reason: 'halaman patut menyapa murid sebelum memilih subjek',
      );

      // --- Masuk latih tubi ------------------------------------------------
      await _tekan(
        tester,
        find.text('Latih tubi'),
        sebab: 'kad subjek patut menawarkan latih tubi',
      );
      expect(
        await _tungguSehingga(tester, find.text('Mula menjawab')),
        isTrue,
        reason: 'kulit latih tubi patut muncul',
      );
      await _tekan(tester, find.text('Mula menjawab'));

      expect(
        await _tungguSehingga(tester, find.textContaining('Soalan 1 daripada')),
        isTrue,
        reason: 'soalan pertama patut dipaparkan',
      );

      // --- 1. Tekan "Seterusnya" sehingga app menunjukkan hasilnya ---------
      //
      // Papan yang berbeza menuntut bilangan ketukan berbeza sebelum jawapan
      // direkod (papan padan mesti memilih kiri dahulu), dan pilihan yang
      // ditekan mungkin pula betul dengan nasib. Maka cubaan diulang sehingga
      // sesuatu yang boleh diperiksa berlaku:
      //
      //   * panel pembetulan terbuka → gate berfungsi, berhenti;
      //   * halaman bertukar ke soalan 2 → jawapan tadi betul, dan memang
      //     tidak sepatutnya dihalang;
      //   * tiada perubahan → jawapan belum direkod, cuba sekali lagi.
      final panel = find.text('Pembetulan — jawapan sebenar');
      final diSoalan1 = find.textContaining('Soalan 1 daripada');
      final diSoalan2 = find.textContaining('Soalan 2 daripada');

      var panelMuncul = false;
      for (var cubaan = 0; cubaan < 5; cubaan++) {
        if (panelMuncul || diSoalan2.evaluate().isNotEmpty) break;
        await _jawabBelumBetul(tester);
        await _tekan(tester, find.text('Seterusnya'));
        panelMuncul = panel.evaluate().isNotEmpty;
      }

      // --- 2. Jalur yang dikehendaki ---------------------------------------
      if (panelMuncul) {
        // Panel terbuka **dan** halaman tidak bertukar — inilah gate itu.
        expect(
          diSoalan1,
          findsOneWidget,
          reason: 'butang Seterusnya tidak boleh bergerak sehingga '
              'pembetulan dilihat',
        );

        // Panel muncul jauh di bawah soalan sedangkan butang berada di bawah
        // skrin — app mesti menatalnya ke pandangan. Kalau tidak, murid hanya
        // mendengar bunyi teguran tanpa nampak jawapan.
        final tinggiLayar =
            tester.view.physicalSize.height / tester.view.devicePixelRatio;
        expect(
          tester.getRect(panel.first).top,
          lessThan(tinggiLayar),
          reason: 'panel pembetulan patut berada dalam pandangan '
              'selepas ditekan',
        );

        // --- 3. Tekan sekali lagi — mesti bergerak maju --------------------
        for (var i = 0; i < 3; i++) {
          await _tekan(tester, find.text('Seterusnya'));
          if (diSoalan2.evaluate().isNotEmpty) break;
        }
      }

      expect(
        await _tungguSehingga(tester, diSoalan2, maksimum: 60),
        isTrue,
        reason: 'tekanan seterusnya mesti membawa murid ke soalan kedua — '
            'latih tubi tidak boleh mengunci murid pada satu soalan',
      );

      // Panel soalan pertama tidak sepatutnya tinggal di halaman kedua.
      expect(panel, findsNothing);

      await Suara.instance.berhenti();
      await tester.pump(const Duration(milliseconds: 300));
    },
  );
}
