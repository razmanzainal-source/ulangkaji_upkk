// Semakan rubrik jawapan bertulis bagi kertas sebenar.
//
// Kontrak: menaip **jawapan contoh** yang tercetak pada skema mesti memberi
// markah penuh, dan jawapan kosong mesti memberi sifar. Tanpa semakan ini,
// satu kata kunci yang tersilap eja akan menyebabkan murid yang menyalin
// jawapan betul tetap mendapat sifar.
import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/models/jawapan.dart';
import 'package:ulangkaji_upkk/models/kertas.dart';
import 'package:ulangkaji_upkk/services/bank_kertas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rubrik ayat: jawapan contoh dapat penuh, jawapan karut dapat sifar',
      () async {
    await BankKertas.instance.muat();
    final gagal = <String>[];
    var diperiksa = 0;

    for (final folder in [
      'adab-2024', 'adab-2025', 'akidah-2024', 'akidah-2025',
      'arab-2024', 'arab-2025', 'ibadah-2024', 'ibadah-2025',
      'jawi-2024', 'jawi-2025', 'sirah-2024', 'sirah-2025',
    ]) {
      final kertas = BankKertas.instance.kertasJawab(folder);
      if (kertas == null) continue;
      for (final bahagian in kertas.bahagian) {
        for (final s in bahagian.soalan) {
          if (s.jenis != JenisKertas.tulis && s.jenis != JenisKertas.huraian) {
            continue;
          }
          if (!s.rubrik.ada) continue;
          diperiksa++;
          final penuh = s.markahBolehDapat;
          if (penuh != s.markah) {
            gagal.add('${s.id}: markah boleh dapat $penuh ≠ markah kertas '
                '${s.markah}');
          }
          // Hanya jawapan contoh **pertama** mesti memberi markah penuh —
          // sesetengah soalan menyimpan serpihan jawapan pada senarai itu.
          final contoh = s.jawapanContoh.isNotEmpty ? s.jawapanContoh.first : '';
          if (contoh.isEmpty) {
            gagal.add('${s.id}: tiada jawapan contoh');
          } else {
            final markah = s.markahDiperoleh(JawapanTaip(contoh));
            if (markah != penuh) {
              gagal.add('${s.id}: jawapan contoh dapat $markah/$penuh — "$contoh"');
            }
          }
          // Murid yang menulis ayat lebih panjang ( tetapi isinya sama )
          // tetap mesti mendapat markah penuh.
          if (contoh.isNotEmpty) {
            final lebih = s.markahDiperoleh(JawapanTaip('$contoh sebab itu'));
            if (lebih != penuh) {
              gagal.add('${s.id}: ayat lebih panjang dapat $lebih/$penuh');
            }
          }
          final karut = s.markahDiperoleh(JawapanTaip('zzz zzz zzz'));
          if (karut != 0) {
            gagal.add('${s.id}: jawapan karut dapat $karut (sepatutnya 0)');
          }
        }
      }
    }

    // ignore: avoid_print
    print('Soalan berubrik diperiksa: $diperiksa');
    expect(diperiksa, greaterThanOrEqualTo(30));
    expect(gagal, isEmpty, reason: gagal.join('\n'));
  });
}
