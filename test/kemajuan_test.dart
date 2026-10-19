// Ujian rekod kemajuan — khasnya pemisahan **latih tubi** daripada **kertas
// percubaan**.
//
// Bug yang dikunci di sini senang terlepas pandang kerana tiada apa-apa yang
// rosak pada skrin: satu latihan sepuluh soalan yang dijawab sempurna menghasilkan
// 100%, dan kad subjek terus memaparkan markah latihan itu sebagai
// "15/70 • Gred A" — gred yang murid tidak pernah dapat pada kertas sebenar.
// Ibu bapa yang melihatnya akan menyangka anak mereka sudah bersedia.
//
// Rekod latih tubi tetap perlu disimpan (supaya rentetan hari ulang kaji tidak
// terputus), jadi penyelesaiannya bukan "jangan simpan" tetapi "jangan kira".

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulangkaji_upkk/services/kemajuan.dart';

RekodPercubaan _rekod({
  required int markah,
  required int penuh,
  bool latihan = false,
  String subjekId = 'adab',
  DateTime? tarikh,
}) {
  return RekodPercubaan(
    tarikh: tarikh ?? DateTime.now(),
    subjekId: subjekId,
    kertasId: 'kertas-uji',
    tajuk: 'Kertas Ujian',
    markah: markah,
    markahPenuh: penuh,
    saat: 600,
    latihan: latihan,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Kemajuan.instance.muat();
    await Kemajuan.instance.padamSemua();
  });

  test('latih tubi sempurna tidak menjadi markah terbaik subjek', () async {
    await Kemajuan.instance.simpanPercubaan(
      _rekod(markah: 15, penuh: 15, latihan: true),
    );

    final ringkasan = Kemajuan.instance.ringkasan('adab');
    expect(ringkasan.adaRekod, isFalse);
    expect(ringkasan.markahTerbaik, 0);
    expect(ringkasan.percubaan, 0);
  });

  test('kertas percubaan dikira sebagai markah terbaik', () async {
    await Kemajuan.instance.simpanPercubaan(
      _rekod(markah: 42, penuh: 70),
    );

    final ringkasan = Kemajuan.instance.ringkasan('adab');
    expect(ringkasan.adaRekod, isTrue);
    expect(ringkasan.markahTerbaik, 42);
    expect(ringkasan.percubaan, 1);
  });

  test('latih tubi tidak menenggelamkan percubaan sebenar', () async {
    // Murid menjawab kertas percubaan sederhana, kemudian latihan sepuluh
    // soalan yang sempurna. Markah terbaik mesti kekal markah kertas.
    await Kemajuan.instance.simpanPercubaan(
      _rekod(markah: 42, penuh: 70),
    );
    await Kemajuan.instance.simpanPercubaan(
      _rekod(markah: 15, penuh: 15, latihan: true),
    );

    final ringkasan = Kemajuan.instance.ringkasan('adab');
    expect(ringkasan.markahTerbaik, 42);
    expect(ringkasan.percubaan, 1);
  });

  test('hari latih tubi masih dikira dalam rentetan', () async {
    await Kemajuan.instance.simpanPercubaan(
      _rekod(markah: 5, penuh: 10, latihan: true),
    );
    expect(Kemajuan.instance.rentetanHari, 1);
  });

  test('had rekod membuang latih tubi lama dahulu', () async {
    for (var i = 0; i < Kemajuan.hadRekod; i++) {
      await Kemajuan.instance.simpanPercubaan(_rekod(markah: 30, penuh: 70));
    }
    await Kemajuan.instance.simpanPercubaan(
      _rekod(markah: 8, penuh: 10, latihan: true),
    );

    expect(Kemajuan.instance.rekod.length, Kemajuan.hadRekod);
    expect(Kemajuan.instance.rekod.where((r) => r.latihan), isEmpty);
    expect(Kemajuan.instance.rekodKertas.length, Kemajuan.hadRekod);
  });

  test('senarai percubaan mengecualikan latih tubi', () async {
    await Kemajuan.instance.simpanPercubaan(_rekod(markah: 50, penuh: 70));
    await Kemajuan.instance.simpanPercubaan(
      _rekod(markah: 9, penuh: 10, latihan: true),
    );

    expect(Kemajuan.instance.rekod.length, 2);
    expect(Kemajuan.instance.rekodKertas.length, 1);
    expect(Kemajuan.instance.rekodKertas.single.markah, 50);
  });

  test('rekod lama tanpa penanda latihan dianggap kertas percubaan', () async {
    // Rekod yang disimpan sebelum medan `latihan` wujud mesti terus dibaca —
    // tanpa migrasi, markah murid yang sedia ada akan hilang.
    final lama = _rekod(markah: 60, penuh: 70).keJson()..remove('l');
    final dibaca = RekodPercubaan.dariJson(lama);

    expect(dibaca.latihan, isFalse);
    expect(dibaca.markah, 60);
    expect(dibaca.markahPenuh, 70);
  });
}
