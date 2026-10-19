import 'dart:math';

import '../models/kertas.dart';
import 'bank_kertas.dart';

/// Penjana kertas percubaan UPKK.
///
/// Kertas percubaan **bukan** kertas tetap yang disimpan dalam fail. Ia dibina
/// setiap kali murid mula menjawab, daripada bank soalan subjek itu, mengikut
/// format rasmi kertas UPKK — bilangan bahagian, bilangan soalan setiap bahagian,
/// dan jumlah markah yang sama seperti kertas sebenar.
///
/// Dua peraturan yang dipegang oleh penjana ini:
///
///   1. **Tiada soalan berulang dalam satu kertas.** Setiap soalan yang dipilih
///      direkodkan, dan soalan yang sudah digunakan tidak boleh dipilih lagi
///      walaupun bank soalan tidak cukup untuk memenuhi format. Dalam kes itu
///      kertas menjadi lebih pendek — ia tidak pernah mengulang soalan, kerana
///      soalan berulang membuatkan murid meneka daripada mengingati.
///
///   2. **Setiap percubaan berbeza.** Soalan dipilih sebagai satu tetingkap
///      bergerak merentasi bank, dan tetingkap itu beralih mengikut bilangan
///      percubaan yang telah dibuat murid ([Kemajuan.giliran]). Selepas beberapa
///      percubaan, murid akan meliputi seluruh bank soalan — bukan asyik
///      menjawab soalan yang sama setiap kali.
///
/// Bahagian B sentiasa 10 soalan × 1 markah, jadi ia sentiasa boleh dipenuhi
/// selagi bank mempunyai sekurang-kurangnya 10 soalan aneka pilihan.
class JanaKertas {
  JanaKertas._();

  /// Bina satu kertas percubaan penuh mengikut format rasmi [subjek].
  ///
  /// [giliran] ialah bilangan percubaan yang telah dibuat murid bagi subjek ini
  /// (lihat `Kemajuan.giliran`). Ia menentukan tetingkap soalan yang dipilih.
  static Kertas percubaan({
    required Subjek subjek,
    required List<SoalanKertas> bank,
    int giliran = 0,
  }) {
    final digunakan = <String>{};
    final bahagian = <BahagianKertas>[];
    var nombor = 1;

    for (var i = 0; i < subjek.bahagian.length; i++) {
      final format = subjek.bahagian[i];
      final calon = bank
          .where((s) => BankKertas.sesuaiUntuk(subjek, s, format.nama))
          .toList();

      final terpilih = _pilihMarkah(
        calon: calon,
        bilangan: format.bilangan,
        markahSasaran: format.markah,
        giliran: giliran,
        offset: i * 3,
        digunakan: digunakan,
      );

      bahagian.add(
        BahagianKertas(
          nama: format.nama,
          markah: format.markah,
          arahan: format.arahan,
          arahanRumi: format.arahanRumi,
          soalan: [
            for (final s in terpilih) s.salin(bahagian: format.nama, nombor: nombor++),
          ],
        ),
      );
    }

    final siri = Kertas.nomborSiri('${subjek.id}-$giliran');
    return Kertas(
      id: 'percubaan-${subjek.id}-$giliran',
      subjekId: subjek.id,
      tajuk: 'Kertas Percubaan ${subjek.nama}',
      sumber: 'Soalan percubaan Ulangkaji UPKK — Kertas Bil. $siri',
      jenisSumber: 'percubaan',
      bahagian: bahagian,
    );
  }

  /// Bina satu set latih tubi — soalan pendek bercampur seluruh bank.
  ///
  /// Latih tubi digunakan untuk ulang kaji pantas, jadi ia mengandungi soalan
  /// daripada semua bahagian dan tidak mengikut susunan kertas. Soalan yang
  /// murid pernah salah didahulukan supaya latihan tertumpu pada kelemahan.
  static Kertas latihTubi({
    required Subjek subjek,
    required List<SoalanKertas> bank,
    int giliran = 0,
    int bilangan = 10,
    Set<String> utamakan = const {},
  }) {
    if (bank.isEmpty) {
      return Kertas(
        id: 'latihan-${subjek.id}-$giliran',
        subjekId: subjek.id,
        tajuk: 'Latih Tubi ${subjek.nama}',
        sumber: 'Latih tubi Ulangkaji UPKK',
        jenisSumber: 'latihan',
        bahagian: const [],
      );
    }

    // Soalan yang murid pernah salah didahulukan, kemudian tetingkap bergerak
    // yang sama seperti kertas percubaan supaya latihan juga berubah setiap kali.
    final utama = bank.where((s) => utamakan.contains(s.id)).toList();
    final digunakan = <String>{};
    final terpilih = _pilih(
      calon: utama,
      bilangan: bilangan,
      giliran: giliran,
      offset: 0,
      digunakan: digunakan,
    );
    if (terpilih.length < bilangan) {
      terpilih.addAll(
        _pilih(
          calon: bank,
          bilangan: bilangan - terpilih.length,
          giliran: giliran,
          offset: 5,
          digunakan: digunakan,
        ),
      );
    }

    var nombor = 1;
    final soalan = [
      for (final s in terpilih) s.salin(bahagian: 'A', nombor: nombor++),
    ];

    return Kertas(
      id: 'latihan-${subjek.id}-$giliran',
      subjekId: subjek.id,
      tajuk: 'Latih Tubi ${subjek.nama}',
      sumber: 'Latih tubi Ulangkaji UPKK',
      jenisSumber: 'latihan',
      bahagian: [
        BahagianKertas(
          nama: 'A',
          // Latih tubi tiada format markah rasmi, jadi jumlahnya dikira
          // daripada soalan yang benar-benar terpilih. Tanpa ini, markah
          // bahagian disetkan kepada *bilangan* soalan, dan kulit kertas
          // memaparkan dua nombor yang bercanggah — contohnya "10 markah
          // (15 tersedia)".
          markah: soalan.fold(0, (jumlah, s) => jumlah + s.markahBolehDapat),
          arahan: 'جواب سموا سوءالن.',
          arahanRumi: 'Jawab semua soalan.',
          soalan: soalan,
        ),
      ],
    );
  }

  /// Pilih soalan bagi satu bahagian supaya **jumlah markahnya** menepati kertas
  /// rasmi.
  ///
  /// Memilih ikut bilangan soalan sahaja tidak mencukupi: soalan dalam bank
  /// tidak semuanya bernilai markah yang sama, jadi 4 soalan Bahagian C yang
  /// dipilih secara rambang boleh berjumlah 22 markah sedangkan kertas sebenar
  /// memperuntukkan 30. Kertas yang berakhir dengan 56 markah daripada 70
  /// memesongkan gred murid, kerana itulah markah yang perlu dipertahankan di
  /// sini.
  ///
  /// Bilangan soalan tetap seperti format rasmi; yang berubah hanyalah soalan
  /// **mana** yang dipilih.
  static List<SoalanKertas> _pilihMarkah({
    required List<SoalanKertas> calon,
    required int bilangan,
    required int markahSasaran,
    required int giliran,
    required int offset,
    required Set<String> digunakan,
  }) {
    if (calon.isEmpty || bilangan <= 0) return const [];

    final tersedia = calon.where((s) => !digunakan.contains(s.id)).toList();
    if (tersedia.isEmpty) return const [];
    final sasaranBilangan = min(bilangan, tersedia.length);

    // Tetingkap bergerak: setiap percubaan bermula pada kedudukan yang berbeza,
    // jadi percubaan berturut-turut menggunakan soalan yang berlainan walaupun
    // kesemuanya daripada bank yang sama.
    final jarak = max(1, bilangan);
    final mula = ((giliran * jarak) + offset) % tersedia.length;
    final putaran = [
      for (var i = 0; i < tersedia.length; i++)
        tersedia[(mula + i) % tersedia.length],
    ];

    // Kolam calon dihadkan supaya carian kekal pantas, tetapi cukup luas untuk
    // mencari gabungan markah yang tepat.
    final kolam = putaran
        .take(min(putaran.length, max(sasaranBilangan * 8, 24)))
        .toList();

    // Susunan kolam diacak dengan benih yang bergantung pada percubaan.
    //
    // Carian gabungan di bawah cenderung memilih soalan yang **terawal** dalam
    // kolam. Tanpa pengacakan, susunan itu berulang dan sebahagian besar bank
    // tidak pernah keluar — pada bank Sirah, hanya 10 daripada 20 soalan
    // Bahagian C terpilih merentas enam puluh percubaan. Benih yang tetap
    // (bukan rawak sebenar) dipakai supaya percubaan nombor tiga sentiasa
    // menghasilkan kertas yang sama; yang berubah hanyalah percubaan yang
    // berlainan nombor.
    kolam.shuffle(Random(giliran * 7919 + offset * 31 + sasaranBilangan));

    final pilihan = _gabunganMarkah(kolam, sasaranBilangan, markahSasaran) ??
        kolam.take(sasaranBilangan).toList();

    for (final s in pilihan) {
      digunakan.add(s.id);
    }
    return pilihan;
  }

  /// Cari tepat [bilangan] soalan daripada [kolam] yang jumlah markahnya paling
  /// hampir dengan [sasaran].
  ///
  /// Carian dibuat dengan atur cara dinamik: keadaan ialah (bilangan soalan
  /// dipilih, jumlah markah), dan setiap keadaan menyimpan soalan terakhir yang
  /// membentuknya. Dengan cara ini carian kekal pantas walaupun jumlah markah
  /// yang mungkin banyak — memilih secara menyeluruh (cuba setiap gabungan) tidak
  /// boleh diterima kerana bank boleh mengandungi puluhan soalan.
  static List<SoalanKertas>? _gabunganMarkah(
    List<SoalanKertas> kolam,
    int bilangan,
    int sasaran,
  ) {
    if (bilangan <= 0 || kolam.length < bilangan) return null;

    // Had jumlah markah yang dijejaki. Gabungan yang jauh melebihi sasaran sudah
    // tentu bukan pilihan terbaik, jadi ruang keadaan boleh dipangkas.
    final had = max(sasaran * 2, 100);

    final dp = List.generate(bilangan + 1, (_) => <int, int>{});
    final sebelum = List.generate(bilangan + 1, (_) => <int, int>{});
    dp[0][0] = -1;

    for (var i = 0; i < kolam.length; i++) {
      final markah = kolam[i].markahBolehDapat;
      if (markah <= 0) continue;
      // `k` menurun supaya setiap soalan hanya boleh dipakai sekali: keadaan
      // yang dibaca belum disentuh oleh soalan ini.
      for (var k = bilangan - 1; k >= 0; k--) {
        final kunci = dp[k].keys.toList();
        for (final jumlah in kunci) {
          final baharu = jumlah + markah;
          if (baharu > had) continue;
          if (dp[k + 1].containsKey(baharu)) continue;
          dp[k + 1][baharu] = i;
          sebelum[k + 1][baharu] = jumlah;
        }
      }
    }

    if (dp[bilangan].isEmpty) return null;

    var terbaik = -1;
    var bezaTerbaik = 1 << 30;
    for (final jumlah in dp[bilangan].keys) {
      final beza = (jumlah - sasaran).abs();
      if (beza < bezaTerbaik) {
        bezaTerbaik = beza;
        terbaik = jumlah;
      }
    }
    if (terbaik < 0) return null;

    // Bina semula gabungan yang dipilih, kemudian susun mengikut urutan kolam
    // supaya susunan soalan pada kertas stabil antara percubaan.
    final indeks = <int>[];
    var jumlah = terbaik;
    for (var k = bilangan; k > 0; k--) {
      final i = dp[k][jumlah];
      if (i == null) return null;
      indeks.add(i);
      jumlah = sebelum[k][jumlah]!;
    }
    indeks.sort();
    return [for (final i in indeks) kolam[i]];
  }

  /// Pilih soalan bagi satu bahagian.
  ///
  /// Tetingkap bermula pada kedudukan yang bergantung kepada [giliran] dan
  /// [offset], kemudian bergerak ke hadapan sambil melangkau soalan yang sudah
  /// digunakan dalam kertas yang sama. Jika tetingkap sampai ke hujung bank, ia
  /// berpusing ke pangkal — jadi bank bulat, tiada soalan pernah hilang.
  static List<SoalanKertas> _pilih({
    required List<SoalanKertas> calon,
    required int bilangan,
    required int giliran,
    required int offset,
    required Set<String> digunakan,
  }) {
    if (calon.isEmpty || bilangan <= 0) return [];

    // Bilangan soalan yang boleh diambil tanpa mengulang soalan yang sama.
    final tersedia = calon.where((s) => !digunakan.contains(s.id)).length;
    final sasaran = min(bilangan, tersedia);
    if (sasaran <= 0) return [];

    // Tetingkap bergerak: setiap percubaan bermula pada kedudukan yang berbeza,
    // dan jarak langkah sama dengan bilangan soalan yang diperlukan. Dengan cara
    // ini percubaan berturut-turut tidak bertindih, dan selepas beberapa
    // percubaan seluruh bank telah diliputi.
    final jarak = max(1, bilangan);
    final mula = ((giliran * jarak) + offset) % calon.length;

    final terpilih = <SoalanKertas>[];
    for (var i = 0; i < calon.length && terpilih.length < sasaran; i++) {
      final s = calon[(mula + i) % calon.length];
      if (digunakan.contains(s.id)) continue;
      terpilih.add(s);
      digunakan.add(s.id);
    }

    // Keselamatan: bank yang sangat kecil (kurang daripada bilangan yang
    // diperlukan) tetap tidak boleh mengulang soalan, jadi senarai yang lebih
    // pendek daripada [bilangan] memang dijangka.
    return terpilih;
  }

  /// Bilangan kertas percubaan berbeza yang boleh dijana daripada [bank] untuk
  /// satu bahagian — untuk memaklumkan murid berapa banyak percubaan ada
  /// sebelum soalan mula berulang.
  static int bilanganVersi(Subjek subjek, List<SoalanKertas> bank) {
    if (bank.isEmpty) return 0;
    var palingSedikit = -1;
    for (final format in subjek.bahagian) {
      if (format.bilangan <= 0) continue;
      final bilangan = bank
          .where((s) => BankKertas.sesuaiUntuk(subjek, s, format.nama))
          .length;
      final versi = bilangan ~/ format.bilangan;
      if (palingSedikit < 0 || versi < palingSedikit) palingSedikit = versi;
    }
    return max(0, palingSedikit);
  }

  /// Adakah bank cukup lengkap untuk menjana kertas yang menepati format rasmi?
  static bool lengkap(Subjek subjek, List<SoalanKertas> bank) {
    for (final format in subjek.bahagian) {
      final bilangan = bank
          .where((s) => BankKertas.sesuaiUntuk(subjek, s, format.nama))
          .length;
      if (bilangan < format.bilangan) return false;
    }
    return true;
  }

  /// Senarai bahagian yang masih kekurangan soalan — untuk skrin Info.
  static List<String> bahagianKurang(Subjek subjek, List<SoalanKertas> bank) {
    final kurang = <String>[];
    for (final format in subjek.bahagian) {
      final bilangan = bank
          .where((s) => BankKertas.sesuaiUntuk(subjek, s, format.nama))
          .length;
      if (bilangan < format.bilangan) {
        kurang.add('Bahagian ${format.nama} ($bilangan/${format.bilangan})');
      }
    }
    return kurang;
  }
}
