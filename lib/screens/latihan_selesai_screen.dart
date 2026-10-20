import 'dart:async';

import 'package:flutter/material.dart';

import '../models/jawapan.dart';
import '../models/kertas.dart';
import '../services/suara.dart';
import '../services/tetapan.dart';
import '../tarikh.dart';
import '../tema.dart';
import '../widgets/bunga_api.dart';
import '../widgets/maskot.dart';

/// Skrin penutup **latih tubi**.
///
/// Skrin ini sengaja berbeza daripada [KeputusanScreen] dalam tiga perkara,
/// dan ketiga-tiganya adalah niat, bukan kekurangan:
///
///   * **Tiada markah, peratus atau gred.** Latih tubi bukan peperiksaan, jadi
///     menandanya seperti kertas percubaan menjadikan latihan terasa seperti
///     ujian — murid berhenti mencuba dan mula takut salah.
///   * **Tiada cop gred atau kad perkongsian.** Tiada apa yang perlu
///     dibanggakan kepada ibu bapa daripada latihan sepuluh soalan; yang
///     dikongsi ialah keputusan kertas percubaan.
///   * **Tiada senarai markah setiap soalan.** Yang tinggal hanyalah satu
///     ayat ringkas: berapa soalan betul, dan soalan mana yang patut diulang.
///
/// Murid tetap mendengar penutup yang menyeronokkan ([Suara.kunciLatihanSelesai])
/// dan bunga api — latihan yang tamat tanpa sebarang sambutan terasa seperti
/// latihan yang tidak dihiraukan.
class LatihanSelesaiScreen extends StatefulWidget {
  const LatihanSelesaiScreen({
    super.key,
    required this.kertas,
    required this.jawapan,
    this.saat,
  });

  final Kertas kertas;
  final Map<String, JawapanMurid> jawapan;

  /// Masa menjawab, dalam saat. `null` bermakna masa tidak diketahui.
  final int? saat;

  @override
  State<LatihanSelesaiScreen> createState() => _LatihanSelesaiScreenState();
}

class _LatihanSelesaiScreenState extends State<LatihanSelesaiScreen> {
  int _letupan = 0;

  List<SoalanKertas> get _soalan => widget.kertas.semuaSoalan;

  int get _betul => _soalan
      .where((s) => s.betulPenuh(widget.jawapan[s.id]))
      .length;

  /// Soalan yang belum betul sepenuhnya — termasuk yang belum dijawab.
  List<SoalanKertas> get _perluUlang =>
      _soalan.where((s) => !s.betulPenuh(widget.jawapan[s.id])).toList();

  @override
  void initState() {
    super.initState();
    // Bunyi selepas bingkai pertama, sama seperti skrin keputusan: skrin yang
    // belum wujud tidak boleh memainkan apa-apa.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _letupan = 1);
      unawaited(_sambut());
    });
  }

  /// Nada ceria dahulu, ayat kemudian — dua bunyi serentak menjadikan ayat
  /// itu kabur (lihat [Suara.mainkanKesanSelesai]).
  Future<void> _sambut() async {
    await Suara.instance.mainkanKesanSelesai(Suara.kesanHebat);
    await Suara.instance.sebutKunci(
      Suara.kunciLatihanSelesai,
      sandaran: Suara.teksLatihanSelesai,
    );
  }

  String get _masaTeks {
    final saat = widget.saat;
    if (saat == null || saat < 0) return '';
    return masaTeks(saat);
  }

  @override
  Widget build(BuildContext context) {
    final jumlah = _soalan.length;
    final nama = Tetapan.instance.namaAnak.trim();
    final semuaBetul = jumlah > 0 && _betul == jumlah;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Warna.latarSkrin,
          appBar: AppBar(
            backgroundColor: Warna.utama,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text('Latihan selesai', style: Teks.sederhana),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _KadSelesai(
                betul: _betul,
                jumlah: jumlah,
                nama: nama,
                semuaBetul: semuaBetul,
                masa: _masaTeks,
              ),
              const SizedBox(height: 16),
              if (_perluUlang.isNotEmpty)
                _KadUlang(soalan: _perluUlang)
              else
                const _KadSemuaBetul(),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Kembali', style: Teks.besar),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: Warna.utama,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Latihan ini tidak mengubah markah percubaan anda. '
                'Markah hanya dikira semasa menjawab kertas percubaan.',
                textAlign: TextAlign.center,
                style: Teks.label.copyWith(
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
        if (_letupan > 0)
          Positioned.fill(
            child: BungaApi(
              key: ValueKey(_letupan),
              letupan: semuaBetul ? 5 : 3,
              onTamat: () {
                if (mounted) setState(() => _letupan = 0);
              },
            ),
          ),
      ],
    );
  }
}

/// Kad utama: syabas, bilangan soalan betul, dan masa menjawab.
class _KadSelesai extends StatelessWidget {
  const _KadSelesai({
    required this.betul,
    required this.jumlah,
    required this.nama,
    required this.semuaBetul,
    required this.masa,
  });

  final int betul;
  final int jumlah;
  final String nama;
  final bool semuaBetul;
  final String masa;

  @override
  Widget build(BuildContext context) {
    final sapaan = nama.isEmpty ? '' : ', $nama';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Warna.utama, Warna.utamaMuda],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33D81B60),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Maskot(
            saiz: 92,
            mood: semuaBetul ? MoodMaskot.hebat : MoodMaskot.gembira,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Syabas$sapaan!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                // Bilangan soalan betul — **bukan** markah, peratus atau gred.
                Text(
                  semuaBetul
                      ? 'Semua $jumlah soalan betul!'
                      : '$betul daripada $jumlah soalan betul',
                  style: Teks.biasa.copyWith(color: Colors.white),
                ),
                if (masa.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Masa menjawab $masa',
                    style: Teks.label.copyWith(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Senarai nombor soalan yang patut dicuba semula.
class _KadUlang extends StatelessWidget {
  const _KadUlang({required this.soalan});

  final List<SoalanKertas> soalan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Soalan untuk diulang', style: Teks.sederhana),
          const SizedBox(height: 6),
          Text(
            'Cuba lagi soalan ini pada latih tubi seterusnya.',
            style: Teks.label.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in soalan)
                Container(
                  width: 44,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Warna.utamaLembut,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Warna.utamaMuda, width: 1.4),
                  ),
                  child: Text(
                    '${s.nombor}',
                    style: Teks.biasa.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Warna.utama,
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

/// Kad ganti apabila semua soalan betul.
class _KadSemuaBetul extends StatelessWidget {
  const _KadSemuaBetul();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Warna.latarBetul,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Warna.betul.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Warna.betul),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tiada soalan yang perlu diulang. Teruskan ke kertas '
              'percubaan!',
              style: Teks.biasa.copyWith(color: Warna.betul),
            ),
          ),
        ],
      ),
    );
  }
}
