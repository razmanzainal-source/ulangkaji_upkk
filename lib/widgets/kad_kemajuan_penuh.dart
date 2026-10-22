import 'package:flutter/material.dart';

import '../models/gred.dart';
import '../models/kertas.dart';
import '../models/lencana.dart';
import '../services/bank_kertas.dart';
import '../services/kemajuan.dart';
import '../tema.dart';
import 'garis_putus.dart';

/// Kad kemajuan penuh — slip keputusan gabungan semua subjek.
///
/// Mengikut format slip peperiksaan UPKK rasmi: kepala (app, nama, tarikh),
/// jadual semua subjek dengan markah, peratus & gred, jumlah & purata,
/// kemudian kaki app.
class KadKemajuanPenuh extends StatelessWidget {
  const KadKemajuanPenuh({
    super.key,
    required this.nama,
    required this.tarikh,
    this.lebar = 360,
  });

  /// Nama anak.
  final String nama;

  /// Tarikh dalam Bahasa Melayu, contoh "19 Oktober 2026".
  final String tarikh;

  /// Lebar tetap kad dalam piksel logik.
  final double lebar;

  @override
  Widget build(BuildContext context) {
    final subjek = BankKertas.instance.subjek;
    final kemajuan = Kemajuan.instance;

    // Kumpul data setiap subjek
    final dataSubjek = <_DataSubjek>[];
    var totalMarkah = 0;
    var totalPenuh = 0;

    for (final s in subjek) {
      final ringkasan = kemajuan.ringkasan(s.id);
      if (ringkasan.adaRekod) {
        totalMarkah += ringkasan.markahTerbaik;
        totalPenuh += 70; // setiap kertas UPKK = 70 markah
        dataSubjek.add(
          _DataSubjek(
            subjek: s,
            markah: ringkasan.markahTerbaik,
            penuh: 70,
            peratus: ringkasan.peratusTerbaik,
            gred: ringkasan.gredTerbaik,
            percubaan: ringkasan.percubaan,
          ),
        );
      } else {
        dataSubjek.add(
          _DataSubjek(
            subjek: s,
            markah: 0,
            penuh: 70,
            peratus: 0,
            gred: Gred.d, // gred terendah untuk paparan; teks "Belum dicuba" akan ditunjukkan
            percubaan: 0,
          ),
        );
      }
    }

    final purata = totalPenuh > 0 ? ((totalMarkah / totalPenuh) * 100).round() : 0;
    final gredKeseluruhan = Gred.dariPeratus(purata);

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
            _jadualSubjek(dataSubjek),
            const SizedBox(height: 12),
            _barisLencana(),
            const SizedBox(height: 12),
            const GarisPutus(),
            const SizedBox(height: 12),
            _jumlahan(totalMarkah, totalPenuh, purata, gredKeseluruhan),
            const SizedBox(height: 12),
            const GarisPutus(),
            const SizedBox(height: 10),
            _kaki(),
          ],
        ),
      ),
    );

    return Material(type: MaterialType.transparency, child: kad);
  }

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
                'Slip Keputusan Keseluruhan',
                style: Teks.label.copyWith(
                  color: Colors.black.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Semua Subjek',
            style: Teks.label.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  /// Lencana yang diperoleh — supaya slip yang dikongsi menunjukkan
  /// pencapaian, bukan sahaja markah.
  ///
  /// Lencana **global** sahaja dipaparkan di sini. Lencana markah adalah
  /// satu bagi setiap subjek, jadi slip akan jadi sangat panjang tanpa
  /// menambah nilai — nama lencana global sudah cukup untuk menunjukkan
  /// pencapaian.
  Widget _barisLencana() {
    final ada = Kemajuan.instance.lencanaDiperoleh;
    final didapat = DaftarLencana.global
        .where((l) => ada.contains(l.id))
        .toList();
    if (didapat.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LENCANA (${didapat.length})',
          style: Teks.cop.copyWith(color: Warna.dakwat),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final l in didapat)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: l.warna.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: l.warna.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(l.ikon, size: 13, color: l.warna),
                    const SizedBox(width: 4),
                    Text(
                      l.tajuk,
                      style: Teks.cop.copyWith(
                        color: l.warna,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
          ],
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

  /// Jadual semua subjek dengan markah, peratus & gred.
  Widget _jadualSubjek(List<_DataSubjek> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keputusan Mengikut Subjek',
          style: Teks.label.copyWith(
            color: Warna.dakwat,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        // Header jadual
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: Warna.dakwat.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(
                  'Subjek',
                  style: Teks.label.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Warna.dakwat,
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  'Markah',
                  textAlign: TextAlign.center,
                  style: Teks.label.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Warna.dakwat,
                  ),
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  '%',
                  textAlign: TextAlign.center,
                  style: Teks.label.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Warna.dakwat,
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  'Gred',
                  textAlign: TextAlign.center,
                  style: Teks.label.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Warna.dakwat,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Baris setiap subjek
        for (var i = 0; i < data.length; i++)
          _barisSubjek(data[i], i == data.length - 1),
      ],
    );
  }

  Widget _barisSubjek(_DataSubjek d, bool terakhir) {
    final warnaSubjek = d.subjek.warna;
    final gred = d.gred;
    final adaRekod = d.percubaan > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: adaRekod
            ? gred.warna.withValues(alpha: 0.04)
            : Colors.grey.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: adaRekod
              ? gred.warna.withValues(alpha: 0.25)
              : Colors.grey.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Ikon subjek
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: warnaSubjek.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(d.subjek.ikon, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.subjek.nama,
                  style: Teks.label.copyWith(
                    fontWeight: FontWeight.w800,
                    color: adaRekod ? warnaSubjek : Colors.black38,
                  ),
                ),
                if (adaRekod)
                  Text(
                    '${d.percubaan} percubaan',
                    style: Teks.cop.copyWith(color: Colors.black45),
                  )
                else
                  Text(
                    'Belum dicuba',
                    style: Teks.cop.copyWith(color: Colors.black26),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              adaRekod ? '${d.markah}/${d.penuh}' : '—',
              textAlign: TextAlign.center,
              style: Teks.label.copyWith(
                fontWeight: FontWeight.w900,
                color: adaRekod ? Warna.dakwat : Colors.black26,
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              adaRekod ? '${d.peratus}%' : '—',
              textAlign: TextAlign.center,
              style: Teks.label.copyWith(
                fontWeight: FontWeight.w900,
                color: adaRekod ? gred.warna : Colors.black26,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Center(
              child: adaRekod
                  ? Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: gred.warna, width: 1.5),
                      ),
                      child: Text(
                        gred.huruf,
                        style: Teks.sederhana.copyWith(
                          color: gred.warna,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : Icon(Icons.circle_outlined, color: Colors.grey.shade300, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _jumlahan(int totalMarkah, int totalPenuh, int purata, Gred gred) {
    final warna = gred.warna;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JUMLAHAN KESeluruhAN',
          style: Teks.label.copyWith(
            color: Warna.dakwat,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('JUMLAH MARKAH', style: Teks.cop.copyWith(color: Warna.dakwat)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$totalMarkah',
                        style: Teks.gergasi.copyWith(
                          color: Warna.dakwat,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Text(
                        ' / $totalPenuh',
                        style: Teks.sederhana.copyWith(
                          color: Warna.dakwat.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _copGredKeseluruhan(gred),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _kotakInfo('Purata', '$purata%', warna),
            const SizedBox(width: 10),
            _kotakInfo('Gred Keseluruhan', gred.nama, warna),
          ],
        ),
      ],
    );
  }

  Widget _copGredKeseluruhan(Gred gred) {
    final warna = gred.warna;
    return Column(
      children: [
        Transform.rotate(
          angle: -0.06,
          child: Container(
            width: 76,
            height: 76,
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
                  Text('GRED', style: Teks.cop.copyWith(color: warna, fontSize: 10)),
                  Text(gred.huruf, style: Teks.gred.copyWith(color: warna, fontSize: 26)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _kotakInfo(String label, String nilai, Color warna) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: warna.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: warna.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Column(
            children: [
              Text(label, style: Teks.cop.copyWith(color: warna, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(nilai, style: Teks.sederhana.copyWith(color: warna, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      );

  Widget _kaki() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
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
                    'Ulang kaji KAFA ikut subjek, uji diri dan kertas percubaan UPKK.',
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

/// Data ringkas satu subjek untuk kad kemajuan penuh.
class _DataSubjek {
  const _DataSubjek({
    required this.subjek,
    required this.markah,
    required this.penuh,
    required this.peratus,
    required this.gred,
    required this.percubaan,
  });

  final Subjek subjek;
  final int markah;
  final int penuh;
  final int peratus;
  final Gred gred;
  final int percubaan;
}