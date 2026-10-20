// Kontrak antara penjana suara dan app: **setiap teks yang boleh didengar
// dalam latih tubi mesti ada rakaman**.
//
// Butang speaker pilihan jawapan meminta klip melalui `Suara.kunciPilihan`,
// yang membina kunci daripada teks mentah yang dipaparkan. `tools/jana_suara.py`
// pula membina kunci yang sama semasa menjana klip. Kalau kedua-dua pihak tidak
// bersetuju (contohnya penjana menggunakan teks yang sudah dibersihkan), app
// tidak akan menemui klip itu dan jatuh ke enjin suara peranti — yang **senyap**
// pada kebanyakan iPhone kerana tiada suara Bahasa Melayu.
//
// Ujian ini membaca bank dan manifest terus daripada cakera, jadi ia berjalan
// tanpa Flutter dan tanpa audio.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/models/kertas.dart';
import 'package:ulangkaji_upkk/services/suara.dart';

/// Laluan akar projek — ujian berjalan dari akar projek.
const String _akar = '.';

Map<String, dynamic> _json(String laluan) =>
    jsonDecode(File(laluan).readAsStringSync()) as Map<String, dynamic>;

List<String> _subjekAdaBank() {
  final data = _json('$_akar/assets/content/subjek.json');
  final semua = (data['subjek'] as List)
      .cast<Map<String, dynamic>>()
      .map((s) => s['id'] as String);
  return [
    for (final id in semua)
      if (File('$_akar/assets/content/bank/$id.json').existsSync()) id,
  ];
}

List<SoalanKertas> _bank(String id) {
  final data = _json('$_akar/assets/content/bank/$id.json');
  return (data['soalan'] as List)
      .cast<Map<String, dynamic>>()
      .asMap()
      .entries
      .map(
        (e) => SoalanKertas.dariJson(
          e.value,
          bahagian: (e.value['bahagian'] as String?) ?? '',
          nombor: e.key + 1,
        ),
      )
      .toList();
}

/// Teks yang **disebut** bagi setiap pilihan jawapan dalam satu soalan.
///
/// Salinan peraturan `kertas_screen.dart`: Rumi bagi subjek Jawi (enjin suara
/// Melayu tidak boleh membaca Jawi), teks Arab bagi subjek Bahasa Arab. Ujian
/// ini gagal jika skrin dan penjana tidak lagi sependapat.
List<String> _teksPilihan(SoalanKertas s) {
  final keluar = <String>[];

  void tambah(String teks) {
    if (teks.trim().isNotEmpty) keluar.add(teks.trim());
  }

  for (final it in s.item) {
    tambah(s.jawapanArab ? it.teks : it.rumi);
    for (var j = 0; j < it.pilihan.length; j++) {
      if (s.jawapanArab) {
        tambah(it.pilihan[j]);
      } else if (j < it.pilihanRumi.length) {
        tambah(it.pilihanRumi[j]);
      }
    }
  }
  for (final p in s.pasangan) {
    tambah(s.jawapanArab ? p.kiri : p.kiriRumi);
    tambah(s.jawapanArab ? p.kanan : p.kananRumi);
  }
  for (var i = 0; i < s.urutan.length; i++) {
    tambah(
      s.jawapanArab
          ? s.urutan[i]
          : (i < s.urutanRumi.length ? s.urutanRumi[i] : ''),
    );
  }
  for (var i = 0; i < s.bank.length; i++) {
    tambah(
      s.jawapanArab
          ? s.bank[i]
          : (i < s.bankRumi.length ? s.bankRumi[i] : ''),
    );
  }
  return keluar;
}

void main() {
  final manifest = _json('$_akar/assets/bunyi/suara/manifest.json');
  final fail = (manifest['fail'] as Map).cast<String, String>();

  test('setiap pilihan jawapan ada rakaman', () {
    final tiada = <String>[];

    for (final id in _subjekAdaBank()) {
      for (final s in _bank(id)) {
        for (final teks in _teksPilihan(s)) {
          // Tanda baca sahaja ("?", "!") tidak boleh disebut — butang speaker
          // tidak dipaparkan untuk teks yang tiada huruf atau angka.
          if (!RegExp(r'[0-9A-Za-z\u0600-\u06FF]').hasMatch(teks)) continue;
          final kunci = Suara.kunciPilihan(teks);
          if (!fail.containsKey(kunci)) {
            tiada.add('$id ${s.id}: $teks');
          }
        }
      }
    }

    expect(
      tiada,
      isEmpty,
      reason:
          'Teks ini tiada klip dalam manifest — jalankan '
          '`python3 tools/jana_suara.py`. Tanpa klip, butang speaker '
          'menjadi senyap pada iPhone: ${tiada.take(10).join('; ')}',
    );
  });

  test('setiap fail rakaman yang dirujuk memang wujud', () {
    final hilang = [
      for (final nama in fail.values)
        if (!File('$_akar/assets/bunyi/suara/$nama').existsSync()) nama,
    ];
    expect(hilang, isEmpty, reason: 'fail tiada: ${hilang.take(10).join(', ')}');
  });

  test('setiap soalan ada rakaman', () {
    final tiada = <String>[];
    for (final id in _subjekAdaBank()) {
      for (final s in _bank(id)) {
        if (!fail.containsKey(Suara.kunciSoalan(s.id))) tiada.add('$id ${s.id}');
      }
    }
    expect(tiada, isEmpty, reason: 'soalan tiada klip: ${tiada.take(10).join(', ')}');
  });
}
