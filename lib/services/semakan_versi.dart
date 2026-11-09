import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../tema.dart';

/// Status kemas kini app.
enum StatusKemasKini {
  /// Versi semasa sudah terkini (atau versi terkini tidak diketahui).
  tiada,

  /// Ada versi baharu, tetapi app masih boleh digunakan. Pengguna diberi
  /// pilihan "Nanti".
  galak,

  /// Versi semasa di bawah had minimum. Dialog tidak boleh ditutup — murid
  /// mesti mengemas kini dahulu supaya tidak menggunakan kandungan lapuk.
  paksa,
}

/// Maklumat versi yang dibaca daripada fail `versi.json` yang dihoskan di
/// GitHub Pages.
@immutable
class MaklumatVersi {
  const MaklumatVersi({
    required this.terkini,
    required this.minimum,
    required this.pautan,
    this.nota,
  });

  /// Versi terbaharu yang ada di kedai.
  final String terkini;

  /// Versi paling lama yang masih dibenarkan. Jika versi semasa lebih rendah,
  /// kemas kini dipaksa.
  final String minimum;

  /// Pautan kedai untuk mengemas kini.
  final String pautan;

  /// Nota ringkas (pilihan) untuk dipaparkan pada dialog.
  final String? nota;

  StatusKemasKini bandingkan(String versiSemasa) {
    if (_lebihBaru(minimum, versiSemasa)) return StatusKemasKini.paksa;
    if (_lebihBaru(terkini, versiSemasa)) return StatusKemasKini.galak;
    return StatusKemasKini.tiada;
  }

  static MaklumatVersi? daripadaJson(
    Object? json, {
    required String platform,
    required String pautanLalai,
  }) {
    if (json is! Map) return null;
    final bahagian = json[platform];
    if (bahagian is! Map) return null;
    final terkini = bahagian['terkini'];
    if (terkini is! String || terkini.trim().isEmpty) return null;
    final minimum = bahagian['minimum'];
    final pautan = bahagian['pautan'];
    final nota = json['nota'];
    return MaklumatVersi(
      terkini: terkini.trim(),
      minimum: (minimum is String && minimum.trim().isNotEmpty)
          ? minimum.trim()
          : terkini.trim(),
      pautan: (pautan is String && pautan.trim().isNotEmpty)
          ? pautan.trim()
          : pautanLalai,
      nota: nota is String && nota.trim().isNotEmpty ? nota.trim() : null,
    );
  }

  /// Benar apabila [calon] lebih tinggi daripada [semasa].
  static bool _lebihBaru(String calon, String semasa) {
    final a = _pecah(calon);
    final b = _pecah(semasa);
    final panjang = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < panjang; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  static List<int> _pecah(String versi) {
    final bersih = versi.split('+').first.split('-').first.trim();
    return bersih
        .split('.')
        .map((b) => int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }
}

/// Pemeriksaan versi automatik.
///
/// App ini berfungsi tanpa Internet. Pemeriksaan versi dilakukan di latar
/// belakang selepas app dibuka; jika tiada Internet atau sumber gagal
/// dihubungi, app terus berjalan seperti biasa tanpa sebarang gangguan.
///
/// Sumber: `versi.json` yang dihoskan bersama dasar privasi. Fail itu
/// dikemas kini setiap kali versi baharu diterbitkan.
class SemakanVersi {
  SemakanVersi._();

  static final SemakanVersi instance = SemakanVersi._();

  /// Alamat fail versi.
  static const String urlVersi =
      'https://razmanzainal-source.github.io/ulangkaji-upkk-legal/versi.json';

  /// iTunes Lookup — sumber rasmi versi App Store.
  static const String urlAppStore =
      'https://itunes.apple.com/lookup?bundleId=com.razmanzainal.ulangkajiUpkk&country=my';

  static const String pautanAppStore =
      'https://apps.apple.com/my/app/id6830672652';
  static const String pautanPlay =
      'https://play.google.com/store/apps/details?id=com.razmanzainal.ulangkaji_upkk';

  /// Fungsi boleh diganti dalam ujian.
  @visibleForTesting
  Future<String?> Function(Uri uri) ambilJson = _ambilJsonBenar;

  @visibleForTesting
  Future<String> Function() bacaVersiSemasa = _bacaVersiBenar;

  /// Pautan kedai mengikut platform semasa.
  String get pautanKedai {
    if (kIsWeb) return pautanPlay;
    return Platform.isIOS ? pautanAppStore : pautanPlay;
  }

  /// Digunakan dalam ujian untuk memaksa platform.
  @visibleForTesting
  String? platformUjian;

  String get _platform {
    if (platformUjian != null) return platformUjian!;
    if (kIsWeb) return 'android';
    return Platform.isIOS ? 'ios' : 'android';
  }

  /// Baca versi semasa yang dipasang.
  Future<String?> versiSemasa() async {
    try {
      return await bacaVersiSemasa();
    } catch (_) {
      return null;
    }
  }

  /// Semak versi terkini di kedai. Pulang `null` jika tidak dapat disemak.
  ///
  /// Pada iOS, versi terbaharu dibaca terus daripada **App Store** (iTunes
  /// Lookup API). Ini bermakna setiap kali versi baharu disahkan Apple dan
  /// tersedia di kedai, app lama akan tahu tanpa perlu mengemas kini fail
  /// manual. `versi.json` pula menentukan versi **minimum** yang masih
  /// dibenarkan (dan boleh menindih nilai terkini jika perlu).
  Future<MaklumatVersi?> semak() async {
    MaklumatVersi? dariFail;
    try {
      final teks = await ambilJson(Uri.parse(urlVersi))
          .timeout(const Duration(seconds: 6));
      if (teks != null && teks.trim().isNotEmpty) {
        dariFail = MaklumatVersi.daripadaJson(
          jsonDecode(teks),
          platform: _platform,
          pautanLalai: pautanKedai,
        );
      }
    } catch (_) {
      // Tiada Internet, JSON rosak, atau masa tamat — cuba sumber lain.
    }

    if (_platform == 'ios') {
      final versiKedai = await versiAppStore();
      if (versiKedai != null) {
        // `terkini` daripada App Store (paling tepat). `minimum` hanya
        // diambil daripada versi.json; tanpanya kemas kini tidak dipaksa.
        return MaklumatVersi(
          terkini: versiKedai,
          minimum: dariFail?.minimum ?? '0.0.0',
          pautan: dariFail?.pautan ?? pautanKedai,
          nota: dariFail?.nota,
        );
      }
    }

    return dariFail;
  }

  /// Baca versi terkini app ini di App Store. `null` jika tiada Internet,
  /// app belum terbit, atau jawapan tidak dapat difahami.
  Future<String?> versiAppStore() async {
    try {
      final teks = await ambilJson(Uri.parse(urlAppStore))
          .timeout(const Duration(seconds: 6));
      if (teks == null || teks.trim().isEmpty) return null;
      final json = jsonDecode(teks);
      if (json is! Map) return null;
      final hasil = json['results'];
      if (hasil is! List || hasil.isEmpty) return null;
      final pertama = hasil.first;
      if (pertama is! Map) return null;
      final versi = pertama['version'];
      if (versi is! String || versi.trim().isEmpty) return null;
      return versi.trim();
    } catch (_) {
      return null;
    }
  }

  /// Semak dan paparkan dialog jika perlu. Tidak pernah membaling ralat.
  Future<void> semakDanTunjuk(GlobalKey<NavigatorState> kunci) async {
    final maklumat = await semak();
    if (maklumat == null) return;
    final semasa = await versiSemasa();
    if (semasa == null) return;

    final status = maklumat.bandingkan(semasa);
    if (status == StatusKemasKini.tiada) return;

    final konteks = kunci.currentContext;
    if (konteks == null || !konteks.mounted) return;

    await showDialog<void>(
      context: konteks,
      barrierDismissible: status == StatusKemasKini.galak,
      builder: (_) => DialogKemasKini(
        maklumat: maklumat,
        paksa: status == StatusKemasKini.paksa,
        versiSemasa: semasa,
      ),
    );
  }

  @visibleForTesting
  void setSemula() {
    ambilJson = _ambilJsonBenar;
    bacaVersiSemasa = _bacaVersiBenar;
    platformUjian = null;
  }

  static Future<String?> _ambilJsonBenar(Uri uri) async {
    final klien = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5);
    try {
      final permintaan = await klien.getUrl(uri);
      permintaan.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      final jawapan = await permintaan.close();
      if (jawapan.statusCode != 200) return null;
      return await jawapan.transform(utf8.decoder).join();
    } finally {
      klien.close(force: true);
    }
  }

  static Future<String> _bacaVersiBenar() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }
}

/// Dialog kemas kini.
class DialogKemasKini extends StatelessWidget {
  const DialogKemasKini({
    super.key,
    required this.maklumat,
    required this.paksa,
    required this.versiSemasa,
  });

  final MaklumatVersi maklumat;
  final bool paksa;
  final String versiSemasa;

  Future<void> _bukaKedai() async {
    try {
      await launchUrl(Uri.parse(maklumat.pautan),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      // Pautan gagal dibuka — pengguna boleh membuka kedai secara manual.
    }
  }

  @override
  Widget build(BuildContext context) {
    final dialog = AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.system_update_rounded, color: Warna.utama),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              paksa ? 'Kemas kini diperlukan' : 'Versi baharu tersedia',
              style: Teks.sederhana,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ulangkaji UPKK versi ${maklumat.terkini} sudah tersedia. '
            'Sila kemas kini melalui kedai aplikasi untuk terus menggunakan '
            'app ini.',
            style: Teks.biasa.copyWith(height: 1.5),
          ),
          if (maklumat.nota != null) ...[
            const SizedBox(height: 10),
            Text(
              maklumat.nota!,
              style: Teks.kecil.copyWith(color: Colors.black54, height: 1.5),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Versi dipasang: $versiSemasa',
            style: Teks.kecil.copyWith(color: Colors.black45),
          ),
        ],
      ),
      actions: [
        if (!paksa)
          TextButton(
            key: const ValueKey('kemas-kini-nanti'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Nanti'),
          ),
        FilledButton(
          key: const ValueKey('kemas-kini-buka'),
          onPressed: _bukaKedai,
          style: FilledButton.styleFrom(backgroundColor: Warna.utama),
          child: const Text('Kemas kini sekarang'),
        ),
      ],
    );

    if (!paksa) return dialog;
    // Kemas kini wajib: dialog tidak boleh ditutup dengan butang kembali.
    return PopScope(canPop: false, child: dialog);
  }
}
