// Papan padanan (`suai`) — membetulkan padanan yang salah.
//
// Bug yang dikunci di sini: setelah semua item kanan terpakai, **tiada** cip
// kanan yang boleh diketuk, jadi murid tidak boleh membetulkan padanan yang
// salah. Pada papan versi lama, item kanan yang sudah dipadankan
// dilumpuhkan sepenuhnya (`onTap: null`), jadi:
///
///   * padanan yang salah tidak boleh **dibuang** — hanya boleh ditukar
//     dengan padanan lain, dan tiada padanan lain yang tinggal; dan
//   * dua item yang tersalah bertukar tempat tidak boleh dibetulkan langsung.
//
// Ujian ini mengunci tiga perkara: padanan boleh dibuang, cip kanan yang
// sudah terpakai boleh **dipindah**, dan butang silang pada nota padanan
// membuang padanan itu.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ulangkaji_upkk/widgets/papan_padan.dart';

/// Satu papan padanan dengan tiga item kiri dan tiga item kanan.
class _Ujian extends StatefulWidget {
  const _Ujian();

  @override
  State<_Ujian> createState() => _UjianState();
}

class _UjianState extends State<_Ujian> {
  final Map<int, int> padanan = {};
  int? terpilih;
  int buangCalled = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PapanPadan(
        kiri: const ['Kiri 1', 'Kiri 2', 'Kiri 3'],
        kanan: const ['Kanan A', 'Kanan B', 'Kanan C'],
        indeksKanan: const [0, 1, 2],
        padanan: padanan,
        warna: const Color(0xFFD81B60),
        terpilih: terpilih,
        onPilihKiri: (i) => setState(() => terpilih = i),
        onPilihKanan: (asal) {
          setState(() {
            final kiri = terpilih;
            if (kiri == null) return;
            if (padanan[kiri] == asal) {
              padanan.remove(kiri);
            } else {
              padanan.removeWhere((_, k) => k == asal);
              padanan[kiri] = asal;
            }
            terpilih = null;
          });
        },
        onBuangPadanan: (i) => setState(() {
          buangCalled = i;
          padanan.remove(i);
          terpilih = null;
        }),
      ),
    );
  }
}

void main() {
  // Papan dipaparkan pada skrin telefon yang tinggi — tanpa ini, baris
  // item ketiga berada di luar kawasanгляди paparan dan ketukan terhuyat.
  void skrinTinggi(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('padanan boleh dibuang dengan mengetiknya semula', (tester) async {
    skrinTinggi(tester);
    await tester.pumpWidget(const MaterialApp(home: _Ujian()));

    // Kiri 1 -> Kanan A
    await tester.tap(find.text('Kiri 1'));
    await tester.pump();
    await tester.tap(find.descendant(of: find.byType(Wrap), matching: find.text('Kanan A')));
    await tester.pump();

    // Ketik semula Kiri 1, kemudian Kanan A — padanan dibuang.
    await tester.tap(find.text('Kiri 1'));
    await tester.pump();
    await tester.tap(find.descendant(of: find.byType(Wrap), matching: find.text('Kanan A')));
    await tester.pump();

    final papan = tester.widget<PapanPadan>(find.byType(PapanPadan));
    expect(papan.padanan, isEmpty);
  });

  testWidgets('cip kanan yang sudah terpakai boleh dipindah', (tester) async {
    skrinTinggi(tester);
    await tester.pumpWidget(const MaterialApp(home: _Ujian()));

    // Kiri 1 -> Kanan A, Kiri 2 -> Kanan B. Semua kini terpakai.
    await tester.tap(find.text('Kiri 1'));
    await tester.pump();
    await tester.tap(find.descendant(of: find.byType(Wrap), matching: find.text('Kanan A')));
    await tester.pump();
    await tester.tap(find.text('Kiri 2'));
    await tester.pump();
    await tester.tap(find.descendant(of: find.byType(Wrap), matching: find.text('Kanan B')));
    await tester.pump();

    // Kiri 3 mengambil Kanan A daripada Kiri 1.
    await tester.tap(find.text('Kiri 3'));
    await tester.pump();
    await tester.tap(find.descendant(of: find.byType(Wrap), matching: find.text('Kanan A')));
    await tester.pump();

    // Indeks kiri bermula dari 0: Kiri 1 = 0, Kiri 2 = 1, Kiri 3 = 2.
    final papan = tester.widget<PapanPadan>(find.byType(PapanPadan));
    // Kiri 3 (indeks 2) mengambil Kanan A (indeks 0) daripada Kiri 1.
    expect(papan.padanan[2], 0);
    // Kiri 1 kehilangan padanannya, dan Kiri 2 kekal dengan Kanan B.
    expect(papan.padanan.containsKey(0), isFalse);
    expect(papan.padanan[1], 1);
  });

  testWidgets('butang silang membuang padanan', (tester) async {
    skrinTinggi(tester);
    await tester.pumpWidget(const MaterialApp(home: _Ujian()));

    await tester.tap(find.text('Kiri 1'));
    await tester.pump();
    await tester.tap(find.descendant(of: find.byType(Wrap), matching: find.text('Kanan A')));
    await tester.pump();

    // Butang silang pada nota padanan di bawah item kiri.
    await tester.tap(find.byTooltip('Buang padanan'));
    await tester.pump();

    final papan = tester.widget<PapanPadan>(find.byType(PapanPadan));
    expect(papan.padanan, isEmpty);
  });
}
