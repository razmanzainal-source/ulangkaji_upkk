import 'package:flutter/material.dart';

import '../models/gred.dart';
import '../models/jawapan.dart';
import '../models/kertas.dart';
import '../tema.dart';

/// Kad keputusan yang boleh dikongsi sebagai gambar.
///
/// Kad ini **bukan** salinan skrin keputusan. Ia dilukis pada lebar tetap
/// (lihat [lebar]) supaya gambar yang dihasilkan sama pada setiap peranti:
/// telefon kecil tidak menghasilkan gambar yang sempit dan bersesak, dan
/// tablet tidak menghasilkan gambar yang penuh dengan ruang kosong.
///
/// Kad ini juga berdiri sendiri — ibu bapa yang menerima gambar di WhatsApp
/// tidak melihat app, jadi gambar mesti membawa nama app dan kredit pencipta
/// supaya penerima tahu dari mana keputusan itu datang dan siapa yang
/// menghasilkannya.
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

  /// Lebar tetap kad dalam piksel logik.
  final double lebar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: lebar,
      color: Warna.latarSkrin,
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEFDCE4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _kepala(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _pujian(peratus, nama),
                    textAlign: TextAlign.center,
                    style: Teks.tajuk.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 14),
                  _barMarkah(),
                  const SizedBox(height: 16),
                  Text(
                    'Pecahan markah',
                    style: Teks.label.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.black54,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final b in kertas.bahagian)
                    _PecahanBaris(
                      nama: b.nama,
                      diperoleh: kertas.markahBahagian(b.nama, jawapan),
                      penuh: b.markahTersedia == 0
                          ? b.markah
                          : b.markahTersedia,
                    ),
                ],
              ),
            ),
            _kaki(),
          ],
        ),
      ),
    );
  }

  /// Kepala kad: cop gred dan markah besar.
  Widget _kepala() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Warna.utama, Warna.utamaMuda],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(23)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Gambar maskot yang sama seperti dalam app. `Image.asset` biasa
              // dipakai dan bukan widget `Maskot` yang berdenyut: kad ini
              // ditangkap sebagai gambar, jadi ia mesti berhenti pada satu
              // bentuk yang sama setiap kali.
              Image.asset(
                'assets/gambar/maskot_upkk.png',
                width: 58,
                height: 58,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ULANGKAJI UPKK',
                      style: Teks.label.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      kertas.tajuk,
                      style: Teks.biasa.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$tarikh · Percubaan format UPKK',
                      style: Teks.label.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              _CopGred(gred: gred),
            ],
          ),
          const SizedBox(height: 14),
          // Markah, markah penuh dan peratus berada dalam satu baris. Bahagian
          // "/ 70 markah" dibalut `Flexible` + `FittedBox` supaya baris ini
          // tidak pernah melimpah — markah tiga angka dan peratus 100% masih
          // masuk walaupun kad ini hanya selebar 360.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$markah',
                style: Teks.gergasi.copyWith(
                  color: Colors.white,
                  fontSize: 40,
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 3),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      '/ $penuh markah',
                      maxLines: 1,
                      style: Teks.biasa.copyWith(color: Colors.white70),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '$peratus%',
                  style: Teks.gergasi.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _barMarkah() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: penuh <= 0 ? 0 : markah / penuh,
        minHeight: 12,
        backgroundColor: Warna.utamaLembut,
        valueColor: const AlwaysStoppedAnimation(Warna.utama),
      ),
    );
  }

  /// Kaki kad: nama app dan penciptanya.
  ///
  /// Gambar ini akan tersebar ke telefon orang yang tidak pernah memasang app
  /// ini. Kredit di sini ialah satu-satunya jalan penerima tahu dari mana ia
  /// datang.
  Widget _kaki() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: const BoxDecoration(
        color: Warna.utamaLembut,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(23)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ulang kaji KAFA ikut subjek, uji diri dan kertas percubaan UPKK.',
            style: Teks.label.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Razman Zainal · razman.zainal@gmail.com',
            style: Teks.label.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  /// Ayat pujian pada kad.
  ///
  /// Nama hanya disertakan apabila ia benar-benar ada — kalau tidak, ayat
  /// tergantung seperti "Cemerlang, !".
  static String _pujian(int peratus, String nama) {
    final sapaan = nama.trim().isEmpty ? '' : ', ${nama.trim()}';
    if (peratus >= 80) return 'Cemerlang$sapaan!';
    if (peratus >= 60) return 'Bagus$sapaan!';
    if (peratus >= 40) return 'Boleh lagi$sapaan!';
    return 'Jangan putus asa$sapaan!';
  }
}

/// Cop gred bergaya tanda guru — bulatan berputar sedikit.
class _CopGred extends StatelessWidget {
  const _CopGred({required this.gred});

  final Gred gred;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.12,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('GRED', style: Teks.cop.copyWith(color: Colors.white70)),
            Text(
              gred.huruf,
              style: Teks.gred.copyWith(color: Colors.white, fontSize: 26),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu baris pecahan markah bahagian pada kad perkongsian.
class _PecahanBaris extends StatelessWidget {
  const _PecahanBaris({
    required this.nama,
    required this.diperoleh,
    required this.penuh,
  });

  final String nama;
  final int diperoleh;
  final int penuh;

  @override
  Widget build(BuildContext context) {
    final nisbah = penuh <= 0 ? 0.0 : diperoleh / penuh;
    final warna = nisbah >= 0.8
        ? Warna.betul
        : nisbah >= 0.5
            ? Warna.tepiNota
            : Warna.salah;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Warna.utamaLembut,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              nama,
              style: Teks.sederhana.copyWith(color: Warna.utama, fontSize: 15),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: nisbah,
                minHeight: 9,
                backgroundColor: const Color(0xFFF0F0F0),
                valueColor: AlwaysStoppedAnimation(warna),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$diperoleh/$penuh',
            style: Teks.kecil.copyWith(
              fontWeight: FontWeight.w800,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }
}
