// Saiz skrin telefon sebenar untuk ujian widget.
//
// Ujian widget secara lalai melukis pada 800 × 600 — saiz desktop. Susun atur
// yang limpah pada telefon boleh kelihatan **elok** pada 800 × 600: baris yang
// tidak cukup lebar, kad yang terlalu tinggi, atau teks Jawi yang panjang.
// Murid tidak akan melaporkan "RenderFlex overflowed"; dia hanya nampak jalur
// kuning-hitam.
//
// Jadi setiap ujian yang membuka skrin sebenar menetapkan saiz telefon dahulu.
// Saiz ini diambil daripada telefon terbesar yang disasarkan (iPhone Pro Max);
// skrin yang elok di sini juga elok pada telefon yang lebih kecil, kerana
// kebanyakan susun atur app menatal secara menegak.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Saiz logik telefon sasaran (lebar × tinggi).
const Size saizTelefon = Size(430, 932);

/// Nisbah piksel peranti bagi [saizTelefon].
const double _nisbahPiksel = 3;

/// Gunakan saiz telefon untuk ujian ini, dan pulihkan selepas ujian tamat.
void gunaSaizTelefon(WidgetTester tester) {
  tester.view.physicalSize = saizTelefon * _nisbahPiksel;
  tester.view.devicePixelRatio = _nisbahPiksel;
  addTearDown(tester.view.reset);
}
