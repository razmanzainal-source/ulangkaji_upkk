import 'dart:math';
import 'dart:ui' show Color;

import '../services/pemarkah.dart';
import 'jawapan.dart';
import 'rubrik.dart';

/// Format kertas UPKK.
///
/// Satu kertas UPKK bertulis bernilai **70 markah** dan diberi masa
/// **1 jam 15 minit**. Ia dibahagikan kepada beberapa bahagian (A hingga E
/// bergantung kepada subjek), dan setiap bahagian mempunyai jenis soalan yang
/// tersendiri — inilah yang menjadikan kertas UPKK berbeza daripada kertas
/// UASA biasa:
///
/// | Bahagian | Bentuk soalan |
/// | --- | --- |
/// | A | Soalan pendek — bulatkan jawapan, padankan, tanda betul/salah |
/// | B | Aneka pilihan (ا ب ج د) — 10 soalan, 1 markah setiap satu |
/// | C | Jawapan bertulis pendek mengikut kehendak soalan |
/// | D | Jawapan bertulis panjang / huraian |
/// | E | (Jawi sahaja) menulis semula ayat dalam tulisan Jawi |
///
/// Bahagian **B sentiasa 10 soalan × 1 markah = 10 markah** pada semua subjek,
/// jadi ia dijadikan pemalar supaya penjana kertas percubaan tidak tersilap.
class FormatUpkk {
  FormatUpkk._();

  /// Jumlah markah satu kertas UPKK bertulis.
  static const int jumlahMarkah = 70;

  /// Masa menjawab satu kertas, dalam minit (1 jam 15 minit).
  static const int masaMinit = 75;

  /// Teks masa seperti yang tercetak pada kulit kertas sebenar.
  static const String masaTeks = '1 jam 15 minit';

  /// Markah Bahagian B — sama pada setiap subjek.
  static const int markahBahagianB = 10;

  /// Bilangan soalan Bahagian B — sama pada setiap subjek.
  static const int bilanganBahagianB = 10;
}

/// Satu subjek bertulis UPKK.
///
/// Enam subjek bertulis UPKK ialah Adab, Akidah, Bahasa Arab, Ibadah, Jawi dan
/// Khat, dan Sirah. Kod subjek (`UPKK01`–`UPKK07`) datang daripada JAKIM;
/// UPKK01 (Al-Quran) tidak disenaraikan kerana ia dinilai secara lisan, bukan
/// bertulis.
class Subjek {
  const Subjek({
    required this.id,
    required this.kod,
    required this.nama,
    required this.namaJawi,
    required this.ikon,
    required this.warna,
    required this.bahasa,
    required this.bahagian,
    required this.kertasSebenar,
  });

  /// Pengenal ringkas untuk nama fail dan kunci simpanan (`adab`, `akidah`, …).
  final String id;

  /// Kod rasmi JAKIM, contohnya `UPKK04` untuk Adab.
  final String kod;

  final String nama;
  final String namaJawi;

  /// Emoji yang mewakili subjek — besar dan jelas untuk kanak-kanak.
  final String ikon;

  final Color warna;

  /// Tulisan jawapan yang dijangka: `jawi` atau `arab`.
  ///
  /// Kertas Bahasa Arab dijawab dalam tulisan Arab, manakala lima subjek lain
  /// dijawab dalam tulisan Jawi. Perbezaan ini penting untuk papan kekunci dan
  /// untuk pemeriksaan jawapan bertulis.
  final String bahasa;

  /// Bentuk bahagian mengikut kertas UPKK sebenar.
  final List<BahagianFormat> bahagian;

  /// Imbasan kertas sebenar yang dibundelkan bersama app.
  final List<KertasSebenar> kertasSebenar;

  factory Subjek.dariJson(Map<String, dynamic> json) => Subjek(
        id: json['id'] as String? ?? '',
        kod: json['kod'] as String? ?? '',
        nama: json['nama'] as String? ?? '',
        namaJawi: json['namaJawi'] as String? ?? '',
        ikon: json['ikon'] as String? ?? '📘',
        warna: warnaDariHex(json['warna'] as String?),
        bahasa: json['bahasa'] as String? ?? 'jawi',
        bahagian: (json['bahagian'] as List? ?? const [])
            .map((e) => BahagianFormat.dariJson(e as Map<String, dynamic>))
            .toList(),
        kertasSebenar: (json['kertasSebenar'] as List? ?? const [])
            .map((e) => KertasSebenar.dariJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Jumlah markah semua bahagian — sepatutnya sentiasa 70.
  int get markahPenuh =>
      bahagian.fold(0, (jumlah, b) => jumlah + b.markah);

  /// Adakah format kertas ini menepati kertas UPKK sebenar?
  bool get formatSah => markahPenuh == FormatUpkk.jumlahMarkah;

  bool get jawapanArab => bahasa == 'arab';
}

/// Bentuk satu bahagian dalam format rasmi kertas UPKK.
class BahagianFormat {
  const BahagianFormat({
    required this.nama,
    required this.markah,
    required this.bilangan,
    required this.jenis,
    required this.arahan,
    required this.arahanRumi,
  });

  /// Huruf bahagian: `A`, `B`, `C`, `D`, atau `E`.
  final String nama;

  final int markah;

  /// Bilangan soalan dalam bahagian ini.
  final int bilangan;

  /// Jenis soalan yang diterima, mengikut keutamaan.
  ///
  /// Contohnya Bahagian A Adab menerima `kariyes` dahulu, kemudian `bulat`,
  /// dan akhirnya `suai` jika soalan jenis itu habis. Keutamaan ini membolehkan
  /// penjana kertas membina kertas baharu daripada bank soalan yang ada tanpa
  /// melanggar bentuk kertas sebenar.
  final List<String> jenis;

  /// Arahan rasmi seperti yang tercetak pada kertas.
  final String arahan;

  /// Transliterasi Rumi bagi [arahan].
  final String arahanRumi;

  factory BahagianFormat.dariJson(Map<String, dynamic> json) => BahagianFormat(
        nama: json['nama'] as String? ?? 'A',
        markah: json['markah'] as int? ?? 0,
        bilangan: json['bilangan'] as int? ?? 0,
        jenis: (json['jenis'] as List? ?? const []).cast<String>(),
        arahan: json['arahan'] as String? ?? '',
        arahanRumi: json['arahanRumi'] as String? ?? '',
      );
}

/// Imbasan satu kertas UPKK tahun lepas.
class KertasSebenar {
  const KertasSebenar({
    required this.tahun,
    required this.folder,
    required this.muka,
  });

  final int tahun;

  /// Folder aset, contohnya `adab-2024`.
  final String folder;

  /// Bilangan muka surat dalam imbasan ini.
  final int muka;

  factory KertasSebenar.dariJson(Map<String, dynamic> json) => KertasSebenar(
        tahun: json['tahun'] as int? ?? 0,
        folder: json['folder'] as String? ?? '',
        muka: json['muka'] as int? ?? 0,
      );

  /// Laluan aset muka surat ke-[nombor] (bermula daripada 1).
  String laluan(int nombor) =>
      'assets/kertas/$folder/muka${nombor.toString().padLeft(2, '0')}.jpg';
}

/// Jenis soalan yang muncul dalam kertas UPKK.
enum JenisKertas {
  /// Bulatkan jawapan yang betul — dua pilihan sahaja.
  bulat,

  /// Padankan item di lajur kiri dengan jawapan di lajur kanan.
  suai,

  /// Tandakan pernyataan sama ada betul (✓) atau salah (✗).
  betulSalah,

  /// Aneka pilihan ا / ب / ج / د.
  objektif,

  /// Isi tempat kosong dengan perkataan daripada bank yang diberi.
  tempatKosong,

  /// Susun perkataan menjadi ayat yang sempurna.
  susun,

  /// Jawapan bertulis — satu atau beberapa patah perkataan.
  tulis,

  /// Jawapan bertulis panjang (huraian, sebab, contoh).
  huraian,

  /// Senarai jawapan bertulis — murid memberi bilangan isi yang diminta, dan
  /// **mana-mana** isi dalam senarai yang diterima skema dikira betul.
  ///
  /// Ini berbeza daripada [huraian] dalam dua hal:
  ///
  /// 1. **Pemarkahan.** [huraian] memadankan rubrik kata kunci yang ditulis
  ///    khas untuk satu soalan. [senarai] membandingkan setiap baris jawapan
  ///    murid dengan senarai jawapan yang diterima skema asal; satu baris yang
  ///    sepadan dengan mana-mana satu jawapan itu mendapat markah penuh.
  /// 2. **Markah berganda.** Skema UPKK kadangkala memberi 2 markah bagi satu
  ///    isi (contohnya "Jelaskan dua adab … (4 markah)" — 2 isi × 2 markah).
  ///    [senarai] membahagikan `markah` sama rata antara [bilanganJawapan].
  senarai,

  /// Kelaskan setiap pernyataan ke dalam salah satu kategori.
  ///
  /// Kertas UPKK memakai bentuk ini untuk "Suaikan pernyataan bahagian (ا)
  /// dengan bahagian (ب)" apabila bahagian (ب) hanya mempunyai dua pilihan.
  /// Ia **bukan** [suai]: dua pernyataan boleh tergolong dalam kategori yang
  /// sama, jadi kategori tidak "habis" apabila dipakai.
  kumpulan;

  static JenisKertas dariTeks(String teks) => switch (teks) {
        'bulat' || 'kariyes' => JenisKertas.bulat,
        'suai' || 'padan' => JenisKertas.suai,
        'betul_salah' => JenisKertas.betulSalah,
        'objektif' => JenisKertas.objektif,
        'tempat_kosong' => JenisKertas.tempatKosong,
        'susun' => JenisKertas.susun,
        'huraian' => JenisKertas.huraian,
        'senarai' => JenisKertas.senarai,
        'kumpulan' => JenisKertas.kumpulan,
        _ => JenisKertas.tulis,
      };

  String get teks => switch (this) {
        JenisKertas.bulat => 'bulat',
        JenisKertas.suai => 'suai',
        JenisKertas.betulSalah => 'betul_salah',
        JenisKertas.objektif => 'objektif',
        JenisKertas.tempatKosong => 'tempat_kosong',
        JenisKertas.susun => 'susun',
        JenisKertas.tulis => 'tulis',
        JenisKertas.huraian => 'huraian',
        JenisKertas.senarai => 'senarai',
        JenisKertas.kumpulan => 'kumpulan',
      };
}

/// Satu sub-soalan dalam kertas UPKK.
///
/// Kertas UPKK menggunakan dua lapis soalan: satu **soalan utama** (yang
/// membawa markah dan arahan) dan beberapa **item** di bawahnya. Contohnya
/// soalan `Bulatkan jawapan yang betul` diikuti lima item bernombor. Model ini
/// mengekalkan dua lapis itu supaya paparan dapat meniru susun atur kertas
/// sebenar dengan tepat.
class SoalanKertas {
  const SoalanKertas({
    required this.id,
    required this.bahagian,
    required this.nombor,
    required this.jenis,
    required this.soalan,
    required this.rumi,
    required this.markah,
    this.item = const [],
    this.bank = const [],
    this.bankRumi = const [],
    this.pasangan = const [],
    this.urutan = const [],
    this.urutanRumi = const [],
    this.rubrik = Rubrik.kosong,
    this.jawapanContoh = const [],
    this.jawapanContohRumi = const [],
    this.bilanganJawapan = 0,
    this.kategori = const [],
    this.kategoriRumi = const [],
    this.bahasa = 'jawi',
  });

  final String id;

  /// Huruf bahagian (`A`–`E`) tempat soalan ini berada.
  final String bahagian;

  /// Nombor soalan seperti yang tercetak pada kertas.
  final int nombor;

  final JenisKertas jenis;

  /// Teks soalan dalam tulisan asal kertas (Jawi atau Arab).
  final String soalan;

  /// Transliterasi Rumi bagi [soalan].
  final String rumi;

  final int markah;

  /// Item di bawah soalan utama.
  final List<ItemKertas> item;

  /// Bank perkataan untuk soalan `tempatKosong`.
  final List<String> bank;
  final List<String> bankRumi;

  /// Pasangan untuk soalan `suai` — kiri dan kanan.
  final List<PasanganKertas> pasangan;

  /// Susunan betul untuk soalan `susun`.
  final List<String> urutan;
  final List<String> urutanRumi;

  /// Rubrik pemarkahan untuk soalan bertulis.
  final Rubrik rubrik;

  /// Contoh jawapan penuh — daripada skema jawapan kertas asal.
  final List<String> jawapanContoh;
  final List<String> jawapanContohRumi;

  /// Bilangan isi yang diminta bagi soalan [JenisKertas.senarai].
  ///
  /// Kertas sebenar mencetak satu ruang bernombor bagi setiap isi ("Tulis dua
  /// adab …"), jadi angka ini juga menentukan bilangan kotak jawapan. Nilai
  /// `0` bermaksud "ikut bilangan jawapan yang diterima".
  final int bilanganJawapan;

  /// Label kategori bagi soalan [JenisKertas.kumpulan].
  ///
  /// Setiap item menyimpan indeks kategori yang betul dalam medan `jawapan`
  /// pada [ItemKertas] — sama medan yang menyimpan indeks pilihan bagi soalan
  /// [JenisKertas.objektif].
  final List<String> kategori;
  final List<String> kategoriRumi;

  /// Tulisan jawapan yang dijangka (`jawi` atau `arab`).
  final String bahasa;

  bool get jawapanArab => bahasa == 'arab';

  /// Bilangan tempat kosong dalam soalan ini.
  int get bilanganKosong {
    var bilangan = 0;
    for (final i in item) {
      bilangan += '____'.allMatches(i.teks).length;
    }
    return bilangan;
  }

  /// Markah penuh yang benar-benar boleh dikutip daripada soalan ini.
  ///
  /// Ia dikira daripada bilangan item atau pasangan, bukan daripada medan
  /// [markah], supaya markah yang dipaparkan sentiasa sepadan dengan apa yang
  /// murid boleh jawab. Markah rasmi kertas tetap diambil daripada
  /// [BahagianFormat] semasa menjumlahkan kertas penuh.
  int get markahBolehDapat => switch (jenis) {
        JenisKertas.bulat ||
        JenisKertas.objektif ||
        JenisKertas.betulSalah =>
          item.isNotEmpty ? item.length : markah,
        JenisKertas.suai => pasangan.length,
        JenisKertas.susun => urutan.length > 1 ? urutan.length : markah,
        JenisKertas.tempatKosong =>
          bilanganKosong > 0 ? bilanganKosong : markah,
        JenisKertas.tulis || JenisKertas.huraian =>
          rubrik.ada ? rubrik.markah : markah,
        // Skema UPKK menulis markah rasmi soalan senarai ("4 markah" bagi dua
        // isi), jadi medan `markah` diutamakan — markah itulah yang dicetak
        // pada kertas. Bilangan jawapan hanya menjadi ganti apabila markah
        // tiada, kerana satu isi lazimnya satu markah.
        JenisKertas.senarai => markah > 0
            ? markah
            : (bilanganJawapan > 0 ? bilanganJawapan : jawapanContoh.length),
        JenisKertas.kumpulan => item.isNotEmpty ? item.length : markah,
      };

  /// Markah yang diperoleh murid bagi soalan ini.
  int markahDiperoleh(JawapanMurid? jawapan) => switch (jenis) {
        JenisKertas.bulat ||
        JenisKertas.objektif =>
          _bilanganItemBetul(jawapan, _semakPilihan),
        JenisKertas.betulSalah =>
          _bilanganItemBetul(jawapan, _semakBetulSalah),
        JenisKertas.suai => jawapan is JawapanPadan
            ? _bilanganPadanBetul(jawapan, _kunciSuai)
            : 0,
        JenisKertas.susun => _markahSusun(jawapan),
        JenisKertas.tempatKosong => jawapan is JawapanTempatKosong
            ? _bilanganKosongBetul(jawapan)
            : 0,
        JenisKertas.tulis || JenisKertas.huraian => _markahTaip(jawapan),
        JenisKertas.senarai => _markahSenarai(jawapan),
        JenisKertas.kumpulan => _bilanganKumpulanBetul(jawapan),
      };

  /// Jawapan contoh untuk dipaparkan selepas murid menghantar jawapan.
  String get jawapanPenuhTeks {
    if (jawapanContoh.isNotEmpty) return jawapanContoh.join('\n');
    return switch (jenis) {
      JenisKertas.bulat || JenisKertas.objektif => item
          .where((i) => i.jawapan >= 0 && i.jawapan < i.pilihan.length)
          .map((i) => i.pilihan[i.jawapan])
          .join(', '),
      JenisKertas.betulSalah =>
        item.map((i) => '${i.teks} (${i.betul == true ? '✓' : '✗'})').join('\n'),
      JenisKertas.suai =>
        pasangan.map((p) => '${p.kiri} — ${p.kanan}').join('\n'),
      JenisKertas.susun => urutan.join(' '),
      JenisKertas.tempatKosong => bank.join(', '),
      JenisKertas.tulis || JenisKertas.huraian => '',
      JenisKertas.senarai => jawapanContoh.join('\n'),
      JenisKertas.kumpulan => [
        for (final i in item)
          if (i.jawapan >= 0 && i.jawapan < kategori.length)
            '${i.teks} — ${kategori[i.jawapan]}'
          else
            i.teks,
      ].join('\n'),
    };
  }

  /// Jawapan betul dalam tulisan yang **boleh dibaca enjin suara**.
  ///
  /// Enjin suara Melayu tidak boleh membaca Jawi, dan enjin suara Arab tidak
  /// boleh membaca Rumi. Panel pembetulan memaparkan tulisan sekolah (Jawi
  /// atau Arab) supaya murid boleh membaca dengan matanya, tetapi apabila
  /// jawapan itu **dibacakan** ia mesti dalam tulisan yang sepadan dengan
  /// enjin — sama seperti bantuan suara pilihan jawapan.
  ///
  /// [jawapanArab] menentukan arah: subjek Bahasa Arab dibaca dengan suara
  /// Arab daripada medan Arab, subjek lain dengan suara Melayu daripada medan
  /// Rumi.
  String get jawapanPenuhDengar {
    if (jawapanArab) return jawapanPenuhTeks;

    if (jawapanContohRumi.isNotEmpty) return jawapanContohRumi.join('\n');
    if (jawapanContoh.isNotEmpty) return jawapanContoh.join('\n');

    return switch (jenis) {
      JenisKertas.bulat || JenisKertas.objektif => item
          .where((i) => i.jawapan >= 0 && i.jawapan < i.pilihanRumi.length)
          .map((i) => i.pilihanRumi[i.jawapan])
          .join(', '),
      JenisKertas.betulSalah =>
        item.map((i) => '${i.rumi} (${i.betul == true ? '✓' : '✗'})').join('\n'),
      JenisKertas.suai =>
        pasangan.map((p) => '${p.kiriRumi} — ${p.kananRumi}').join('\n'),
      JenisKertas.susun => urutanRumi.join(' '),
      JenisKertas.tempatKosong => bankRumi.join(', '),
      JenisKertas.tulis || JenisKertas.huraian => '',
      JenisKertas.senarai => jawapanContohRumi.isNotEmpty
          ? jawapanContohRumi.join('\n')
          : jawapanContoh.join('\n'),
      JenisKertas.kumpulan => [
        for (final i in item)
          if (i.jawapan >= 0 && i.jawapan < kategoriRumi.length)
            '${i.rumi} — ${kategoriRumi[i.jawapan]}'
          else
            i.rumi,
      ].join('\n'),
    };
  }

  /// Kunci jawapan bagi soalan `suai` — indeks kanan yang betul bagi setiap
  /// item kiri.
  ///
  /// Soalan suai UPKK sentiasa dipaparkan dengan lajur kanan yang sudah
  /// dikocok semasa menjawab, jadi kunci disimpan sebagai padanan terus
  /// (0→0, 1→1, …) dan pengocokan dilakukan oleh lapisan paparan.
  List<int> get _kunciSuai =>
      List<int>.generate(pasangan.length, (i) => i);

  int _bilanganPadanBetul(JawapanPadan jawapan, List<int> kunci) {
    var bilangan = 0;
    for (var i = 0; i < kunci.length; i++) {
      if (jawapan.padanan[i] == kunci[i]) bilangan++;
    }
    return bilangan;
  }

  int _markahSusun(JawapanMurid? jawapan) {
    if (urutan.length < 2) {
      // Soalan susun satu baris — markah penuh jika ayat sama.
      return jawapan is JawapanTaip && _samaAyat(jawapan.teks) ? markah : 0;
    }
    if (jawapan is! JawapanSusun || jawapan.susunan.length != urutan.length) {
      return 0;
    }
    var bilangan = 0;
    for (var i = 0; i < urutan.length; i++) {
      if (jawapan.susunan[i] == i) bilangan++;
    }
    return bilangan;
  }

  bool _samaAyat(String teks) {
    String normal(String s) =>
        s.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    return normal(teks) == normal(urutan.join(' '));
  }

  int _bilanganKosongBetul(JawapanTempatKosong jawapan) {
    var bilangan = 0;
    final kunci = _kunciKosong();
    for (var i = 0; i < kunci.length; i++) {
      if (jawapan.isi[i] == kunci[i]) bilangan++;
    }
    return bilangan;
  }

  /// Indeks bank yang betul bagi setiap tempat kosong.
  ///
  /// Bank perkataan dikocok semasa dipaparkan; kunci disimpan sebagai indeks
  /// asal supaya pengocokan tidak mengubah pemarkahan.
  List<int> _kunciKosong() =>
      List<int>.generate(bilanganKosong, (i) => i);

  int _bilanganItemBetul(
    JawapanMurid? jawapan,
    int Function(JawapanMurid, int) semak,
  ) {
    if (jawapan == null || item.isEmpty) return 0;
    var bilangan = 0;
    for (var i = 0; i < item.length; i++) {
      bilangan += semak(jawapan, i);
    }
    return bilangan;
  }

  int _semakPilihan(JawapanMurid jawapan, int i) {
    if (jawapan is! JawapanPilihanKertas) return 0;
    return jawapan.pilihan[i] == item[i].jawapan ? 1 : 0;
  }

  int _semakBetulSalah(JawapanMurid jawapan, int i) {
    if (jawapan is! JawapanBetulSalah) return 0;
    if (i >= jawapan.jawapan.length) return 0;
    return jawapan.jawapan[i] == item[i].betul ? 1 : 0;
  }

  int _bilanganKumpulanBetul(JawapanMurid? jawapan) {
    if (jawapan is! JawapanKumpulan) return 0;
    var bilangan = 0;
    for (var i = 0; i < item.length; i++) {
      if (i >= jawapan.pilihan.length) continue;
      if (jawapan.pilihan[i] == item[i].jawapan) bilangan++;
    }
    return bilangan;
  }

  int _markahTaip(JawapanMurid? jawapan) {
    if (jawapan is! JawapanTaip) return 0;
    if (!rubrik.ada) {
      // Tiada rubrik — bandingkan dengan jawapan contoh secara sederhana.
      if (jawapanContoh.isEmpty) return 0;
      final sama = jawapanContoh.any(
        (c) => Pemarkah.hampirSama(c, jawapan.teks),
      );
      return sama ? markah : 0;
    }
    return Pemarkah.semak(rubrik, jawapan.teks).diperoleh;
  }

  /// Markah bagi soalan [JenisKertas.senarai].
  ///
  /// Skema UPKK menyenaraikan beberapa jawapan yang **semuanya** diterima
  /// ("mana-mana 2 jawapan yang betul diterima"), dan kadangkala satu isi
  /// bernilai lebih daripada satu markah. Jadi setiap baris jawapan murid
  /// dibandingkan dengan senarai [jawapanContoh] — satu baris yang sepadan
  /// dengan mana-mana satu jawapan itu dikira satu isi betul, dan setiap isi
  /// bernilai `markah / bilanganJawapan`.
  int _markahSenarai(JawapanMurid? jawapan) {
    if (jawapan is! JawapanTaip) return 0;

    final diterima =
        jawapanContoh.where((t) => t.trim().isNotEmpty).toList();
    if (diterima.isEmpty) return 0;

    final bilangan = bilanganJawapan > 0 ? bilanganJawapan : diterima.length;
    final betul = Pemarkah.bilanganSenarai(
      diterima: diterima,
      jawapan: jawapan.teks.split('\n'),
      had: bilangan,
    );
    final penuh = markahBolehDapat;
    if (bilangan <= 0 || betul >= bilangan) return penuh;
    return (betul * penuh) ~/ bilangan;
  }

  /// Semak sama ada jawapan murid betul sepenuhnya — untuk maklum balas.
  bool betulPenuh(JawapanMurid? jawapan) =>
      markahBolehDapat > 0 && markahDiperoleh(jawapan) == markahBolehDapat;

  /// Adakah setiap bahagian soalan ini sudah dijawab?
  ///
  /// Ini berbeza daripada sekadar "ada jawapan". Soalan padan yang baru diisi
  /// satu daripada lima pasangan sudah ada jawapan, tetapi ia belum **selesai**
  /// — dan menegur murid pada ketika itu tidak adil.
  ///
  /// Maklum balas dalam app (nada, pujian, bunga api) bergantung pada dua
  /// soalan ini bersama-sama: [betulPenuh] menentukan pujian, dan [lengkap]
  /// menentukan sama ada teguran wajar diberikan.
  ///
  /// `susun` sentiasa `false` kerana murid mengalihkan kad sehingga dia
  /// berpuas hati, tanpa menekan apa-apa — tiada saat "selesai" yang boleh
  /// dikenal pasti, jadi tiada masa yang adil untuk menyatakan dia salah.
  bool lengkap(JawapanMurid? jawapan) => switch (jenis) {
    JenisKertas.bulat || JenisKertas.objektif =>
      jawapan is JawapanPilihanKertas &&
          jawapan.pilihan.isNotEmpty &&
          jawapan.pilihan.length >= item.length &&
          jawapan.pilihan.every((p) => p >= 0),
    JenisKertas.betulSalah =>
      jawapan is JawapanBetulSalah &&
          jawapan.jawapan.isNotEmpty &&
          jawapan.jawapan.length >= item.length &&
          jawapan.jawapan.every((e) => e != null),
    JenisKertas.suai =>
      jawapan is JawapanPadan &&
          pasangan.isNotEmpty &&
          jawapan.padanan.length >= pasangan.length,
    JenisKertas.tempatKosong =>
      jawapan is JawapanTempatKosong &&
          bilanganKosong > 0 &&
          jawapan.isi.length >= bilanganKosong,
    JenisKertas.tulis || JenisKertas.huraian =>
      jawapan is JawapanTaip && jawapan.teks.trim().isNotEmpty,
    // Soalan senarai mencetak satu ruang bagi setiap isi, jadi ia belum
    // "lengkap" sehingga setiap ruang itu berisi.
    JenisKertas.senarai =>
      jawapan is JawapanTaip &&
          jawapan.teks
                  .split('\n')
                  .where((b) => b.trim().isNotEmpty)
                  .length >=
              (bilanganJawapan > 0 ? bilanganJawapan : 1),
    JenisKertas.kumpulan =>
      jawapan is JawapanKumpulan &&
          item.isNotEmpty &&
          jawapan.pilihan.length >= item.length &&
          jawapan.pilihan.every((p) => p >= 0),
    JenisKertas.susun => false,
  };

  /// Salinan soalan dengan bahagian dan nombor baharu.
  ///
  /// Penjana kertas mengambil soalan terus daripada bank, dan bank menyimpan
  /// setiap soalan tanpa bahagian atau nombor tetap — soalan yang sama boleh
  /// muncul di bahagian berbeza pada percubaan berbeza. Nombor dan bahagian
  /// ditetapkan hanya apabila kertas dibina, iaitu di sini.
  SoalanKertas salin({String? bahagian, int? nombor}) => SoalanKertas(
        id: id,
        bahagian: bahagian ?? this.bahagian,
        nombor: nombor ?? this.nombor,
        jenis: jenis,
        soalan: soalan,
        rumi: rumi,
        markah: markah,
        item: item,
        bank: bank,
        bankRumi: bankRumi,
        pasangan: pasangan,
        urutan: urutan,
        urutanRumi: urutanRumi,
        rubrik: rubrik,
        jawapanContoh: jawapanContoh,
        jawapanContohRumi: jawapanContohRumi,
        bilanganJawapan: bilanganJawapan,
        kategori: kategori,
        kategoriRumi: kategoriRumi,
        bahasa: bahasa,
      );

  factory SoalanKertas.dariJson(
    Map<String, dynamic> json, {
    required String bahagian,
    required int nombor,
  }) =>
      SoalanKertas(
        id: json['id'] as String? ?? '$bahagian-$nombor',
        bahagian: bahagian,
        nombor: nombor,
        jenis: JenisKertas.dariTeks(json['jenis'] as String? ?? 'tulis'),
        soalan: json['soalan'] as String? ?? '',
        rumi: json['rumi'] as String? ?? '',
        markah: json['markah'] as int? ?? 0,
        item: ((json['item'] as List?) ?? const [])
            .asMap()
            .entries
            .map((e) => ItemKertas.dariJson(
                  e.value as Map<String, dynamic>,
                  nombor: e.key + 1,
                ))
            .toList(),
        bank: (json['bank'] as List? ?? const []).cast<String>(),
        bankRumi: (json['bankRumi'] as List? ?? const []).cast<String>(),
        pasangan: ((json['pasangan'] as List?) ?? const [])
            .map((e) => PasanganKertas.dariJson(e as Map<String, dynamic>))
            .toList(),
        urutan: (json['urutan'] as List? ?? const []).cast<String>(),
        urutanRumi: (json['urutanRumi'] as List? ?? const []).cast<String>(),
        rubrik: Rubrik.dariJson(json['idea']),
        jawapanContoh:
            (json['jawapanContoh'] as List? ?? const []).cast<String>(),
        jawapanContohRumi:
            (json['jawapanContohRumi'] as List? ?? const []).cast<String>(),
        bilanganJawapan: json['bilanganJawapan'] as int? ?? 0,
        kategori: (json['kategori'] as List? ?? const []).cast<String>(),
        kategoriRumi:
            (json['kategoriRumi'] as List? ?? const []).cast<String>(),
        bahasa: json['bahasa'] as String? ?? 'jawi',
      );
}

/// Satu item di bawah soalan utama.
class ItemKertas {
  const ItemKertas({
    required this.nombor,
    required this.teks,
    required this.rumi,
    this.pilihan = const [],
    this.pilihanRumi = const [],
    this.jawapan = -1,
    this.betul,
    this.jawapanTerima = const [],
    this.markah = 1,
  });

  final int nombor;

  /// Teks item dalam tulisan asal kertas.
  final String teks;
  final String rumi;

  /// Pilihan jawapan (2 pilihan untuk `bulat`, 4 untuk `objektif`).
  final List<String> pilihan;
  final List<String> pilihanRumi;

  /// Indeks pilihan yang betul, atau `-1` jika item ini bukan jenis pilihan.
  final int jawapan;

  /// Jawapan bagi item `betulSalah`.
  final bool? betul;

  /// Jawapan bertulis yang diterima (semua varian ejaan).
  final List<String> jawapanTerima;

  final int markah;

  /// Adakah item ini item `bulat`/`objektif`?
  bool get adaPilihan => pilihan.length >= 2;

  factory ItemKertas.dariJson(Map<String, dynamic> json, {required int nombor}) =>
      ItemKertas(
        nombor: json['nombor'] as int? ?? nombor,
        teks: json['teks'] as String? ?? '',
        rumi: json['rumi'] as String? ?? '',
        pilihan:
            ((json['pilihan'] as List?) ?? const []).map((e) {
          if (e is String) return e;
          if (e is Map) return e['teks'] as String? ?? '';
          return '';
        }).toList(),
        pilihanRumi: ((json['pilihan'] as List?) ?? const []).map((e) {
          if (e is Map) return e['rumi'] as String? ?? '';
          return '';
        }).toList(),
        jawapan: json['jawapan'] as int? ?? -1,
        betul: json['betul'] as bool?,
        jawapanTerima:
            (json['jawapanTerima'] as List? ?? const []).cast<String>(),
        markah: json['markah'] as int? ?? 1,
      );
}

class PasanganKertas {
  const PasanganKertas({
    required this.kiri,
    required this.kanan,
    this.kiriRumi = '',
    this.kananRumi = '',
  });

  final String kiri;
  final String kanan;
  final String kiriRumi;
  final String kananRumi;

  factory PasanganKertas.dariJson(Map<String, dynamic> json) => PasanganKertas(
        kiri: json['kiri'] as String? ?? json['a'] as String? ?? '',
        kanan: json['kanan'] as String? ?? json['b'] as String? ?? '',
        kiriRumi: json['kiriRumi'] as String? ?? json['aRumi'] as String? ?? '',
        kananRumi:
            json['kananRumi'] as String? ?? json['bRumi'] as String? ?? '',
      );
}

/// Satu bahagian penuh dalam satu kertas.
class BahagianKertas {
  const BahagianKertas({
    required this.nama,
    required this.markah,
    required this.arahan,
    required this.arahanRumi,
    required this.soalan,
  });

  final String nama;
  final int markah;
  final String arahan;
  final String arahanRumi;
  final List<SoalanKertas> soalan;

  /// Markah sebenar yang boleh dikutip daripada soalan yang ada.
  ///
  /// Jika bank soalan tidak cukup untuk memenuhi format rasmi, nilai ini lebih
  /// kecil daripada [markah]. Kertas percubaan tetap memaparkan markah rasmi
  /// supaya murid biasa dengan bentuk kertas sebenar.
  int get markahTersedia =>
      soalan.fold(0, (jumlah, s) => jumlah + s.markahBolehDapat);

  factory BahagianKertas.dariJson(Map<String, dynamic> json) {
    final nama = json['nama'] as String? ?? 'A';
    return BahagianKertas(
      nama: nama,
      markah: json['markah'] as int? ?? 0,
      arahan: json['arahan'] as String? ?? '',
      arahanRumi: json['arahanRumi'] as String? ?? '',
      soalan: ((json['soalan'] as List?) ?? const [])
          .asMap()
          .entries
          .map((e) => SoalanKertas.dariJson(
                e.value as Map<String, dynamic>,
                bahagian: nama,
                nombor: e.key + 1,
              ))
          .toList(),
    );
  }
}

/// Satu kertas penuh — sama ada kertas percubaan yang dijana, atau kertas
/// ramalan yang telah dihurai daripada PDF.
class Kertas {
  const Kertas({
    required this.id,
    required this.subjekId,
    required this.tajuk,
    required this.sumber,
    required this.jenisSumber,
    required this.bahagian,
    this.masaMinit = FormatUpkk.masaMinit,
  });

  final String id;
  final String subjekId;
  final String tajuk;

  /// Keterangan sumber — dipaparkan pada kulit kertas dan skrin info.
  final String sumber;

  /// `percubaan`, `ramalan`, atau `latihan`.
  final String jenisSumber;

  final List<BahagianKertas> bahagian;
  final int masaMinit;

  /// Semua soalan dalam kertas, mengikut turutan bahagian.
  List<SoalanKertas> get semuaSoalan =>
      [for (final b in bahagian) ...b.soalan];

  int get bilanganSoalan => semuaSoalan.length;

  /// Jumlah markah rasmi kertas ini.
  int get markahPenuh =>
      bahagian.fold(0, (jumlah, b) => jumlah + b.markah);

  /// Markah yang benar-benar boleh dikutip daripada soalan yang ada.
  int get markahTersedia =>
      bahagian.fold(0, (jumlah, b) => jumlah + b.markahTersedia);

  BahagianKertas? bahagianBernama(String nama) {
    for (final b in bahagian) {
      if (b.nama == nama) return b;
    }
    return null;
  }

  int markahDiperoleh(Map<String, JawapanMurid> jawapan) {
    var jumlah = 0;
    for (final s in semuaSoalan) {
      jumlah += s.markahDiperoleh(jawapan[s.id]);
    }
    return jumlah;
  }

  /// Markah diperoleh bagi satu bahagian — untuk pecahan markah pada laporan.
  int markahBahagian(String nama, Map<String, JawapanMurid> jawapan) {
    final b = bahagianBernama(nama);
    if (b == null) return 0;
    return b.soalan.fold(
      0,
      (jumlah, s) => jumlah + s.markahDiperoleh(jawapan[s.id]),
    );
  }

  /// Peratus berdasarkan markah yang boleh dikutip.
  int peratus(Map<String, JawapanMurid> jawapan) {
    final penuh = markahTersedia;
    if (penuh <= 0) return 0;
    return ((markahDiperoleh(jawapan) / penuh) * 100).round();
  }

  static final Random _rawakKekal = Random(20261231);

  /// Bilangan berbeza antara satu kertas percubaan dengan yang berikutnya.
  static int nomborSiri(String id) {
    var jumlah = 0;
    for (final unit in id.codeUnits) {
      jumlah = (jumlah * 31 + unit) & 0x7fffffff;
    }
    return jumlah % 1000 + 1;
  }

  /// Benih rawak yang stabil bagi satu kertas — supaya susunan pilihan jawapan
  /// tidak berubah setiap kali skrin dibina semula.
  int get benih => id.codeUnits.fold(17, (a, b) => (a * 31 + b) & 0x7fffffff);

  factory Kertas.dariJson(Map<String, dynamic> json) => Kertas(
        id: json['id'] as String? ?? '',
        subjekId: json['subjek'] as String? ?? '',
        tajuk: json['tajuk'] as String? ?? '',
        sumber: json['sumber'] as String? ?? '',
        jenisSumber: json['jenisSumber'] as String? ?? 'ramalan',
        masaMinit: json['masa'] as int? ?? FormatUpkk.masaMinit,
        bahagian: ((json['bahagian'] as List?) ?? const [])
            .map((e) => BahagianKertas.dariJson(e as Map<String, dynamic>))
            .toList(),
      );

  static Random get rawakKekal => _rawakKekal;
}

/// Tukar warna dalam bentuk teks heks (`#RRGGBB`) kepada [Color].
///
/// Warna setiap subjek disimpan dalam fail JSON supaya tema dapat diubah tanpa
/// menyentuh kod. Jika teks itu tidak sah, warna utama app digunakan sebagai
/// ganti — kad subjek tidak sepatutnya gagal dipaparkan hanya kerana satu
/// kesilapan menaip dalam fail data.
Color warnaDariHex(String? hex) {
  if (hex == null || hex.length != 7 || !hex.startsWith('#')) {
    return const Color(0xFFD81B60);
  }
  final nilai = int.tryParse(hex.substring(1), radix: 16);
  if (nilai == null) return const Color(0xFFD81B60);
  return Color(0xFF000000 | nilai);
}
