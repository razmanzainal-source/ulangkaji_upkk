import 'dart:typed_data';

import 'package:gal/gal.dart';

/// Simpan gambar ke galeri foto telefon (Android dan iOS).
///
/// Kebenaran galeri diminta di sini — pengguna hanya ditanya apabila dia
/// benar-benar menekan butang simpan, bukan semasa app dibuka.
///
/// Memulangkan `false` apabila kebenaran ditolak atau penyimpanan gagal.
Future<bool> simpanGambarKeGaleri(Uint8List bait, {required String nama}) async {
  try {
    if (!await Gal.hasAccess()) {
      final dibenarkan = await Gal.requestAccess();
      if (!dibenarkan) return false;
    }
    await Gal.putImageBytes(bait, name: nama);
    return true;
  } catch (_) {
    return false;
  }
}
