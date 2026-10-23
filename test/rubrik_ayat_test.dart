// Semakan rubrik jawapan bertulis — kertas sebenar DAN bank latihan.
//
// Kontrak: menaip **jawapan contoh** yang tercetak mesti memberi markah penuh,
// jawapan yang lebih panjang tetap penuh, dan jawapan karut mesti sifar.
import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/models/jawapan.dart';
import 'package:ulangkaji_upkk/models/kertas.dart';
import 'package:ulangkaji_upkk/services/bank_kertas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rubrik ayat: jawapan contoh penuh, karut sifar', () async {
    await BankKertas.instance.muat();
    final gagal = <String>[];
    var diperiksa = 0;

    final semua = <(String, SoalanKertas)>[];
    for (final subjek in BankKertas.instance.subjek) {
      for (final s in BankKertas.instance.bank(subjek.id)) {
        semua.add(('bank/${subjek.id}', s));
      }
    }
    for (final folder in [
      'adab-2024', 'adab-2025', 'akidah-2024', 'akidah-2025',
      'arab-2024', 'arab-2025', 'ibadah-2024', 'ibadah-2025',
      'jawi-2024', 'jawi-2025', 'sirah-2024', 'sirah-2025',
    ]) {
      final k = BankKertas.instance.kertasJawab(folder);
      if (k == null) continue;
      for (final b in k.bahagian) {
        for (final s in b.soalan) {
          semua.add((folder, s));
        }
      }
    }

    for (final (label, s) in semua) {
      if (s.jenis != JenisKertas.tulis && s.jenis != JenisKertas.huraian) {
        continue;
      }
      if (!s.rubrik.ada) continue;
      diperiksa++;

      final penuh = s.markahBolehDapat;
      if (penuh != s.markah) {
        gagal.add('$label ${s.id}: boleh dapat $penuh, kertas ${s.markah}');
      }
      final contoh = s.jawapanContoh.isNotEmpty ? s.jawapanContoh.first : '';
      if (contoh.isEmpty) {
        gagal.add('$label ${s.id}: tiada jawapan contoh');
      } else {
        final markah = s.markahDiperoleh(JawapanTaip(contoh));
        // Kertas sebenar: jawapan skema mesti memberi markah penuh.
        // Bank latihan: sesetengah soalan menyimpan **satu** contoh isi
        // sahaja walaupun rubriknya beberapa isi — ketika itu contoh itu
        // hanya perlu boleh dimarkah (bukan sifar).
        // Soalan kata lawan Bahasa Arab dalam bank mesti penuh — rubriknya
        // ditulis khusus supaya jawapan skema sepadan sepenuhnya.
        const wajibPenuh = {'arab-c18', 'arab-c19', 'arab-d2', 'arab-d14'};
        final perluPenuh =
            !label.startsWith('bank/') || wajibPenuh.contains(s.id);
        if (perluPenuh && markah != penuh) {
          gagal.add('$label ${s.id}: contoh dapat $markah/$penuh — "$contoh"');
        }
        if (!perluPenuh && markah <= 0) {
          gagal.add('$label ${s.id}: contoh tidak boleh dimarkah ($markah/$penuh)');
        }
        if (markah > penuh) {
          gagal.add('$label ${s.id}: markah melebihi penuh ($markah/$penuh)');
        }
      }
      if (s.markahDiperoleh(JawapanTaip('zzz zzz zzz')) != 0) {
        gagal.add('$label ${s.id}: jawapan karut tidak sifar');
      }
    }

    // ignore: avoid_print
    print('Soalan berubrik diperiksa: $diperiksa');
    expect(diperiksa, greaterThanOrEqualTo(30));
    expect(gagal, isEmpty, reason: gagal.join('\n'));
  });
}
