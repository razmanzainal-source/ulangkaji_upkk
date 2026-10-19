import 'package:flutter/material.dart';

/// Skala teks app.
///
/// Semua skrin menggunakan saiz daripada senarai ini sahaja. Saiz huruf yang
/// berubah-ubah antara skrin mengganggu kanak-kanak yang mudah hilang tumpuan,
/// dan menjadikan app kelihatan tidak kemas. Ketebalan (weight) dan warna
/// boleh diubah dengan `copyWith`, tetapi **saiz** mesti datang dari sini.
class Teks {
  Teks._();

  /// Nombor skor besar — "62 / 70".
  static const TextStyle gergasi = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w900,
    height: 1.1,
  );

  /// Emoji besar dalam pilihan jawapan.
  static const TextStyle gambar = TextStyle(fontSize: 32, height: 1.2);

  /// Ayat Jawi — saiz besar supaya huruf Jawi yang halus mudah dibaca.
  ///
  /// Tulisan Jawi lebih kecil mata hurufnya berbanding Rumi pada saiz yang
  /// sama, jadi ayat Jawi sentiasa satu langkah lebih besar daripada Rumi.
  static const TextStyle jawi = TextStyle(
    fontFamily: 'Jawi',
    fontSize: 24,
    height: 1.8,
  );

  /// Ayat Jawi pada kepala kertas dan label kecil.
  static const TextStyle jawiKecil = TextStyle(
    fontFamily: 'Jawi',
    fontSize: 17,
    height: 1.6,
  );

  /// Baris terjemahan Rumi di bawah ayat Jawi.
  ///
  /// Sengaja lebih kecil dan berwarna lembut: ia membantu murid dan ibu bapa
  /// yang belum lancar Jawi, tanpa menenggelamkan ayat Jawi yang sebenar.
  static const TextStyle rumi = TextStyle(fontSize: 14, height: 1.4);

  /// Teks jawapan bertulis dalam tulisan Jawi.
  static const TextStyle jawiTaip = TextStyle(
    fontFamily: 'Jawi',
    fontSize: 26,
    height: 1.9,
  );

  /// Tajuk skrin — "Syabas!", "Kertas selesai!".
  static const TextStyle tajuk = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    height: 1.15,
  );

  /// Teks soalan dan butang utama.
  static const TextStyle besar = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.3,
  );

  /// Teks pilihan jawapan, tajuk kad utama.
  static const TextStyle sederhana = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  /// Teks biasa dan butang kecil.
  static const TextStyle biasa = TextStyle(fontSize: 16, height: 1.35);

  /// Baris meta di bawah tajuk.
  static const TextStyle kecil = TextStyle(fontSize: 14, height: 1.35);

  /// Label paling kecil — kiraan soalan, peratus, nota.
  static const TextStyle label = TextStyle(fontSize: 12.5, height: 1.3);

  /// Huruf dalam lencana pilihan jawapan (A, B, C, D) dan pilihan Jawi
  /// (ا, ب, ج, د). Lencana Jawi lebih besar kerana mata hurufnya lebih halus.
  static const TextStyle lencana = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    height: 1,
  );

  static const TextStyle lencanaJawi = TextStyle(
    fontFamily: 'Jawi',
    fontSize: 22,
    height: 1.4,
  );

  /// Huruf gred besar di dalam cop kertas percubaan.
  static const TextStyle gred = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w900,
    height: 1,
  );

  /// Huruf kecil bergaya cop pada kertas percubaan ("GRED", "UPKK ADAB").
  static const TextStyle cop = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.4,
    height: 1.25,
  );
}

/// Warna yang dikongsi antara skrin dan widget.
///
/// Warna tema subjek datang daripada bank soalan (`warna` pada setiap subjek).
/// Warna di sini ialah warna tetap app: maklum balas betul/salah, latar skrin
/// dan kad nota.
class Warna {
  Warna._();

  /// Warna utama app Ulangkaji UPKK — pink.
  ///
  /// Pink dipilih kerana ia lembut dan mesra kanak-kanak, sejajar dengan
  /// maskot bertudung pink, tetapi masih cukup gelap untuk kontras teks putih
  /// di atasnya.
  static const Color utama = Color(0xFFD81B60);

  /// Pink lebih cerah untuk hujung gradien dan sorotan.
  static const Color utamaMuda = Color(0xFFF06292);

  /// Pink sangat muda — kad kedua dan latar butang lembut.
  static const Color utamaLembut = Color(0xFFFCE4EC);

  /// Latar skrin utama — pink sangat muda supaya kad putih menonjol.
  static const Color latarSkrin = Color(0xFFFFF5F8);

  /// Maklum balas betul (hijau) dan salah (merah).
  static const Color betul = Color(0xFF2E7D32);
  static const Color salah = Color(0xFFE53935);
  static const Color latarBetul = Color(0xFFE8F5E9);
  static const Color latarSalah = Color(0xFFFFEBEE);

  /// Kad nota penerangan.
  static const Color latarNota = Color(0xFFFFF8E1);
  static const Color tepiNota = Color(0xFFFFB300);

  /// Dakwat pen merah — markah pada kertas percubaan ditanda seolah-olah guru
  /// menanda dengan pen merah, sama seperti kertas sekolah anak.
  static const Color dakwat = Color(0xFFD32F2F);

  /// Warna kepala surat kertas soalan (kelabu muda seperti kertas cetak).
  static const Color kepalaKertas = Color(0xFFF3F3F5);
  static const Color garisKertas = Color(0xFF9E9E9E);
}
