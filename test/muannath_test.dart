// Soalan Mudhakkar/Mu'annath mesti **menolak** bentuk maskulin.
//
// Enjin pemarkahan membenarkan satu huruf tersilap bagi perkataan lima huruf
// ke atas. Tanpa semakan ini, murid yang menulis «معلم» (maskulin) akan
// dianggap betul bagi «معلمة» — dan soalan ini tidak menguji apa-apa.
import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/models/jawapan.dart';
import 'package:ulangkaji_upkk/services/bank_kertas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mu\'annath: bentuk maskulin tidak mendapat markah', () async {
    await BankKertas.instance.muat();
    final bank = BankKertas.instance.bank('arab');

    const maskulin = {
      'arab-c18': 'معلم، مسلم، كاتب، طبيب',
      'arab-c19': 'تاجر، نجار، خباز، حارس',
      'arab-d2': 'معلم، مسلم، كاتب، طبيب، تاجر، نجار، فلاح',
      'arab-d14': 'هذا معلم نشيط. هذا مسلم صالح. هذا كاتب مشهور. '
          'هذا طبيب ماهر. هذا تاجر غني. هذا نجار حاذق. هذا فلاح نشيط.',
    };

    for (final q in bank) {
      final teks = maskulin[q.id];
      if (teks == null) continue;
      final penuh = q.markahBolehDapat;
      final salah = q.markahDiperoleh(JawapanTaip(teks));
      // ignore: avoid_print
      print('${q.id}: maskulin dapat $salah/$penuh');
      expect(salah, 0, reason: '${q.id}: bentuk maskulin sepatutnya sifar');
    }
  });
}
