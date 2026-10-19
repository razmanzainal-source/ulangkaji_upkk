import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../models/gred.dart';

/// Kongsi keputusan percubaan.
///
/// App ini tidak pernah menghantar apa-apa sendiri. Keputusan hanya keluar
/// daripada peranti apabila ibu bapa atau murid memilih app di dalam lembaran
/// kongsi telefon. Semua kerja berlaku di dalam peranti.
///
/// Dua bentuk perkongsian disediakan:
///
///   * **Teks** ([keputusanKertas]) — ringkasan markah dan gred, mudah dihantar
///     di WhatsApp kepada guru atau ibu bapa.
///   * **Gambar** ([tangkapImej] + [kongsiImej]) — kad keputusan ditangkap
///     sebagai PNG untuk Instagram atau Threads, yang tidak menerima teks
///     sahaja.
class Kongsi {
  Kongsi._();

  /// Kapsyen perkongsian keputusan satu kertas.
  ///
  /// Nama murid sengaja tidak dimasukkan: kad keputusan mungkin tersebar lebih
  /// jauh daripada yang dijangkakan, dan nama kanak-kanak tidak perlu bersama
  /// markahnya.
  static String kapsyenKeputusan({
    required String tajuk,
    required int markah,
    required int penuh,
    required int peratus,
    required Gred gred,
    String pecahan = '',
  }) {
    final baris = StringBuffer()
      ..writeln('$tajuk — $markah/$penuh markah '
          '($peratus%), Gred ${gred.huruf} (${gred.nama})');
    if (pecahan.isNotEmpty) baris.writeln(pecahan);
    if (peratus >= 80) {
      baris.writeln('Cemerlang! 🎉');
    } else if (peratus >= 60) {
      baris.writeln('Bagus, teruskan berlatih! 💪');
    } else {
      baris.writeln('Akan cuba lagi! 📚');
    }
    baris.write('\n📚 Ulang kaji dengan app "Ulangkaji UPKK".');
    return baris.toString();
  }

  /// Buka lembaran kongsi dengan ringkasan keputusan.
  ///
  /// Kegagalan perkongsian tidak pernah dipaparkan sebagai ralat kepada
  /// pengguna — ia bukan sesuatu yang perlu dibimbangkan oleh murid.
  static Future<ShareResult?> keputusanKertas({
    required String tajuk,
    required int markah,
    required int penuh,
    required int peratus,
    required String gred,
    String pecahan = '',
  }) async {
    final gredObjek = Gred.values.firstWhere(
      (g) => g.huruf == gred,
      orElse: () => Gred.dariPeratus(peratus),
    );
    return kongsiTeks(
      kapsyenKeputusan(
        tajuk: tajuk,
        markah: markah,
        penuh: penuh,
        peratus: peratus,
        gred: gredObjek,
        pecahan: pecahan,
      ),
    );
  }

  /// Kongsi teks sahaja.
  static Future<ShareResult?> kongsiTeks(String teks) async {
    try {
      return await SharePlus.instance.share(
        ShareParams(text: teks, subject: 'Ulangkaji UPKK'),
      );
    } catch (_) {
      return null;
    }
  }

  /// Tangkap kad keputusan sebagai gambar PNG.
  ///
  /// [kunci] mesti dilekatkan pada `RepaintBoundary` yang mengandungi kad itu,
  /// dan kad itu mesti **sudah dilukis** sebelum fungsi ini dipanggil — tunggu
  /// satu bingkai selepas kad dimasukkan ke dalam pokok widget.
  ///
  /// Memulangkan `null` apabila penangkapan gagal, supaya skrin boleh
  /// memaklumkan pengguna tanpa meruntuhkan app.
  static Future<Uint8List?> tangkapImej(
    GlobalKey kunci, {
    double skala = 3,
  }) async {
    final objek = kunci.currentContext?.findRenderObject();
    if (objek is! RenderRepaintBoundary) return null;
    try {
      final imej = await objek.toImage(pixelRatio: skala);
      final data = await imej.toByteData(format: ui.ImageByteFormat.png);
      imej.dispose();
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// Buka lembaran kongsi dengan gambar kad keputusan.
  static Future<ShareResult?> kongsiImej({
    required Uint8List imej,
    required String namaFail,
    required String teks,
  }) async {
    try {
      return await SharePlus.instance.share(
        ShareParams(
          text: teks,
          subject: 'Ulangkaji UPKK',
          files: [XFile.fromData(imej, name: namaFail, mimeType: 'image/png')],
          fileNameOverrides: [namaFail],
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
