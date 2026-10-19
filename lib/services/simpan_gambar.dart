/// Menyimpan gambar ke storan pengguna — berbeza mengikut platform.
///
/// - Android/iOS: gambar disimpan ke **galeri foto** melalui pakej `gal`.
/// - Web: gambar dimuat turun sebagai fail (`qr_sumbangan.png`).
///
/// Kedua-dua pelaksanaan memulangkan `false` (bukan melontar ralat) apabila
/// penyimpanan gagal, supaya skrin boleh memaklumkan pengguna dengan tenang.
library;

export 'simpan_gambar_io.dart'
    if (dart.library.js_interop) 'simpan_gambar_web.dart';
