import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Simpan gambar sebagai muat turun fail di dalam pelayar (versi web).
///
/// Di dalam pelayar tiada galeri foto, jadi butang "Simpan" menurunkan fail
/// `qr_sumbangan.png` — pengguna boleh menyimpannya atau berkongsinya.
Future<bool> simpanGambarKeGaleri(Uint8List bait, {required String nama}) async {
  try {
    final blob = web.Blob(
      <web.BlobPart>[bait.toJS].toJS,
      web.BlobPropertyBag(type: 'image/png'),
    );
    final url = web.URL.createObjectURL(blob);
    web.HTMLAnchorElement()
      ..href = url
      ..download = '$nama.png'
      ..click();
    web.URL.revokeObjectURL(url);
    return true;
  } catch (_) {
    return false;
  }
}
