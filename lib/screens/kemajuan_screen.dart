import 'package:flutter/material.dart';

import '../models/gred.dart';
import '../models/kertas.dart';
import '../services/bank_kertas.dart';
import '../services/kemajuan.dart';
import '../tarikh.dart';
import '../tema.dart';
import '../widgets/maskot.dart';
import 'rumah_screen.dart';

/// Tab "Kemajuan" — markah dan gred setiap subjek.
///
/// Semua rekod disimpan **di dalam telefon sahaja**. App ini tidak menghantar
/// apa-apa ke Internet dan tidak memerlukan akaun, jadi skrin ini ialah satunya
/// tempat keputusan murid berada.
class KemajuanScreen extends StatefulWidget {
  const KemajuanScreen({super.key});

  @override
  State<KemajuanScreen> createState() => _KemajuanScreenState();
}

class _KemajuanScreenState extends State<KemajuanScreen> {
  @override
  Widget build(BuildContext context) {
    final subjek = BankKertas.instance.subjek;
    // Hanya kertas percubaan — latih tubi dipisahkan supaya "purata markah"
    // tidak dicampur antara kertas 70 markah dan latihan 10 soalan.
    final rekod = Kemajuan.instance.rekodKertas;
    final jumlahPercubaan = rekod.length;
    final purata = rekod.isEmpty
        ? 0
        : (rekod.fold<int>(0, (j, r) => j + r.peratus) / rekod.length).round();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: KepalaUpik(
            tajuk: 'Kemajuan',
            sari: jumlahPercubaan == 0
                ? 'Belum ada percubaan. Mulakan dengan satu kertas — markah '
                    'pertama ialah titik tolak.'
                : 'Purata anda $purata%. Ulang kaji bahagian yang lemah '
                    'supaya gred naik.',
            mood: jumlahPercubaan == 0 ? MoodMaskot.fikir : MoodMaskot.gembira,
            kanak: Row(
              children: [
                CipStat(
                  ikon: Icons.assignment_turned_in_rounded,
                  teks: '$jumlahPercubaan percubaan',
                ),
                const SizedBox(width: 8),
                CipStat(
                  ikon: Icons.local_fire_department_rounded,
                  teks: '${Kemajuan.instance.rentetanHari} hari berturut',
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Mengikut subjek',
              style: Teks.sederhana.copyWith(color: Colors.black87),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList.separated(
            itemCount: subjek.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _KadSubjek(
              subjek: subjek[i],
              ringkasan: Kemajuan.instance.ringkasan(subjek[i].id),
            ),
          ),
        ),
        if (rekod.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Percubaan terkini',
                style: Teks.sederhana.copyWith(color: Colors.black87),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            sliver: SliverList.separated(
              itemCount: rekod.length > 12 ? 12 : rekod.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _BarisRekod(
                rekod: rekod[i],
                namaSubjek: _namaSubjek(rekod[i].subjekId),
              ),
            ),
          ),
        ] else
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  String _namaSubjek(String id) =>
      BankKertas.instance.subjekDaripada(id)?.nama ?? id;
}

/// Kad satu subjek dengan markah terbaik dan bilangan percubaan.
class _KadSubjek extends StatelessWidget {
  const _KadSubjek({required this.subjek, required this.ringkasan});

  final Subjek subjek;
  final RingkasanSubjek ringkasan;

  @override
  Widget build(BuildContext context) {
    final ada = ringkasan.adaRekod;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: subjek.warna.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: subjek.warna.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(subjek.ikon, style: Teks.gambar),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subjek.nama,
                  style: Teks.sederhana.copyWith(color: subjek.warna),
                ),
                const SizedBox(height: 4),
                if (!ada)
                  Text(
                    'Belum dicuba',
                    style: Teks.label.copyWith(color: Colors.black45),
                  )
                else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ringkasan.peratusTerbaik / 100,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF0F0F0),
                      valueColor: AlwaysStoppedAnimation(
                        ringkasan.gredTerbaik.warna,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Terbaik ${ringkasan.markahTerbaik}/70 • '
                    '${ringkasan.peratusTerbaik}% • '
                    '${ringkasan.percubaan} percubaan',
                    style: Teks.label.copyWith(color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (ada)
            _CopGredKecil(gred: ringkasan.gredTerbaik)
          else
            Icon(Icons.circle_outlined, color: Colors.grey.shade300, size: 34),
        ],
      ),
    );
  }
}

/// Cop huruf gred kecil.
class _CopGredKecil extends StatelessWidget {
  const _CopGredKecil({required this.gred});

  final Gred gred;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: gred.warna.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: gred.warna, width: 1.6),
      ),
      child: Text(
        gred.huruf,
        style: Teks.gergasi.copyWith(color: gred.warna, fontSize: 24),
      ),
    );
  }
}

/// Satu baris rekod percubaan.
class _BarisRekod extends StatelessWidget {
  const _BarisRekod({required this.rekod, required this.namaSubjek});

  final RekodPercubaan rekod;
  final String namaSubjek;

  @override
  Widget build(BuildContext context) {
    final gred = rekod.gred;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: gred.warna.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              gred.huruf,
              style: Teks.sederhana.copyWith(color: gred.warna),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaSubjek,
                  style: Teks.biasa.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${tarikhMelayu(rekod.tarikh)} • ${rekod.masaTeks}',
                  style: Teks.label.copyWith(color: Colors.black45),
                ),
              ],
            ),
          ),
          Text(
            '${rekod.markah}/${rekod.markahPenuh}',
            style: Teks.sederhana.copyWith(color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
