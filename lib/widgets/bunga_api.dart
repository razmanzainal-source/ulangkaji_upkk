import 'dart:math';

import 'package:flutter/material.dart';

import '../tema.dart';

/// Letupan bunga api sebagai raikan jawapan betul.
///
/// Kanak-kanak Tahun 5 perlu tahu **serta-merta** bahawa jawapannya betul.
/// Warna sahaja tidak cukup: warna boleh terlepas pandang pada skrin kecil,
/// dan murid yang sedang memandang papan jawapan tidak melihat butang yang
/// bertukar warna. Satu letupan pendek di tengah skrin sukar terlepas pandang,
/// dan ia berhenti sendiri supaya tidak mengganggu soalan seterusnya.
///
/// Widget ini **tidak** menyimpan keadaan sendiri selain animasi: ia dilukis
/// apabila ibu bapa meletakkannya dalam pokok widget, dan memanggil [onTamat]
/// selepas letupan habis supaya pemanggil boleh mengeluarkannya semula.
/// Dengan cara itu tidak ada pemasa yang tertinggal di belakang skrin.
class BungaApi extends StatefulWidget {
  const BungaApi({
    super.key,
    required this.onTamat,
    this.titik = 24,
    this.letupan = 3,
    this.warna = const [
      Warna.utama,
      Warna.utamaMuda,
      Color(0xFFFFC107),
      Color(0xFF4FC3F7),
      Color(0xFF81C784),
    ],
  });

  /// Dipanggil sekali selepas letupan habis.
  final VoidCallback onTamat;

  /// Bilangan zarah bagi setiap letupan.
  final int titik;

  /// Bilangan letupan serentak.
  final int letupan;

  final List<Color> warna;

  /// Berapa lama satu letupan mengambil masa.
  static const Duration tempoh = Duration(milliseconds: 1400);

  @override
  State<BungaApi> createState() => _BungaApiState();
}

class _BungaApiState extends State<BungaApi>
    with SingleTickerProviderStateMixin {
  late final AnimationController _kawalan;
  late final List<_Letupan> _senarai;

  @override
  void initState() {
    super.initState();
    _kawalan = AnimationController(vsync: this, duration: BungaApi.tempoh);
    _senarai = _binaLetupan();
    _kawalan.forward().whenComplete(() {
      if (mounted) widget.onTamat();
    });
  }

  List<_Letupan> _binaLetupan() {
    final rawak = Random();
    // Letupan diletak pada kedudukan berbeza supaya ia tidak bertindih dan
    // tidak menutup teks soalan di bahagian atas skrin.
    final kedudukan = <Offset>[
      const Offset(0.50, 0.34),
      const Offset(0.24, 0.47),
      const Offset(0.76, 0.45),
      const Offset(0.38, 0.62),
      const Offset(0.64, 0.25),
    ];

    return [
      for (var i = 0; i < widget.letupan; i++)
        _Letupan(
          pusat: kedudukan[i % kedudukan.length],
          // Setiap letupan bermula sedikit kemudian daripada yang sebelumnya
          // supaya kelihatan seperti bunga api berturut-turut, bukan satu bulatan.
          kelewatan: i * 0.14,
          zarah: [
            for (var j = 0; j < widget.titik; j++)
              _Zarah(
                sudut: (j / widget.titik) * 2 * pi + rawak.nextDouble() * 0.35,
                laju: 0.055 + rawak.nextDouble() * 0.075,
                saiz: 2.0 + rawak.nextDouble() * 3.2,
                warna: widget.warna[j % widget.warna.length],
              ),
          ],
        ),
    ];
  }

  @override
  void dispose() {
    _kawalan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _kawalan,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _PelukisBungaApi(
            letupan: _senarai,
            kemajuan: _kawalan.value,
          ),
        ),
      ),
    );
  }
}

/// Satu letupan: satu pusat, satu masa mula, dan zarah-zarahnya.
class _Letupan {
  const _Letupan({
    required this.pusat,
    required this.kelewatan,
    required this.zarah,
  });

  /// Kedudukan relatif (0–1) terhadap saiz kotak.
  final Offset pusat;

  /// Bila letupan ini bermula, dalam pecahan tempoh penuh.
  final double kelewatan;

  final List<_Zarah> zarah;
}

class _Zarah {
  const _Zarah({
    required this.sudut,
    required this.laju,
    required this.saiz,
    required this.warna,
  });

  final double sudut;
  final double laju;
  final double saiz;
  final Color warna;
}

class _PelukisBungaApi extends CustomPainter {
  _PelukisBungaApi({required this.letupan, required this.kemajuan});

  final List<_Letupan> letupan;
  final double kemajuan;

  @override
  void paint(Canvas canvas, Size saiz) {
    for (final l in letupan) {
      // Setiap letupan ada tempoh sendiri; yang lewat masih belum bermula.
      final t = ((kemajuan - l.kelewatan) / (1 - l.kelewatan)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final pusat = Offset(l.pusat.dx * saiz.width, l.pusat.dy * saiz.height);
      // Melambat pada hujung (bukan linear) supaya zarah kelihatan kehilangan
      // tenaga seperti bunga api sebenar.
      final jarak = Curves.easeOutCubic.transform(t);
      final pudar = (1 - Curves.easeInQuad.transform(t)).clamp(0.0, 1.0);
      if (pudar <= 0.01) continue;

      final cat = Paint()..style = PaintingStyle.fill;
      for (final z in l.zarah) {
        // Graviti sedikit: zarah jatuh perlahan selepas meletus.
        final jatuh = 0.10 * t * t;
        final kedudukan = pusat +
            Offset(cos(z.sudut) * z.laju * saiz.shortestSide * jarak,
                sin(z.sudut) * z.laju * saiz.shortestSide * jarak) +
            Offset(0, jatuh * saiz.height * 0.16);

        cat.color = z.warna.withValues(alpha: pudar);
        canvas.drawCircle(kedudukan, z.saiz * (0.5 + 0.5 * pudar), cat);
      }
    }
  }

  @override
  bool shouldRepaint(_PelukisBungaApi lama) => lama.kemajuan != kemajuan;
}
