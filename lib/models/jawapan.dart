import 'dart:math';

/// Jawapan yang dibina oleh murid bagi satu soalan.
///
/// Satu jenis untuk keempat-empat kaedah soalan (`pilihan`, `padan`, `susun`
/// dan `taip`) supaya skrin latih tubi dan kertas percubaan boleh menyimpan
/// jawapan dalam satu senarai sahaja tanpa kod bercabang di merata tempat.
sealed class JawapanMurid {
  const JawapanMurid();
}

/// Jawapan soalan pilihan (A/B/C/D) — indeks pilihan yang dipilih.
class JawapanPilihan extends JawapanMurid {
  const JawapanPilihan(this.indeks);

  final int indeks;
}

/// Jawapan soalan `padan`.
///
/// `padanan[i]` ialah indeks pasangan asal bagi item kanan yang dipadankan
/// dengan item kiri `i`. Jawapan betul apabila `padanan[i] == i` untuk semua
/// item — iaitu murid memadankan setiap item dengan pasangannya yang asal.
class JawapanPadan extends JawapanMurid {
  const JawapanPadan(this.padanan);

  final Map<int, int> padanan;
}

/// Jawapan soalan `susun`.
///
/// `susunan` ialah senarai indeks urutan asal mengikut susunan yang dipilih
/// murid. Jawapan betul apabila ia sama dengan `[0, 1, 2, ...]`.
class JawapanSusun extends JawapanMurid {
  const JawapanSusun(this.susunan);

  final List<int> susunan;
}

/// Jawapan soalan bertulis (`taip`) — ayat ringkas yang ditaip murid.
///
/// Pemarkahannya mengikut skema pemarkahan UASA (1 idea = 1 markah) dan
/// dijalankan oleh `Pemarkah` terhadap `Soalan.rubrik`.
class JawapanTaip extends JawapanMurid {
  const JawapanTaip(this.teks);

  final String teks;
}

/// Jawapan soalan `tempat_kosong` — satu perkataan dipilih bagi setiap kosong.
///
/// `isi[i]` ialah indeks asal perkataan dalam bank jawapan bagi kosong `i`.
/// Jawapan betul apabila setiap kosong diisi dengan perkataan asalnya —
/// iaitu `isi[i] == i` untuk semua kosong.
class JawapanTempatKosong extends JawapanMurid {
  const JawapanTempatKosong(this.isi);

  final Map<int, int> isi;
}

/// Jawapan soalan `betul_salah_set` — satu tandaan bagi setiap pernyataan.
///
/// `jawapan[i]` ialah `true` apabila murid menandakan pernyataan `i` sebagai
/// BETUL dan `false` apabila SALAH; `null` bermakna belum ditanda.
class JawapanBetulSalah extends JawapanMurid {
  const JawapanBetulSalah(this.jawapan);

  final List<bool?> jawapan;
}

/// Jawapan soalan `kumpulan` — satu kategori dipilih bagi setiap pernyataan.
///
/// Kertas UPKK memakai bentuk ini untuk soalan seperti "Suaikan pernyataan
/// bahagian (ا) dengan bahagian (ب)": murid tidak memadankan pasangan satu
/// dengan satu, tetapi mengelaskan setiap pernyataan ke dalam salah satu
/// kategori. `pilihan[i]` ialah indeks kategori bagi pernyataan `i`, dan `-1`
/// bermakna pernyataan itu belum dikelaskan.
class JawapanKumpulan extends JawapanMurid {
  const JawapanKumpulan(this.pilihan);

  final List<int> pilihan;

  /// Bilangan pernyataan yang sudah dikelaskan.
  int get bilanganDijawab => pilihan.where((p) => p >= 0).length;
}

/// Jawapan soalan yang mempunyai **beberapa item berpilihan** dalam satu soalan.
///
/// Bahagian A dan Bahagian B kertas UPKK meminta murid membulatkan jawapan bagi
/// beberapa item di bawah satu soalan utama — contohnya lima item bernombor
/// yang berkongsi satu arahan. Ia berbeza daripada [JawapanPilihan] yang hanya
/// menyimpan satu pilihan bagi satu soalan.
class JawapanPilihanKertas extends JawapanMurid {
  const JawapanPilihanKertas(this.pilihan);

  /// Indeks pilihan yang dipilih bagi setiap item.
  ///
  /// `-1` bermakna item itu belum dijawab. Senarai ini sentiasa sama panjang
  /// dengan bilangan item soalan supaya pemarkahan boleh dibuat mengikut
  /// kedudukan tanpa semakan tambahan.
  final List<int> pilihan;

  /// Bilangan item yang sudah dijawab.
  int get bilanganDijawab =>
      pilihan.where((p) => p >= 0).length;
}

/// Susunan paparan yang mesti kekal sama sepanjang satu soalan.
///
/// Item kanan (`padan`) dan item urutan (`susun`) tidak boleh dipaparkan dalam
/// susunan asal — jika tidak, jawapan betul sudah terpampang. Susunan dikocok
/// daripada `id` soalan supaya sama pada setiap peranti dan setiap kali app
/// dibuka, dan supaya ujian boleh meramal susunannya.
class Paparan {
  const Paparan({
    required this.kanan,
    required this.susun,
    this.bank = const [],
  });

  /// Bagi `padan`: indeks pasangan asal bagi setiap slot kanan yang dipaparkan.
  final List<int> kanan;

  /// Bagi `susun`: susunan awal (indeks urutan asal) yang dikocok.
  final List<int> susun;

  /// Bagi `tempat_kosong`: susunan paparan bank perkataan (indeks asal).
  final List<int> bank;

  static Paparan bina({
    required String id,
    required int bilanganKanan,
    required int bilanganSusun,
    int bilanganBank = 0,
  }) {
    final rawak = Random(_benih(id));
    var kanan = _kocok(bilanganKanan, rawak);
    var susun = _kocok(bilanganSusun, rawak);
    final bank = _kocok(bilanganBank, rawak);
    // Pastikan susunan bukan susunan asal — jika tidak jawapan sudah terbuka.
    if (bilanganKanan > 1 && _susunanAsal(kanan)) kanan = _putar(kanan);
    if (bilanganSusun > 1 && _susunanAsal(susun)) susun = _putar(susun);
    return Paparan(kanan: kanan, susun: susun, bank: bank);
  }

  static const Paparan kosong = Paparan(kanan: [], susun: []);

  static List<int> _kocok(int bilangan, Random rawak) {
    final senarai = List<int>.generate(bilangan, (i) => i);
    for (var i = bilangan - 1; i > 0; i--) {
      final j = rawak.nextInt(i + 1);
      final sementara = senarai[i];
      senarai[i] = senarai[j];
      senarai[j] = sementara;
    }
    return senarai;
  }

  static bool _susunanAsal(List<int> senarai) {
    for (var i = 0; i < senarai.length; i++) {
      if (senarai[i] != i) return false;
    }
    return true;
  }

  /// Putarkan senarai satu langkah supaya bukan lagi susunan asal.
  static List<int> _putar(List<int> senarai) =>
      [...senarai.sublist(1), senarai.first];

  /// Benih daripada id soalan.
  ///
  /// Hash FNV-1a ditulis sendiri (bukan `String.hashCode`) kerana
  /// `String.hashCode` tidak dijamin sama antara versi Dart.
  static int _benih(String id) {
    var nilai = 0x811c9dc5;
    for (final unit in id.codeUnits) {
      nilai ^= unit;
      nilai = (nilai * 0x01000193) & 0xffffffff;
    }
    return nilai;
  }
}
