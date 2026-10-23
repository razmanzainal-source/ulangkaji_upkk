// Versi yang dipaparkan pada skrin Info mesti sama dengan versi pubspec.
//
// Tanpa ujian ini, versi di skrin Info senyap-senyap ketinggalan setiap kali
// app dinaikkan versi — dan ibu bapa yang bertanya "versi apa ini?" akan
// mendapat jawapan yang salah.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/screens/info_screen.dart';

void main() {
  test('versi Info sepadan dengan pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final padanan = RegExp(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+',
            multiLine: true)
        .firstMatch(pubspec);
    expect(padanan, isNotNull, reason: 'pubspec.yaml tiada baris version:');
    expect(InfoScreen.versi, padanan!.group(1));
  });
}
