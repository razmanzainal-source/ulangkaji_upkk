import 'package:flutter/material.dart';

import '../models/gred.dart';
import '../models/kertas.dart';
import '../models/lencana.dart';
import '../services/bank_kertas.dart';
import '../services/kemajuan.dart';
import '../services/kongsi.dart';
import '../services/tetapan.dart';
import '../tarikh.dart';
import '../tema.dart';
import '../widgets/kad_kemajuan_penuh.dart';
import '../widgets/kad_lencana.dart';
import '../widgets/lencana_widget.dart';
import '../widgets/maskot.dart';
import 'kongsi_screen.dart';
import 'laporan_screen.dart';
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
  /// Kunci kad perkongsian yang dilukis di luar skrin.
  final GlobalKey _kunciKongsi = GlobalKey();

  /// Kunci kad lencana yang dilukis di luar skrin.
  final GlobalKey _kunciLencana = GlobalKey();

  /// Benar semasa gambar kad disediakan.
  bool _menyediakanKongsi = false;

  /// Benar semasa kad lencana sedang disediakan.
  bool _menyediakanLencana = false;

  /// Menyediakan gambar kad kemajuan penuh, kemudian membuka skrin perkongsian.
  Future<void> _kongsiKemajuan() async {
    if (_menyediakanKongsi) return;
    setState(() => _menyediakanKongsi = true);

    // Satu bingkai diberi supaya kad perkongsian dilukis dahulu — gambar
    // hanya boleh ditangkap selepas kad benar-benar dilukis.
    await WidgetsBinding.instance.endOfFrame;
    final imej = await Kongsi.tangkapImej(_kunciKongsi);

    if (!mounted) return;
    setState(() => _menyediakanKongsi = false);

    if (imej == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gambar keputusan tidak dapat disediakan. Cuba lagi.'),
        ),
      );
      return;
    }

    final nama = Tetapan.instance.namaAnak.trim();
    final tarikh = tarikhMelayu(DateTime.now());
    final totalPenuh = BankKertas.instance.subjek.length * 70;
    var totalMarkah = 0;
    for (final s in BankKertas.instance.subjek) {
      totalMarkah += Kemajuan.instance.ringkasan(s.id).markahTerbaik;
    }
    final purata = totalPenuh > 0 ? ((totalMarkah / totalPenuh) * 100).round() : 0;
    final gred = Gred.dariPeratus(purata);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KongsiScreen(
          imej: imej,
          teks: 'Slip keputusan kesemuhaan subjek UPKK untuk $nama pada $tarikh. '
              'Jumlah: $totalMarkah/$totalPenuh ($purata%), Gred ${gred.huruf} (${gred.nama}).',
          namaFail: 'keputusan-upkk-kemajuan-penuh.png',
          namaSimpan: 'keputusan_upkk_kemajuan_penuh',
        ),
      ),
    );
  }

  /// Sediakan gambar koleksi lencana, kemudian buka skrin perkongsian.
  ///
  /// Kad lencana berbeza daripada slip markah: ia menunjukkan **pencapaian**,
  /// jadi murid yang belum mendapat gred A masih boleh menunjukkan apa yang
  /// dia kumpulkan.
  Future<void> _kongsiLencana() async {
    if (_menyediakanLencana) return;
    setState(() => _menyediakanLencana = true);

    // Satu bingkai diberi supaya kad dilukis dahulu — gambar hanya boleh
    // ditangkap selepas kad benar-benar dilukis.
    await WidgetsBinding.instance.endOfFrame;
    final imej = await Kongsi.tangkapImej(_kunciLencana);

    if (!mounted) return;
    setState(() => _menyediakanLencana = false);

    if (imej == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gambar lencana tidak dapat disediakan. Cuba lagi.'),
        ),
      );
      return;
    }

    final nama = Tetapan.instance.namaAnak.trim();
    final tarikh = tarikhMelayu(DateTime.now());
    final jumlah = Kemajuan.instance.lencanaDiperoleh.length;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KongsiScreen(
          imej: imej,
          teks: 'Koleksi lencana Ulangkaji UPKK untuk $nama pada $tarikh. '
              '$jumlah lencana diperoleh.',
          namaFail: 'lencana-upkk.png',
          namaSimpan: 'lencana_upkk',
          tajuk: 'Kongsi lencana',
        ),
      ),
    );
  }

  /// Kad lencana yang dilukis di luar kawasan yang kelihatan.
  Widget _kadLencana() {
    return KadLencana(
      nama: Tetapan.instance.namaAnak,
      tarikh: tarikhMelayu(DateTime.now()),
      subjek: BankKertas.instance.subjek,
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjek = BankKertas.instance.subjek;
    final rekod = Kemajuan.instance.rekodKertas;
    final jumlahPercubaan = rekod.length;
    final purata = rekod.isEmpty
        ? 0
        : (rekod.fold<int>(0, (j, r) => j + r.peratus) / rekod.length).round();

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: KepalaRaz(
                tajuk: 'Kemajuan',
                sari: jumlahPercubaan == 0
                    ? 'Belum ada percubaan. Mulakan dengan satu kertas — markah '
                        'pertama ialah titik tolak.'
                    : 'Purata anda $purata%. Ulang kaji bahagian yang lemah '
                        'supaya gred naik.',
                mood: jumlahPercubaan == 0 ? MoodMaskot.fikir : MoodMaskot.gembira,
                kanak: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    CipStat(
                      ikon: Icons.assignment_turned_in_rounded,
                      teks: '$jumlahPercubaan percubaan',
                    ),
                    CipStat(
                      ikon: Icons.local_fire_department_rounded,
                      teks: '${Kemajuan.instance.rentetanHari} hari berturut',
                    ),
                    CipStat(
                      ikon: Icons.workspace_premium_rounded,
                      teks: '${Kemajuan.instance.lencanaDiperoleh.length} lencana',
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const ValueKey('buka-laporan'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LaporanScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 19),
                    label: const Text('Laporan Ibu Bapa', style: Teks.biasa),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Warna.utama,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(
                        color: Warna.utama.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverToBoxAdapter(
                child: _KadRekod(kemajuan: Kemajuan.instance),
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

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Pencapaian',
                  style: Teks.sederhana.copyWith(color: Colors.black87),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverToBoxAdapter(
                child: _KoleksiLencana(
                  subjek: BankKertas.instance.subjek,
                ),
              ),
            ),
            if (rekod.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: _butangKongsi(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: _butangKongsiLencana(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
        ),
        // Kad perkongsian di luar skrin
        if (_menyediakanKongsi)
          Positioned(
            left: -4000,
            top: 0,
            width: 360,
            child: RepaintBoundary(
              key: _kunciKongsi,
              child: KadKemajuanPenuh(
                nama: Tetapan.instance.namaAnak,
                tarikh: tarikhMelayu(DateTime.now()),
              ),
            ),
          ),
        // Kad lencana di luar skrin — dilukis hanya semasa gambar
        // sedang disediakan.
        if (_menyediakanLencana)
          Positioned(
            left: -4000,
            top: 0,
            width: 360,
            child: RepaintBoundary(
              key: _kunciLencana,
              child: _kadLencana(),
            ),
          ),
      ],
    );
  }

  /// Butang kongsi penuh — gaya sama seperti butang pada skrin Keputusan.
  ///
  /// Ia diletak **atas** senarai "Percubaan terkini" supaya ibu bapa jumpa
  /// dengan mudah: butang yang penuh dan berwarna lebih menonjol berbanding
  /// butang kecil di dalam baris tajuk.
  Widget _butangKongsi() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              backgroundColor: Warna.utama,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: _menyediakanKongsi ? null : _kongsiKemajuan,
            icon: _menyediakanKongsi
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.share_rounded),
            label: Text(
              _menyediakanKongsi
                  ? 'Menyediakan gambar...'
                  : 'Kongsi Keputusan',
              style: Teks.besar,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hantar slip keputusan semua subjek kepada ibu bapa atau guru melalui '
          'WhatsApp, Facebook, Instagram atau Threads.',
          textAlign: TextAlign.center,
          style: Teks.label.copyWith(
            color: Colors.black.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
  /// Butang kongsi koleksi lencana.
  ///
  /// Berbeza daripada butang "Kongsi Keputusan": butang ini menunjuk
  /// **pencapaian** — lencana yang dikumpulkan — bukan markah.
  Widget _butangKongsiLencana() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: Warna.utama.withValues(alpha: 0.12),
          foregroundColor: Warna.utama,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: _menyediakanLencana ? null : _kongsiLencana,
        icon: _menyediakanLencana
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: Warna.utama,
                ),
              )
            : const Icon(Icons.workspace_premium_rounded),
        label: Text(
          _menyediakanLencana
              ? 'Menyediakan gambar...'
              : 'Kongsi Koleksi Lencana',
          style: Teks.biasa.copyWith(
            color: Warna.utama,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
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

  /// Lencana seterusnya yang perlu dicapai dalam subjek ini.
  ///
  /// `null` apabila keempat-empat lencana sudah diperoleh. Lencana
  /// yang hilang tidak diambil semula — ia kekal.
  TahapLencana? get _seterusnya {
    final peratus = ringkasan.peratusTerbaik;
    for (final t in TahapLencana.values) {
      if (!t.cukup(peratus)) return t;
    }
    return null;
  }

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
                  const SizedBox(height: 8),
                  BarisLencanaMarkah(
                    subjekId: subjek.id,
                    namaSubjek: subjek.nama,
                    ukuran: 28,
                  ),
                  if (_seterusnya != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Seterusnya: ${_seterusnya!.tajuk} (${_seterusnya!.peratus}%)',
                      style: Teks.label.copyWith(
                        color: Colors.black45,
                      ),
                    ),
                  ],
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

/// Kad rekod — angka yang membesar dan strip tujuh hari.
///
/// Rekod ini sengaja **tidak pernah hilang**. Murid yang melihat
/// "24 jawapan betul berturut-turut" tahu usahanya dikira, walaupun hari ini
/// dia tidak mendapat apa-apa yang baharu.
class _KadRekod extends StatelessWidget {
  const _KadRekod({required this.kemajuan});

  final Kemajuan kemajuan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Warna.utama.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, size: 18, color: Warna.utama),
              const SizedBox(width: 6),
              Text(
                'Rekod',
                style: Teks.sederhana.copyWith(color: Warna.utama),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Grid 2 x 2 — lebar setiap petak dikira daripada ruang yang
          // **benar-benar** ada, bukan daripada saiz skrin. Pada iPad (atau
          // skrin lebar lain) cara lama menggunakan lebar skrin dan menyemak
          // dua petak ke satu baris, lalu ruang kanan kekal kosong.
          LayoutBuilder(
            builder: (context, ruang) {
              final lebar = (ruang.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _PetakRekod(
                    lebar: lebar,
                    ikon: Icons.local_fire_department_rounded,
                    warna: const Color(0xFFFF7043),
                    nilai: '${kemajuan.rentetanTerpanjang}',
                    label: 'betul berturut',
                  ),
                  _PetakRekod(
                    lebar: lebar,
                    ikon: Icons.check_circle_rounded,
                    warna: const Color(0xFF2E7D32),
                    nilai: '${kemajuan.jumlahBetul}',
                    label: 'jawapan betul',
                  ),
                  _PetakRekod(
                    lebar: lebar,
                    ikon: Icons.emoji_events_rounded,
                    warna: const Color(0xFFD4A017),
                    nilai: '${kemajuan.kertasSempurna}',
                    label: 'kertas sempurna',
                  ),
                  _PetakRekod(
                    lebar: lebar,
                    ikon: Icons.calendar_month_rounded,
                    warna: Warna.utama,
                    nilai: '${kemajuan.rentetanHari}',
                    label: 'hari berturut',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _StripTujuhHari(kemajuan: kemajuan),
        ],
      ),
    );
  }
}

/// Satu angka dalam kad rekod.
class _PetakRekod extends StatelessWidget {
  const _PetakRekod({
    required this.lebar,
    required this.ikon,
    required this.warna,
    required this.nilai,
    required this.label,
  });

  /// Lebar petak — dikira oleh `LayoutBuilder` daripada ruang sebenar.
  final double lebar;

  final IconData ikon;
  final Color warna;
  final String nilai;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: lebar,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(ikon, size: 18, color: warna),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                nilai,
                style: Teks.biasa.copyWith(
                  color: warna,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: Teks.label.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tujuh titik — hari-hari murid belajar, bermula dari hari ini.
class _StripTujuhHari extends StatelessWidget {
  const _StripTujuhHari({required this.kemajuan});

  final Kemajuan kemajuan;

  @override
  Widget build(BuildContext context) {
    final hariIni = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.date_range_rounded, size: 14, color: Colors.black45),
            const SizedBox(width: 5),
            Text(
              '7 hari terakhir — bulatan bertanda ialah hari belajar',
              style: Teks.label.copyWith(color: Colors.black45),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
      children: [
        for (var i = 6; i >= 0; i--)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kemajuan.adaPadaHari(
                      hariIni.subtract(Duration(days: i)),
                    )
                        ? Warna.utama
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: Colors.white.withValues(
                      alpha: kemajuan.adaPadaHari(
                        hariIni.subtract(Duration(days: i)),
                      )
                          ? 1
                          : 0,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _hariPendek(hariIni.subtract(Duration(days: i))),
                  style: Teks.cop.copyWith(color: Colors.black45),
                ),
              ],
            ),
          ),
      ],
        ),
      ],
    );
  }

  /// Huruf pertama nama hari — "I", "S", "R", "K", "J", "S", "A".
  static String _hariPendek(DateTime d) => const [
        'A',
        'I',
        'S',
        'R',
        'K',
        'J',
        'S',
      ][d.weekday - 1];
}

/// Koleksi lencana — semua lencana yang ada, diperoleh atau belum.
///
/// Lencana yang belum diperoleh masih kelihatan, dikunci dan kelabu. Murid
/// lebih-working untuk *"dapat"* sesuatu yang belum ada daripada diberi
/// sesuatu yang sudah ada.
class _KoleksiLencana extends StatelessWidget {
  const _KoleksiLencana({required this.subjek});

  final List<Subjek> subjek;

  @override
  Widget build(BuildContext context) {
    final ada = Kemajuan.instance.lencanaDiperoleh;
    final jumlah = subjek.length * TahapLencana.values.length +
        DaftarLencana.global.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Warna.utama.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  size: 18, color: Warna.utama),
              const SizedBox(width: 6),
              Text(
                '${ada.length} daripada $jumlah lencana diperoleh',
                style: Teks.label.copyWith(color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final s in subjek) ...[
            Text(
              s.nama,
              style: Teks.label.copyWith(
                color: s.warna,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final t in TahapLencana.values) ...[
                  Expanded(
                    child: PetakLencana(
                      lencana: Lencana(
                        id: DaftarLencana.kunciSubjek(s.id, t),
                        tajuk: t.tajuk,
                        penerangan: t.penerangan,
                        ikon: t.ikon,
                        warna: t.warna,
                        subjekId: s.id,
                        peratus: t.peratus,
                      ),
                      diperoleh: ada.contains(
                        DaftarLencana.kunciSubjek(s.id, t),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Lencana global',
            style: Teks.label.copyWith(
              color: Warna.utama,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final l in DaftarLencana.global)
                SizedBox(
                  width: 78,
                  child: PetakLencana(
                    lencana: l,
                    diperoleh: ada.contains(l.id),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
