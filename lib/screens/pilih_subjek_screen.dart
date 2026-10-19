import 'package:flutter/material.dart';

import '../models/kertas.dart';
import '../services/bank_kertas.dart';
import '../services/jana_kertas.dart';
import '../services/kemajuan.dart';
import '../services/sapaan.dart';
import '../services/tetapan.dart';
import '../tema.dart';
import '../widgets/dialog_nama.dart';
import 'kertas_screen.dart';
import 'rumah_screen.dart';

/// Tab "Percubaan" — pilih subjek untuk dijawab.
///
/// Setiap kad subjek menunjukkan format rasmi kertas itu (bahagian dan markah),
/// bilangan soalan dalam bank, dan markah terbaik murid jika pernah menjawab.
///
/// Skrin ini juga tempat app **menyapa** murid: kali pertama dibuka ia bertanya
/// nama (nama itu dipaparkan di kepala skrin dan pada kad keputusan), dan
/// sapaan pembuka dimainkan. Sapaan diletakkan di sini dan bukan di skrin muat
/// turun kerana ia sepatutnya berlaku apabila murid sudah melihat app, bukan
/// semasa logo masih berputar.
class PilihSubjekScreen extends StatefulWidget {
  const PilihSubjekScreen({super.key});

  @override
  State<PilihSubjekScreen> createState() => _PilihSubjekScreenState();
}

class _PilihSubjekScreenState extends State<PilihSubjekScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sambut());
  }

  /// Tanya nama (kali pertama) dan mainkan sapaan pembuka.
  Future<void> _sambut() async {
    if (!mounted) return;

    if (!Tetapan.instance.adaNama) {
      final nama = await tanyaNama(context);
      if (!mounted) return;
      if (nama != null && nama.isNotEmpty) {
        await Tetapan.instance.tetapkanNama(nama);
        if (mounted) setState(() {});
      }
    }

    // Sapaan tidak lagi menyebut nama, jadi ia dimainkan sama sahaja — sama ada
    // murid menaip namanya, melangkaunya, atau sudah menetapkannya dahulu.
    await Sapaan.instance.mainkan();
  }

  @override
  Widget build(BuildContext context) {
    final subjek = BankKertas.instance.subjek;
    final nama = Tetapan.instance.namaAnak.trim();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: KepalaRaz(
            tajuk: nama.isEmpty ? 'Ulangkaji UPKK' : 'Assalamualaikum, $nama!',
            sari: 'Jom belajar KAFA bersama Raz — 6 subjek bertulis, '
                '70 markah, 1 jam 15 minit, mengikut format UPKK sebenar.',
            kanak: Row(
              children: [
                CipStat(
                  ikon: Icons.library_books_rounded,
                  teks: '${subjek.length} subjek',
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
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          sliver: SliverList.separated(
            itemCount: subjek.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (_, i) => _KadSubjek(
              subjek: subjek[i],
              onMula: () => _mulaKertas(subjek[i]),
              onLatihTubi: () => _mulaLatihTubi(subjek[i]),
            ),
          ),
        ),
        if (subjek.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Bank soalan tidak dapat dibaca.\nCuba tutup dan buka semula app.',
                  style: Teks.biasa,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _mulaKertas(Subjek subjek) {
    final bank = BankKertas.instance.bank(subjek.id);
    if (bank.isEmpty) {
      _maklum('Bank soalan ${subjek.nama} belum tersedia.');
      return;
    }
    final kertas = JanaKertas.percubaan(
      subjek: subjek,
      bank: bank,
      giliran: Kemajuan.instance.giliran(subjek.id),
    );
    if (kertas.bilanganSoalan == 0) {
      _maklum('Bank soalan ${subjek.nama} belum cukup untuk membina kertas.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => KertasScreen(kertas: kertas)),
    );
  }

  void _mulaLatihTubi(Subjek subjek) {
    final bank = BankKertas.instance.bank(subjek.id);
    if (bank.isEmpty) {
      _maklum('Bank soalan ${subjek.nama} belum tersedia.');
      return;
    }
    final lemah = {
      for (final s in bank)
        if (Kemajuan.instance.perluUlang(s.id)) s.id,
    };
    final kertas = JanaKertas.latihTubi(
      subjek: subjek,
      bank: bank,
      giliran: Kemajuan.instance.giliran(subjek.id),
      bilangan: 10,
      utamakan: lemah,
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => KertasScreen(kertas: kertas)),
    );
  }

  void _maklum(String mesej) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesej), behavior: SnackBarBehavior.floating),
    );
  }
}

/// Kad satu subjek pada tab Percubaan.
class _KadSubjek extends StatelessWidget {
  const _KadSubjek({
    required this.subjek,
    required this.onMula,
    required this.onLatihTubi,
  });

  final Subjek subjek;
  final VoidCallback onMula;
  final VoidCallback onLatihTubi;

  @override
  Widget build(BuildContext context) {
    final bilangan = BankKertas.instance.bilanganSoalan(subjek.id);
    final terbaik = markahTerbaik(subjek);
    final lengkap = JanaKertas.lengkap(subjek, BankKertas.instance.bank(subjek.id));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: subjek.warna.withValues(alpha: 0.22)),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: subjek.warna.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
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
                        style: Teks.besar.copyWith(color: subjek.warna),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _Label(kecil: subjek.kod),
                          const SizedBox(width: 8),
                          Text(
                            '${subjek.markahPenuh} markah • ${FormatUpkk.masaTeks}',
                            style: Teks.label.copyWith(color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _JalurBahagian(subjek: subjek),
                      const SizedBox(height: 8),
                      Text(
                        terbaik == null
                            ? '$bilangan soalan dalam bank'
                            : 'Terbaik: $terbaik',
                        style: Teks.label.copyWith(
                          color: terbaik == null ? Colors.black54 : Warna.betul,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!lengkap) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Bank belum penuh: ${JanaKertas.bahagianKurang(subjek, BankKertas.instance.bank(subjek.id)).join(', ')}',
                          style: Teks.label.copyWith(color: Warna.salah),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onLatihTubi,
                  icon: const Icon(Icons.bolt_rounded, size: 19),
                  label: const Text('Latih tubi', style: Teks.biasa),
                  style: TextButton.styleFrom(
                    foregroundColor: subjek.warna,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              Container(width: 1, height: 26, color: const Color(0xFFEEEEEE)),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onMula,
                  icon: const Icon(Icons.play_arrow_rounded, size: 21),
                  label: const Text(
                    'Mula kertas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: subjek.warna,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Jalur kecil yang menunjukkan pembahagian markah setiap bahagian.
class _JalurBahagian extends StatelessWidget {
  const _JalurBahagian({required this.subjek});

  final Subjek subjek;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            for (final b in subjek.bahagian)
              Expanded(
                flex: b.markah,
                child: Container(
                  margin: const EdgeInsets.only(right: 2),
                  color: subjek.warna.withValues(
                    alpha: 0.35 + 0.13 * subjek.bahagian.indexOf(b),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.kecil});

  final String kecil;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        kecil,
        style: Teks.label.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
