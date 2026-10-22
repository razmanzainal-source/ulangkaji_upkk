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

  // Soalan "betul salah" menyebut perkataan "Betul" atau "Salah" — tanda
  // ✓/✗ tidak boleh dibacakan oleh enjin suara.
  //
  // Tiga perkara di sini mudah pecah tanpa disedari:
  //
  //   1. Kunci yang diminta app mesti sama dengan kunci yang dijana
  //      penjana. Kalau tidak, app jatuh ke enjin suara **peranti** — dan
  //      bunyi itu robotik ("pelek"), berbeza dengan rekaman Yasmin yang
  //      dipakai di seluruh app.
  //   2. "Betul" dan "Salah" mesti **sentiasa** dibaca dengan suara Melayu.
  //      Subjek Bahasa Arab membaca soalannya dengan suara Arab, dan
  //      "Betul" yang dibaca dengan sebutan Arab kedengaran teruk.
  //   3. Setiap segmen jawapan — termasuk nombor item — mesti ada
  //      rakaman, kalau tidak butang speaker senyap.
  group('soalan betul salah', () {
    /// Semua soalan `betul_salah` daripada bank latihan dan kertas sebenar.
    List<SoalanKertas> semua() {
      final keluar = <SoalanKertas>[];

      for (final id in _subjekAdaBank()) {
        keluar.addAll(_bank(id));
      }

      final dir = Directory('$_akar/assets/content/sebenar');
      if (dir.existsSync()) {
        // Bahasa datang daripada **subjek**, bukan daripada fail kertas —
        // sama seperti `BankKertas._tambahBahasa`. Tanpa itu, kertas Bahasa
        // Arab akan kelihatan Rumi, dan klip yang diminta tidak pernah dijana.
        final bahasaSubjek = <String, String>{
          for (final s in _json('$_akar/assets/content/subjek.json')['subjek']
              as List)
            (s as Map<String, dynamic>)['id'] as String:
                s['bahasa'] as String? ?? 'jawi',
        };

        for (final failJson in dir.listSync().whereType<File>()) {
          if (!failJson.path.endsWith('.json')) continue;
          final data = _json(failJson.path);
          final subjekId = (data['subjek'] as String? ?? '').toLowerCase();
          final bahasa = bahasaSubjek[subjekId] ?? 'jawi';
          for (final b in (data['bahagian'] as List? ?? const [])) {
            for (final s in (b['soalan'] as List? ?? const [])) {
              (s as Map<String, dynamic>)['bahasa'] = bahasa;
              keluar.add(
                SoalanKertas.dariJson(
                  s,
                  bahagian: (b['nama'] as String?) ?? '',
                  nombor: 1,
                ),
              );
            }
          }
        }
      }
      return keluar;
    }

    List<SoalanKertas> betulSalah() =>
        semua().where((s) => s.jenis == JenisKertas.betulSalah).toList();

    test('perkataan "Betul" dan "Salah" ada rakaman', () {
      expect(
        fail.containsKey(Suara.kunciPilihan('Betul')),
        isTrue,
        reason: 'Klip "Betul" tiada — jalankan `python3 tools/jana_suara.py`.',
      );
      expect(
        fail.containsKey(Suara.kunciPilihan('Salah')),
        isTrue,
        reason: 'Klip "Salah" tiada — jalankan `python3 tools/jana_suara.py`.',
      );
    });

    test('setiap segmen jawapan ada rakaman', () {
      final tiada = <String>[];
      for (final s in betulSalah()) {
        for (final baris in s.jawapanDengarSegmen) {
          for (final segmen in baris) {
            if (segmen.trim().isEmpty) continue;
            if (!RegExp(r'[0-9A-Za-z\u0600-\u06FF]').hasMatch(segmen)) continue;
            if (!fail.containsKey(Suara.kunciPilihan(segmen))) {
              tiada.add('${s.id}: $segmen');
            }
          }
        }
      }
      expect(
        tiada,
        isEmpty,
        reason:
            'Segmen ini tiada klip dalam manifest — bunyinya akan jatuh ke '
            'enjin suara peranti yang robotik: ${tiada.take(10).join('; ')}',
      );
    });

    test('perkataan "Betul" dan "Salah" muncul sebagai segmen berasingan', () {
      // Kalau digabungkan dengan teks lain ("Asy-Salam — Betul"), kunci
      // `o-` tidak pernah dijana dan bunyinya robotik.
      for (final s in betulSalah()) {
        for (final baris in s.jawapanDengarSegmen) {
          expect(
            baris.where((x) => x == 'Betul' || x == 'Salah'),
            isNotEmpty,
            reason:
                '${s.id}: baris jawapan tidak mengandungi "Betul"/"Salah" '
                'sebagai segmen berasingan: $baris',
          );
        }
      }
    });
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

  // Medan `audio` pada bank menukar suara bagi klip tertentu — lihat `_teks`
  // dalam `tools/jana_suara.py`. Ia sengaja bukan sebahagian daripada model
  // Dart: app meminta kunci yang sama seperti biasa dan penjana menyambung
  // segmen berlainan suara menjadi satu fail. Sebab itu tiada ujian model
  // yang mengesahkannya, jadi ujian ini membaca medan mentah dan menegakkan
  // syarat yang penjana perlukan.
  group('penanda audio bercampur', () {
    /// Blok tulisan Arab. Segmen yang dibaca oleh suara Melayu mesti
    /// **bebas** daripada tulisan ini, kalau tidak `bersih()` akan
    /// membuangnya sehingga klip menjadi senyap.
    final RegExp blokArab = RegExp(r'[\u0600-\u06FF]');

    /// Soalan mentah (belum ditukar kepada `SoalanKertas`, yang tidak
    /// memegang medan `audio`).
    List<Map<String, dynamic>> bankMentah(String id) =>
        (_json('$_akar/assets/content/bank/$id.json')['soalan'] as List)
            .cast<Map<String, dynamic>>();

    /// Teks yang sepadan bagi satu medan bercampur, dalam bentuk senarai
    /// baris seperti `jawapanContohRumi`.
    List<String> barisRumi(Map<String, dynamic> s, String medan) =>
        medan == 'soalan'
            ? [s['rumi'] as String]
            : (s['${medan}Rumi'] as List).cast<String>();

    List<MapEntry<String, Map<String, dynamic>>> bertanda() {
      final keluar = <MapEntry<String, Map<String, dynamic>>>[];
      for (final id in _subjekAdaBank()) {
        for (final s in bankMentah(id)) {
          final audio = s['audio'];
          if (audio != null) {
            keluar.add(MapEntry(s['id'] as String, audio as Map<String, dynamic>));
          }
        }
      }
      return keluar;
    }

    test('hanya mod yang dikenali boleh ditulis', () {
      final salah = <String>[];
      for (final e in bertanda()) {
        e.value.forEach((medan, mod) {
          final m = mod as String;
          final sah =
              m == 'melayu' || (m.startsWith('pisah') && m.length > 'pisah'.length);
          if (!sah) salah.add('${e.key}.$medan=$m');
        });
      }
      expect(
        salah,
        isEmpty,
        reason:
            'Mod ini ditafsir secara senyap oleh penjana: ${salah.join('; ')}',
      );
    });

    test('pembahagian tidak membuang teks dan mengekalkan segmen Melayu', () {
      final salah = <String>[];
      for (final id in _subjekAdaBank()) {
        for (final s in bankMentah(id)) {
          final audio = s['audio'];
          if (audio == null) continue;
          for (final e in (audio as Map).entries) {
            final medan = e.key as String;
            final mod = e.value as String;
            if (!mod.startsWith('pisah')) continue;
            final dl = mod.substring('pisah'.length);

            if (medan == 'soalan') {
              final ar = s['soalan'] as String;
              if (!ar.contains(dl) || !barisRumi(s, medan).first.contains(dl)) {
                salah.add('${s['id']}: penanda $dl tiada pada kedua-dua belah');
                continue;
              }
              final kiri = ar.split(dl).first.trim();
              final kanan = barisRumi(s, medan).first.split(dl).last.trim();
              if (kiri.isEmpty || kanan.isEmpty) {
                salah.add('${s['id']}: ada segmen kosong');
              } else if (blokArab.hasMatch(kanan)) {
                salah.add('${s['id']}: segmen Melayu masih bertulis Arab');
              }
            } else {
              final ar = (s[medan] as List).cast<String>();
              final rm = barisRumi(s, medan);
              if (ar.length != rm.length) {
                salah.add('${s['id']}: $medan berbeza panjang daripada Rumi');
                continue;
              }
              for (var i = 0; i < ar.length; i++) {
                if (!ar[i].contains(dl) || !rm[i].contains(dl)) {
                  salah.add('${s['id']}[$i]: penanda $dl tiada');
                } else if (blokArab.hasMatch(rm[i].split(dl).last.trim())) {
                  salah.add('${s['id']}[$i]: segmen Melayu masih bertulis Arab');
                }
              }
            }
          }
        }
      }
      expect(
        salah,
        isEmpty,
        reason: 'Pembahagian rosak: ${salah.take(6).join('; ')}',
      );
    });

    test('mod melayu: baris Rumi lengkap dan bebas tulisan Arab', () {
      final salah = <String>[];
      for (final id in _subjekAdaBank()) {
        for (final s in bankMentah(id)) {
          if ((s['audio'] as Map?)?['jawapanContoh'] != 'melayu') continue;
          final ar = (s['jawapanContoh'] as List).cast<String>();
          final rm =
              (s['jawapanContohRumi'] as List?)?.cast<String>() ?? <String>[];
          if (ar.length != rm.length || rm.any((x) => x.trim().isEmpty)) {
            salah.add('${s['id']}: jawapanContohRumi tidak lengkap');
          } else if (rm.any(blokArab.hasMatch)) {
            salah.add('${s['id']}: Rumi masih bertulis Arab');
          }
        }
      }
      expect(salah, isEmpty, reason: salah.join('; '));
    });
  });
}
