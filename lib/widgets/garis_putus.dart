import 'package:flutter/material.dart';

/// Garisan putus-putus gaya kertas peperiksaan.
///
/// Digunakan pada kad keputusan untuk memisahkan kepala kertas (nama, tarikh,
/// markah) daripada kandungan di bawahnya, sama seperti garisan pada kertas
/// soalan yang sebenar.
///
/// Ia dilukis dengan [CustomPaint] dan bukan aksara "----" kerana aksara
/// bergantung pada fon: pada sesetengah fon, sambungan aksara itu kelihatan
/// sebagai garisan penuh, dan pada fon lain ia terlalu jarang.
class GarisPutus extends StatelessWidget {
  const GarisPutus({
    super.key,
    this.warna = const Color(0xFFBDBDBD),
    this.ketebalan = 1.4,
  });

  final Color warna;
  final double ketebalan;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ketebalan,
      width: double.infinity,
      child: CustomPaint(
        painter: _CatGarisPutus(warna: warna, ketebalan: ketebalan),
      ),
    );
  }
}

class _CatGarisPutus extends CustomPainter {
  const _CatGarisPutus({required this.warna, required this.ketebalan});

  final Color warna;
  final double ketebalan;

  static const double _putus = 5;
  static const double _jurang = 4;

  @override
  void paint(Canvas kanvas, Size saiz) {
    final cat = Paint()
      ..color = warna
      ..strokeWidth = ketebalan
      ..strokeCap = StrokeCap.round;

    final tengah = saiz.height / 2;
    for (var x = 0.0; x < saiz.width; x += _putus + _jurang) {
      final hujung = (x + _putus).clamp(0.0, saiz.width);
      kanvas.drawLine(Offset(x, tengah), Offset(hujung, tengah), cat);
    }
  }

  @override
  bool shouldRepaint(_CatGarisPutus lama) =>
      lama.warna != warna || lama.ketebalan != ketebalan;
}
