import 'package:flutter/material.dart';

import '../models/gred.dart';
import '../models/jawapan.dart';
import '../models/kertas.dart';
import '../tema.dart';
import 'garis_putus.dart';

/// Kad keputusan yang boleh dikongsi sebagai gambar.
///
/// Kad ini **bukan** salinan skrin keputusan. Ia dilukis pada lebar tetap
/// (lihat [lebar]) supaya gambar yang dihasilkan sama pada setiap peranti:
/// telefon kecil tidak menghasilkan gambar yang sempit dan bersesak, dan
/// tablet tidak menghasilkan gambar yang penuh dengan ruang kosong.
///
/// Bentuknya mengikut muka depan kertas yang telah ditanda guru: kepala kertas
/// (nama dan tarikh), markah dan cop gred, jadual "Untuk Kegunaan Pemeriksa",
/// kemudian markah setiap soalan. Tiada hiasan tambahan — ibu bapa yang
/// menerima gambar di WhatsApp perlu membaca nombor, bukan menghiasnya.
///
/// Kad ini juga berdiri sendiri — penerima gambar tidak melihat app, jadi
/// gambar mesti membawa nama app dan kredit pencipta supaya penerima tahu dari
/// mana keputusan itu datang dan siapa yang menghasilkannya.
class KadKeputusan extends StatelessWidget {
  const KadKeputusan({
    super.key,
    required this.kertas,
    required this.jawapan,
    required this.markah,
    required this.penuh,
    required this.peratus,
    required this.gred,
    required this.nama,
    required this.tarikh,
    this.masa,
    this.lebar = 360,
  });

  final Kertas kertas;
  final Map<String, JawapanMurid> jawapan;

  final int markah;
  final int penuh;
  final int peratus;
  final Gred gred;

  /// Nama anak. Ia menjadikan kad ini milik **dia**, bukan kad kosong.
  final String nama;

  /// Tarikh dalam Bahasa Melayu, contohnya "19 Oktober 2026".
  final String tarikh;

  /// Masa menjawab dalam bentuk `5:28`, atau `null` jika tiada.
  ///
  /// Masa dipaparkan seperti pada kertas sebenar: ia memberi ibu bapa gambaran
  /// sama ada anak menjawab dengan tenang atau tergesa-gesa.
  final String? masa;

  /// Lebar tetap kad dalam piksel logik.
  final double lebar;

  @override
  Widget build(BuildContext context) {
    final soalan = kertas.semuaSoalan;
    var betul = 0;
    for (final s in soalan) {
      if (s.betulPenuh(jawapan[s.id])) betul++;
    }

    // Kad ini dipasang sebagai **adik-beradik** Scaffold (lihat
    // `KeputusanScreen._kadKongsi`) supaya ia boleh ditangkap di luar skrin.
    // Di luar Scaffold tiada induk Material, jadi setiap `Text` di sini
    // mewarisi `_errorTextStyle` MaterialApp: `TextDecoration.underline`
    // bergaya `double` berwarna `0xFFFFFF00`. Hiasan itu terbakar ke dalam
    // gambar yang dikongsi sebagai garis dua kuning di bawah setiap baris.
    // Material lutsinar memberi kad gaya teks yang sama seperti skrin biasa.
    final kad = Container(
      width: lebar,
      color: Warna.latarSkrin,
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black12, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kepala(),
            const SizedBox(height: 8),
            _barisMaklumat('Nama', nama.trim().isEmpty ? '—' : nama.trim()),
            _barisMaklumat('Tarikh', tarikh),
            const SizedBox(height: 12),
            const GarisPutus(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _kotakMarkah(betul, soalan.length - betul)),
                const SizedBox(width: 8),
                _copGred(),
              ],
            ),
            const SizedBox(height: 12),
            const GarisPutus(),
            const SizedBox(height: 12),
            _jadualBahagian(),
            const SizedBox(height: 12),
            const GarisPutus(),
            const SizedBox(height: 12),
            Text(
              'Markah setiap soalan',
              style: Teks.label.copyWith(
                color: Warna.dakwat,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < soalan.length; i++) _cip(soalan[i], i + 1),
              ],
            ),
            const SizedBox(height: 14),
            const GarisPutus(),
            const SizedBox(height: 10),
            _kaki(),
          ],
        ),
      ),
    );

    return Material(type: MaterialType.transparency, child: kad);
  }

  /// Kepala kad: nama app, tajuk kertas dan masa menjawab.
  Widget _kepala() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ULANGKAJI UPKK',
                style: Teks.biasa.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
              Text(
                kertas.tajuk,
                style: Teks.label.copyWith(
                  color: Colors.black.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (masa != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Masa $masa',
              style: Teks.label.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }

  Widget _barisMaklumat(String label, String nilai) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: nilai,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
      style: Teks.kecil.copyWith(color: Colors.black.withValues(alpha: 0.75)),
    ),
  );

  /// Markah penuh dan jumlah markah, ditulis seperti guru menanda kertas.
  Widget _kotakMarkah(int betul, int perluUlang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MARKAH', style: Teks.cop.copyWith(color: Warna.dakwat)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$markah',
              style: Teks.gergasi.copyWith(
                color: Warna.dakwat,
                fontStyle: FontStyle.italic,
              ),
            ),
            Text(
              ' / $penuh',
              style: Teks.sederhana.copyWith(
                color: Warna.dakwat.withValues(alpha: 0.8),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Text(
          '$peratus%',
          style: Teks.sederhana.copyWith(
            color: Warna.dakwat,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        _tandaPen(Icons.check_rounded, '$betul betul'),
        _tandaPen(Icons.close_rounded, '$perluUlang perlu diulang'),
      ],
    );
  }

  /// Tanda pen merah kecil, contohnya "✓ 2 betul".
  ///
  /// Ikon Material digunakan dan bukan aksara ✓/✗ supaya tandanya sama pada
  /// setiap peranti — aksara itu tiada dalam sesetengah fon sistem. Teksnya
  /// dibalut `Flexible` supaya ia tidak pernah melimpah keluar kad pada skrin
  /// sempit atau apabila saiz fon sistem dibesarkan.
  Widget _tandaPen(IconData ikon, String teks) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ikon, size: 16, color: Warna.dakwat),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            teks,
            style: Teks.label.copyWith(
              color: Warna.dakwat.withValues(alpha: 0.9),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  /// Jadual markah setiap bahagian, seperti ruang "Untuk Kegunaan Pemeriksa"
  /// pada muka depan kertas UPKK.
  ///
  /// Nombor soalan dikira mengikut turutan dalam kertas (1 hingga N merentas
  /// bahagian), sama seperti kertas cetak — bukan nombor dalam bahagian.
  Widget _jadualBahagian() {
    final baris =
        <({String label, int mula, int tamat, int markah, int penuh})>[];
    var mula = 1;
    for (final b in kertas.bahagian) {
      if (b.soalan.isEmpty) continue;
      final tamat = mula + b.soalan.length - 1;
      baris.add((
        label: b.nama,
        mula: mula,
        tamat: tamat,
        markah: kertas.markahBahagian(b.nama, jawapan),
        penuh: b.markahTersedia == 0 ? b.markah : b.markahTersedia,
      ));
      mula = tamat + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Untuk Kegunaan Pemeriksa',
          style: Teks.label.copyWith(
            color: Warna.dakwat,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        for (final b in baris)
          Padding(
            key: ValueKey('bahagian-${b.label}'),
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 78,
                  child: Text(
                    'Bahagian ${b.label}',
                    style: Teks.label.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Expanded(
                  child: Text(
                    b.mula == b.tamat
                        ? 'Soalan ${b.mula}'
                        : 'Soalan ${b.mula}–${b.tamat}',
                    style: Teks.label.copyWith(
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Text(
                  '${b.markah}/${b.penuh}',
                  style: Teks.label.copyWith(
                    color: Warna.dakwat,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Cop gred di penjuru kertas, sedikit senget seperti cop sebenar.
  Widget _copGred() {
    final warna = gred.warna;
    return Column(
      children: [
        Transform.rotate(
          angle: -0.06,
          child: Container(
            width: 88,
            height: 88,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: warna, width: 3),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: warna.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('GRED', style: Teks.cop.copyWith(color: warna)),
                  Text(gred.huruf, style: Teks.gred.copyWith(color: warna)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 108,
          child: Text(
            gred.nama,
            textAlign: TextAlign.center,
            style: Teks.label.copyWith(
              color: warna,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  /// Satu petak markah dalam senarai "Markah setiap soalan".
  ///
  /// Soalan yang boleh mendapat markah separa (jawapan bertulis, padanan,
  /// susunan) memaparkan pecahan seperti `3/5`; soalan satu markah hanya
  /// betul atau salah, jadi tanda ✓/✗ lebih mudah dibaca daripada `1/1`.
  Widget _cip(SoalanKertas s, int nombor) {
    final pecahan = s.markahBolehDapat > 1
        ? '${s.markahDiperoleh(jawapan[s.id])}/${s.markahBolehDapat}'
        : null;

    return Container(
      key: ValueKey('cip-$nombor'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Warna.dakwat.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Warna.dakwat.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$nombor',
            style: Teks.label.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 5),
          if (pecahan != null)
            Text(
              pecahan,
              style: Teks.label.copyWith(
                color: Warna.dakwat,
                fontWeight: FontWeight.w900,
              ),
            )
          else
            Icon(
              s.betulPenuh(jawapan[s.id])
                  ? Icons.check_rounded
                  : Icons.close_rounded,
              size: 16,
              color: Warna.dakwat,
            ),
        ],
      ),
    );
  }

  /// Kaki kad: nama app, maskot dan penciptanya.
  ///
  /// Gambar ini akan tersebar ke telefon orang yang tidak pernah memasang app
  /// ini. Kredit di sini ialah satu-satunya jalan penerima tahu dari mana ia
  /// datang.
  Widget _kaki() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Gambar maskot yang sama seperti dalam app. `Image.asset` biasa
            // dipakai dan bukan widget `Maskot` yang berdenyut: kad ini
            // ditangkap sebagai gambar, jadi ia mesti berhenti pada satu
            // bentuk yang sama setiap kali.
            Image.asset(
              'assets/gambar/maskot_upkk.png',
              width: 34,
              height: 34,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ulangkaji UPKK Bersama Raz',
                    style: Teks.kecil.copyWith(
                      color: Warna.utama,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Ulang kaji KAFA ikut subjek, uji diri dan kertas '
                    'percubaan UPKK.',
                    style: Teks.label.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '© Razman Zainal · razman.zainal@gmail.com',
          style: Teks.label.copyWith(
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}
