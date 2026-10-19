import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/gred.dart';

/// Rekod satu percubaan menjawab kertas penuh.
///
/// Disimpan selepas murid menghantar kertas, dan dipaparkan semula pada skrin
/// Kemajuan supaya ibu bapa dapat melihat perkembangan dari semasa ke semasa.
/// Markah pecahan setiap bahagian disimpan kerana bahagian kertas UPKK menguji
/// kemahiran yang berbeza — pecahan inilah yang menunjukkan bahagian mana
/// perlu diulang.
class RekodPercubaan {
  const RekodPercubaan({
    required this.tarikh,
    required this.subjekId,
    required this.kertasId,
    required this.tajuk,
    required this.markah,
    required this.markahPenuh,
    required this.saat,
    this.markahBahagian = const {},
    this.latihan = false,
  });

  final DateTime tarikh;
  final String subjekId;
  final String kertasId;
  final String tajuk;
  final int markah;
  final int markahPenuh;

  /// Masa menjawab dalam saat.
  final int saat;

  /// Markah diperoleh bagi setiap bahagian (`A`, `B`, …).
  final Map<String, int> markahBahagian;

  /// Benar apabila rekod ini daripada **latih tubi**, bukan kertas percubaan.
  ///
  /// Latih tubi hanya sepuluh soalan, jadi markahnya tidak boleh dibandingkan
  /// dengan kertas 70 markah. Rekodnya tetap disimpan supaya tarikh ulang kaji
  /// dan rentetan hari tidak hilang — tetapi ia **tidak** diambil kira sebagai
  /// markah terbaik subjek. Tanpa penanda ini, satu latihan sepuluh soalan yang
  /// sempurna akan muncul pada kad subjek sebagai "15/70 • Gred A".
  final bool latihan;

  int get peratus =>
      markahPenuh <= 0 ? 0 : ((markah / markahPenuh) * 100).round();

  Gred get gred => Gred.dariPeratus(peratus);

  /// Teks skor, contohnya "58 / 70".
  String get skorTeks => '$markah / $markahPenuh';

  /// Masa menjawab dalam bentuk "1 jam 5 minit" atau "12 minit".
  String get masaTeks {
    final minit = saat ~/ 60;
    if (minit < 60) return '$minit minit';
    final jam = minit ~/ 60;
    final baki = minit % 60;
    return baki == 0 ? '$jam jam' : '$jam jam $baki minit';
  }

  Map<String, dynamic> keJson() => {
        't': tarikh.toIso8601String(),
        's': subjekId,
        'k': kertasId,
        'j': tajuk,
        'm': markah,
        'p': markahPenuh,
        'd': saat,
        'b': markahBahagian,
        'l': latihan,
      };

  factory RekodPercubaan.dariJson(Map<String, dynamic> json) => RekodPercubaan(
        tarikh: DateTime.tryParse(json['t'] as String? ?? '') ?? DateTime(2000),
        subjekId: json['s'] as String? ?? '',
        kertasId: json['k'] as String? ?? '',
        tajuk: json['j'] as String? ?? '',
        markah: json['m'] as int? ?? 0,
        markahPenuh: json['p'] as int? ?? 0,
        saat: json['d'] as int? ?? 0,
        markahBahagian:
            (json['b'] as Map?)?.map((k, v) => MapEntry('$k', v as int)) ??
                const {},
        latihan: json['l'] as bool? ?? false,
      );
}

/// Ringkasan pencapaian satu subjek — untuk kad pada skrin Kemajuan.
class RingkasanSubjek {
  const RingkasanSubjek({
    required this.subjekId,
    required this.percubaan,
    required this.markahTerbaik,
    required this.peratusTerbaik,
    required this.saatTerakhir,
  });

  final String subjekId;

  /// Bilangan percubaan yang telah dibuat.
  final int percubaan;

  final int markahTerbaik;
  final int peratusTerbaik;
  final DateTime? saatTerakhir;

  Gred get gredTerbaik => Gred.dariPeratus(peratusTerbaik);

  bool get adaRekod => percubaan > 0;
}

/// Kemajuan murid — disimpan dalam storan peranti, bukan dihantar ke mana-mana.
///
/// App ini berfungsi tanpa Internet dan tidak mengumpul data murid. Semua
/// rekod kekal dalam telefon sahaja, dan boleh dipadam oleh ibu bapa pada
/// skrin Info.
class Kemajuan {
  Kemajuan._();

  static final Kemajuan instance = Kemajuan._();

  static const String _kunciRekod = 'rekod_percubaan';
  static const String _kunciGiliran = 'giliran_subjek';
  static const String _kunciBetul = 'betul_';
  static const String _kunciSalah = 'salah_';

  /// Had rekod yang disimpan — cukup untuk melihat perkembangan beberapa bulan
  /// tanpa membesar tanpa had.
  static const int hadRekod = 60;

  SharedPreferences? _p;
  List<RekodPercubaan> _rekod = [];
  Map<String, int> _giliran = {};

  List<RekodPercubaan> get rekod => List.unmodifiable(_rekod);

  /// Rekod **kertas percubaan** sahaja — tanpa latih tubi.
  ///
  /// Ini senarai yang dipaparkan sebagai "percubaan terkini" pada skrin
  /// Kemajuan, dan asas kepada purata markah. Latih tubi disimpan berasingan
  /// kerana sepuluh soalan tidak boleh dibandingkan dengan kertas 70 markah.
  List<RekodPercubaan> get rekodKertas =>
      List.unmodifiable(_rekod.where((r) => !r.latihan));

  bool get sedia => _p != null;

  Future<void> muat() async {
    try {
      _p = await SharedPreferences.getInstance();
      final teks = _p?.getString(_kunciRekod);
      if (teks != null && teks.isNotEmpty) {
        final senarai = jsonDecode(teks) as List;
        _rekod = senarai
            .map((e) => RekodPercubaan.dariJson(e as Map<String, dynamic>))
            .toList();
      }
      final giliran = _p?.getString(_kunciGiliran);
      if (giliran != null && giliran.isNotEmpty) {
        _giliran = (jsonDecode(giliran) as Map)
            .map((k, v) => MapEntry('$k', v as int));
      }
    } catch (_) {
      // Rekod yang rosak tidak boleh menghalang app daripada dibuka. Ia
      // diabaikan, dan rekod baharu akan ditulis dari awal.
      _rekod = [];
      _giliran = {};
    }
  }

  // --- Penguasaan soalan ---------------------------------------------------

  int bilanganBetul(String soalanId) => _p?.getInt('$_kunciBetul$soalanId') ?? 0;

  int bilanganSalah(String soalanId) => _p?.getInt('$_kunciSalah$soalanId') ?? 0;

  /// Adakah murid pernah menjawab soalan ini dengan betul?
  bool sudahDikuasai(String soalanId) => bilanganBetul(soalanId) > 0;

  /// Adakah soalan ini perlu diulang — lebih banyak salah daripada betul?
  bool perluUlang(String soalanId) =>
      bilanganSalah(soalanId) > bilanganBetul(soalanId);

  Future<void> rekodJawapan({
    required String soalanId,
    required bool betul,
  }) async {
    final p = _p;
    if (p == null) return;
    final kunci = betul ? '$_kunciBetul$soalanId' : '$_kunciSalah$soalanId';
    await p.setInt(kunci, (p.getInt(kunci) ?? 0) + 1);
  }

  // --- Giliran soalan ------------------------------------------------------

  /// Nombor giliran semasa bagi satu subjek.
  ///
  /// Penjana kertas menggunakan nombor ini untuk memulakan carian pada tempat
  /// yang berbeza dalam bank soalan, supaya setiap percubaan menghasilkan
  /// kertas yang berbeza walaupun bank soalan yang sama digunakan semula.
  int giliran(String subjekId) => _giliran[subjekId] ?? 0;

  Future<void> majukanGiliran(String subjekId) async {
    _giliran[subjekId] = giliran(subjekId) + 1;
    await _p?.setString(_kunciGiliran, jsonEncode(_giliran));
  }

  // --- Rekod percubaan -----------------------------------------------------

  Future<void> simpanPercubaan(RekodPercubaan rekodBaharu) async {
    _rekod.insert(0, rekodBaharu);
    // Apabila had dicapai, rekod **latih tubi lama** dibuang dahulu. Rekod
    // kertas percubaan ialah rekod yang ibu bapa benar-benar mahu lihat, dan
    // murid yang membuat latih tubi setiap hari boleh menyesakkannya keluar
    // dalam beberapa minggu.
    while (_rekod.length > hadRekod) {
      final latihanLama = _rekod.lastIndexWhere((r) => r.latihan);
      _rekod.removeAt(latihanLama >= 0 ? latihanLama : _rekod.length - 1);
    }
    await _p?.setString(
      _kunciRekod,
      jsonEncode(_rekod.map((r) => r.keJson()).toList()),
    );
  }

  List<RekodPercubaan> rekodSubjek(String subjekId) =>
      _rekod.where((r) => r.subjekId == subjekId).toList();

  RekodPercubaan? terakhirSubjek(String subjekId) {
    for (final r in _rekod) {
      if (r.subjekId == subjekId) return r;
    }
    return null;
  }

  RingkasanSubjek ringkasan(String subjekId) {
    // Latih tubi dikecualikan: markahnya daripada sepuluh soalan, dan
    // membandingkannya dengan kertas 70 markah menghasilkan "15/70 • Gred A"
    // yang palsu pada kad subjek.
    final senarai = rekodSubjek(subjekId).where((r) => !r.latihan).toList();
    if (senarai.isEmpty) {
      return RingkasanSubjek(
        subjekId: subjekId,
        percubaan: 0,
        markahTerbaik: 0,
        peratusTerbaik: 0,
        saatTerakhir: null,
      );
    }
    var terbaik = senarai.first;
    for (final r in senarai) {
      if (r.peratus > terbaik.peratus) terbaik = r;
    }
    return RingkasanSubjek(
      subjekId: subjekId,
      percubaan: senarai.length,
      markahTerbaik: terbaik.markah,
      peratusTerbaik: terbaik.peratus,
      saatTerakhir: senarai.first.tarikh,
    );
  }

  /// Bilangan hari berturut-turut murid membuat percubaan.
  ///
  /// Menggalakkan murid mengulang kaji sedikit tetapi kerap — lebih baik
  /// daripada satu sesi panjang seminggu sekali.
  int get rentetanHari {
    if (_rekod.isEmpty) return 0;
    final hari = _rekod
        .map((r) => DateTime(r.tarikh.year, r.tarikh.month, r.tarikh.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    final hariIni = DateTime.now();
    final semalam = hariIni.subtract(const Duration(days: 1));
    bool samaHari(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    if (!samaHari(hari.first, hariIni) && !samaHari(hari.first, semalam)) {
      return 0;
    }
    var bilangan = 1;
    for (var i = 1; i < hari.length; i++) {
      final beza = hari[i - 1].difference(hari[i]).inDays;
      if (beza == 1) {
        bilangan++;
      } else {
        break;
      }
    }
    return bilangan;
  }

  /// Padam semua rekod — untuk butang "Padam rekod" pada skrin Info.
  Future<void> padamSemua() async {
    _rekod = [];
    _giliran = {};
    final p = _p;
    if (p == null) return;
    await p.remove(_kunciRekod);
    await p.remove(_kunciGiliran);
    final kunci = p.getKeys().where(
          (k) => k.startsWith(_kunciBetul) || k.startsWith(_kunciSalah),
        );
    for (final k in kunci) {
      await p.remove(k);
    }
  }
}
