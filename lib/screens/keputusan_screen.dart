import 'dart:async';

import 'package:flutter/material.dart';

import '../models/gred.dart';
import '../models/jawapan.dart';
import '../models/kertas.dart';
import '../services/kongsi.dart';
import '../services/suara.dart';
import '../services/tetapan.dart';
import '../tarikh.dart';
import '../tema.dart';
import '../widgets/bunga_api.dart';
import '../widgets/dwibahasa.dart';
import '../widgets/kad_keputusan.dart';
import '../widgets/maskot.dart';
import 'kongsi_screen.dart';

/// Skrin keputusan — kertas yang sudah ditanda.
///
/// Paparan meniru kertas yang ditanda guru: markah ditulis dengan **pen merah**
/// pada tepi setiap soalan, dan cop gred diletakkan di atas kertas. Ini penting
/// untuk murid Tahun 5 — gred A/B/C/D ialah bahasa yang mereka kenal daripada
/// kertas sekolah, bukan peratus.
///
/// Skrin ini juga **meraikan** murid. Selepas satu jam menjawab kertas,
/// mendapat markah tanpa sebarang reaksi adalah saat yang paling hambar dalam
/// app; jadi gred A dan B disambut dengan fanfar dan bunga api. Murid yang
/// markahnya rendah tidak diraikan, tetapi tetap didengar ayat yang
/// mengajaknya mencuba lagi — bukan ayat yang menyalahkannya.
class KeputusanScreen extends StatefulWidget {
  const KeputusanScreen({
    super.key,
    required this.kertas,
    required this.jawapan,
  });

  final Kertas kertas;
  final Map<String, JawapanMurid> jawapan;

  @override
  State<KeputusanScreen> createState() => _KeputusanScreenState();
}

class _KeputusanScreenState extends State<KeputusanScreen> {
  /// Bilangan letupan bunga api yang diminta. `0` bermakna tiada.
  int _letupan = 0;

  /// Kunci kad perkongsian yang dilukis di luar skrin (lihat [_kadKongsi]).
  final GlobalKey _kunciKongsi = GlobalKey();

  /// Benar semasa gambar kad disediakan.
  bool _menyediakanKongsi = false;

  @override
  void initState() {
    super.initState();
    // Bunyi dimainkan selepas bingkai pertama dilukis. Kalau ia dimainkan dalam
    // `initState`, skrin belum wujud dan sesetengah peranti menggugurkan bunyi
    // itu begitu sahaja.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sambut();
    });
  }

  void _sambut() {
    final peratus = widget.kertas.peratus(widget.jawapan);
    final markah = widget.kertas.markahDiperoleh(widget.jawapan);
    final penuh = widget.kertas.markahTersedia;
    final (kunci, teks) = Suara.keputusan(
      peratus,
      sempurna: penuh > 0 && markah == penuh,
    );

    if (peratus >= 60) {
      setState(() => _letupan = 1);
      unawaited(_sambutan(Suara.kesanHebat, kunci, teks));
    } else {
      unawaited(_sambutan(Suara.kesanSalah, kunci, teks));
    }
  }

  /// Nada sambutan dahulu, ayat maklum balas kemudian.
  ///
  /// Urutan ini yang menjadikan ayat itu jelas: nada sambutan hanya 1–2 saat,
  /// dan memainkannya **serentak** dengan ayat membuat permulaan ayat tenggelam
  /// — murid mengadu suara "tak clear & tidak penuh". Bunga api kekal serta-merta
  /// kerana ia penglihatan, bukan bunyi.
  Future<void> _sambutan(String nada, String kunci, String teks) async {
    await Suara.instance.mainkanKesanSelesai(nada);
    await Suara.instance.sebutKunci(kunci, sandaran: teks);
  }

  // --- Kongsi keputusan ----------------------------------------------------

  /// Kad keputusan yang ditangkap sebagai gambar untuk dikongsi.
  ///
  /// Kad ini dilukis **di luar kawasan yang kelihatan** — kedudukannya
  /// diletakkan jauh di kiri skrin. Sebabnya: gambar yang dikongsi mesti
  /// lengkap dari kepala hingga kaki, dan apa sahaja yang berada di dalam
  /// senarai skrol akan terpotong mengikut kedudukan skrol pada masa itu.
  Widget _kadKongsi() {
    final kertas = widget.kertas;
    final jawapan = widget.jawapan;
    final peratus = kertas.peratus(jawapan);

    return KadKeputusan(
      kertas: kertas,
      jawapan: jawapan,
      markah: kertas.markahDiperoleh(jawapan),
      penuh: kertas.markahTersedia,
      peratus: peratus,
      gred: Gred.dariPeratus(peratus),
      nama: Tetapan.instance.namaAnak,
      tarikh: tarikhMelayu(DateTime.now()),
    );
  }

  /// Menyediakan gambar kad keputusan, kemudian membuka skrin perkongsian.
  Future<void> _kongsi() async {
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

    final kertas = widget.kertas;
    final jawapan = widget.jawapan;
    final peratus = kertas.peratus(jawapan);
    final nama = Tetapan.instance.namaAnak.trim();
    final pecahan = kertas.bahagian
        .map((b) {
          final penuh = b.markahTersedia == 0 ? b.markah : b.markahTersedia;
          return 'Bahagian ${b.nama} '
              '${kertas.markahBahagian(b.nama, jawapan)}/$penuh';
        })
        .join('  ·  ');

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KongsiScreen(
          imej: imej,
          teks: Kongsi.kapsyenKeputusan(
            tajuk: kertas.tajuk,
            markah: kertas.markahDiperoleh(jawapan),
            penuh: kertas.markahTersedia,
            peratus: peratus,
            gred: Gred.dariPeratus(peratus),
            pecahan: pecahan,
          ),
          namaFail: 'keputusan-upkk-${kertas.subjekId}.png',
          namaSimpan: nama.isEmpty
              ? 'keputusan_upkk_${kertas.subjekId}'
              : 'keputusan_upkk_${kertas.subjekId}_'
                    '${nama.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_')}',
        ),
      ),
    );
  }

  /// Butang kongsi di bawah keputusan.
  ///
  /// Ia diletakkan di hujung skrin — selepas murid membaca markahnya — kerana
  /// perkongsian ialah sesuatu yang ibu bapa lakukan **selepas** anak selesai
  /// membaca keputusannya, bukan sebelum.
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
            onPressed: _menyediakanKongsi ? null : _kongsi,
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
              _menyediakanKongsi ? 'Menyediakan gambar...' : 'Kongsi keputusan',
              style: Teks.besar,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hantar gambar keputusan ini kepada ibu bapa atau guru melalui '
          'WhatsApp, Facebook, Instagram atau Threads.',
          textAlign: TextAlign.center,
          style: Teks.label.copyWith(
            color: Colors.black.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final kertas = widget.kertas;
    final jawapan = widget.jawapan;
    final markah = kertas.markahDiperoleh(jawapan);
    final penuh = kertas.markahTersedia;
    final peratus = kertas.peratus(jawapan);
    final gred = Gred.dariPeratus(peratus);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Warna.latarSkrin,
          appBar: AppBar(
            backgroundColor: Warna.utama,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text('Keputusan', style: Teks.sederhana),
            actions: [
              IconButton(
                tooltip: 'Kongsi keputusan',
                onPressed: _menyediakanKongsi ? null : _kongsi,
                icon: const Icon(Icons.ios_share_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _KadMarkah(
                markah: markah,
                penuh: penuh,
                peratus: peratus,
                gred: gred,
                nama: Tetapan.instance.namaAnak,
              ),
              const SizedBox(height: 16),
              _PecahanBahagian(kertas: kertas, jawapan: jawapan),
              const SizedBox(height: 16),
              const Text('Semakan jawapan', style: Teks.sederhana),
              const SizedBox(height: 8),
              for (final b in kertas.bahagian) ...[
                _BahagianBertanda(
                  bahagian: b,
                  jawapan: jawapan,
                  adaSeksyen: kertas.bahagian.length > 1,
                ),
              ],
              const SizedBox(height: 12),
              _NotaGred(gred: gred),
              const SizedBox(height: 20),
              _butangKongsi(),
            ],
          ),
        ),
        // Kad perkongsian: kad keputusan penuh yang dilukis di luar kawasan
        // yang kelihatan, dan hanya sementara gambar sedang disediakan. Ia
        // tidak pernah dipotong oleh kedudukan skrol, jadi gambar yang
        // dikongsi sentiasa lengkap.
        if (_menyediakanKongsi)
          Positioned(
            left: -4000,
            top: 0,
            child: RepaintBoundary(key: _kunciKongsi, child: _kadKongsi()),
          ),
        if (_letupan > 0)
          Positioned.fill(
            child: BungaApi(
              key: ValueKey(_letupan),
              letupan: peratus >= 80 ? 5 : 3,
              onTamat: () {
                if (mounted) setState(() => _letupan = 0);
              },
            ),
          ),
      ],
    );
  }
}

/// Kad markah besar dengan cop gred.
class _KadMarkah extends StatelessWidget {
  const _KadMarkah({
    required this.markah,
    required this.penuh,
    required this.peratus,
    required this.gred,
    this.nama = '',
  });

  final int markah;
  final int penuh;
  final int peratus;
  final Gred gred;

  /// Nama anak. Nama menjadikan pujian terasa ditujukan kepada **dia**,
  /// bukan kepada sesiapa sahaja yang memegang telefon.
  final String nama;

  @override
  Widget build(BuildContext context) {
    final cemerlang = gred.cemerlang;
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
      child: Column(
        children: [
          Row(
            children: [
              Maskot(
                saiz: 92,
                mood: cemerlang ? MoodMaskot.hebat : MoodMaskot.gembira,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pujian(peratus, nama),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$markah daripada $penuh markah',
                      style: Teks.biasa.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$peratus%',
                      style: Teks.label.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              _CopGred(gred: gred),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: penuh <= 0 ? 0 : markah / penuh,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  static String _pujian(int peratus, String nama) {
    // Sapaan nama hanya letak koma selepas pujian apabila nama benar-benar ada
    // — kalau tidak, ayat tergantung seperti "Cemerlang, !".
    final sapaan = nama.trim().isEmpty ? '' : ', ${nama.trim()}';
    if (peratus >= 80) return 'Cemerlang$sapaan!';
    if (peratus >= 60) return 'Bagus$sapaan!';
    if (peratus >= 40) return 'Boleh lagi$sapaan!';
    return 'Jangan putus asa$sapaan!';
  }
}

/// Cop gred bergaya tanda guru — bulatan berputar sedikit dengan huruf besar.
class _CopGred extends StatelessWidget {
  const _CopGred({required this.gred});

  final Gred gred;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.12,
      child: Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('GRED', style: Teks.cop.copyWith(color: Colors.white70)),
            Text(gred.huruf, style: Teks.gred.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// Pecahan markah setiap bahagian — bar mendatar.
class _PecahanBahagian extends StatelessWidget {
  const _PecahanBahagian({required this.kertas, required this.jawapan});

  final Kertas kertas;
  final Map<String, JawapanMurid> jawapan;

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
          const Text('Pecahan markah', style: Teks.sederhana),
          const SizedBox(height: 12),
          for (final b in kertas.bahagian)
            _BarisBahagian(
              nama: b.nama,
              diperoleh: kertas.markahBahagian(b.nama, jawapan),
              penuh: b.markahTersedia == 0 ? b.markah : b.markahTersedia,
              catatan: b.markahTersedia != b.markah
                  ? 'bank ${b.markahTersedia}/${b.markah}'
                  : null,
            ),
        ],
      ),
    );
  }
}

class _BarisBahagian extends StatelessWidget {
  const _BarisBahagian({
    required this.nama,
    required this.diperoleh,
    required this.penuh,
    this.catatan,
  });

  final String nama;
  final int diperoleh;
  final int penuh;
  final String? catatan;

  @override
  Widget build(BuildContext context) {
    final nisbah = penuh <= 0 ? 0.0 : diperoleh / penuh;
    final warna = nisbah >= 0.8
        ? Warna.betul
        : nisbah >= 0.5
        ? Warna.tepiNota
        : Warna.salah;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Warna.utamaLembut,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              nama,
              style: Teks.sederhana.copyWith(color: Warna.utama, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: nisbah,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF0F0F0),
                    valueColor: AlwaysStoppedAnimation(warna),
                  ),
                ),
                if (catatan != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    catatan!,
                    style: Teks.label.copyWith(color: Colors.black45),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$diperoleh/$penuh',
            style: Teks.biasa.copyWith(
              fontWeight: FontWeight.w800,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu bahagian kertas dengan tanda pen merah pada setiap soalan.
class _BahagianBertanda extends StatelessWidget {
  const _BahagianBertanda({
    required this.bahagian,
    required this.jawapan,
    required this.adaSeksyen,
  });

  final BahagianKertas bahagian;
  final Map<String, JawapanMurid> jawapan;
  final bool adaSeksyen;

  @override
  Widget build(BuildContext context) {
    final diperoleh = bahagian.soalan.fold(
      0,
      (jumlah, s) => jumlah + s.markahDiperoleh(jawapan[s.id]),
    );
    final penuh = bahagian.markahTersedia;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (adaSeksyen) ...[
            Row(
              children: [
                Text('Bahagian ${bahagian.nama}', style: Teks.sederhana),
                const Spacer(),
                Text(
                  '$diperoleh/$penuh',
                  style: Teks.biasa.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Warna.dakwat,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          for (final s in bahagian.soalan)
            _SoalanBertanda(soalan: s, jawapan: jawapan[s.id]),
        ],
      ),
    );
  }
}

class _SoalanBertanda extends StatelessWidget {
  const _SoalanBertanda({required this.soalan, required this.jawapan});

  final SoalanKertas soalan;
  final JawapanMurid? jawapan;

  @override
  Widget build(BuildContext context) {
    final diperoleh = soalan.markahDiperoleh(jawapan);
    final penuh = soalan.markahBolehDapat;
    final betul = penuh > 0 && diperoleh == penuh;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '${soalan.nombor}.',
                        style: Teks.label.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (soalan.soalan.isNotEmpty)
                            Dwibahasa(
                              jawi: soalan.soalan,
                              rumi: soalan.rumi,
                              gayaJawi: Teks.jawiKecil,
                            )
                          else
                            Text(
                              _ringkas(soalan),
                              style: Teks.label.copyWith(height: 1.4),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            _ringkasJawapan(soalan, jawapan),
                            style: Teks.label.copyWith(
                              color: betul ? Warna.betul : Warna.salah,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                          if (!betul && penuh > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Jawapan: ${_ringkasBetul(soalan)}',
                              style: Teks.label.copyWith(
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Markah ditulis seperti guru menanda dengan pen merah.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Warna.dakwat, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (betul)
                  const Padding(
                    padding: EdgeInsets.only(right: 3),
                    child: Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Warna.dakwat,
                    ),
                  ),
                Text(
                  '$diperoleh/$penuh',
                  style: Teks.label.copyWith(
                    color: Warna.dakwat,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ringkasan soalan apabila soalan tiada teks utama — itemnya sahaja.
  static String _ringkas(SoalanKertas s) {
    if (s.item.isEmpty) return s.jenis.teks;
    final pertama = s.item.first.teks;
    return s.item.length == 1
        ? pertama
        : '$pertama  (+${s.item.length - 1} lagi)';
  }

  /// Jawapan murid dalam bentuk teks ringkas.
  static String _ringkasJawapan(SoalanKertas s, JawapanMurid? j) {
    if (j == null) return 'Tidak dijawab';
    return switch (j) {
      JawapanPilihanKertas(:final pilihan) => [
        for (var i = 0; i < s.item.length; i++)
          if (i < pilihan.length && pilihan[i] >= 0)
            s.item[i].pilihan[pilihan[i]]
          else
            '—',
      ].join(', '),
      JawapanBetulSalah(:final jawapan) => [
        for (var i = 0; i < s.item.length; i++)
          '${i + 1}. ${i < jawapan.length && jawapan[i] != null ? (jawapan[i]! ? '✓' : '✗') : '—'}',
      ].join('  '),
      JawapanPadan(:final padanan) =>
        padanan.entries
            .map(
              (e) => '${s.pasangan[e.key].kiri} → ${s.pasangan[e.value].kanan}',
            )
            .join('\n'),
      JawapanSusun(:final susunan) =>
        susunan.map((i) => i < s.urutan.length ? s.urutan[i] : '').join(' '),
      JawapanTempatKosong(:final isi) =>
        isi.entries
            .map(
              (e) =>
                  '${e.key + 1}. ${e.value < s.bank.length ? s.bank[e.value] : ''}',
            )
            .join('  '),
      JawapanTaip(:final teks) => teks.isEmpty ? 'Tidak dijawab' : teks,
      _ => 'Tidak dijawab',
    };
  }

  /// Jawapan sebenar dalam bentuk teks ringkas.
  static String _ringkasBetul(SoalanKertas s) {
    final penuh = s.jawapanPenuhTeks;
    if (penuh.isNotEmpty && penuh.length <= 200) return penuh;
    return switch (s.jenis) {
      JenisKertas.objektif || JenisKertas.bulat =>
        s.item
            .map(
              (i) => i.jawapan >= 0 && i.jawapan < i.pilihan.length
                  ? i.pilihan[i.jawapan]
                  : '',
            )
            .where((t) => t.isNotEmpty)
            .join(', '),
      JenisKertas.betulSalah =>
        s.item
            .map((i) => i.betul == null ? '' : (i.betul! ? '✓' : '✗'))
            .join('  '),
      JenisKertas.suai => s.pasangan.map((p) => p.kanan).join(', '),
      JenisKertas.susun => s.urutan.join(' '),
      JenisKertas.tempatKosong => s.bank.join(', '),
      JenisKertas.tulis ||
      JenisKertas.huraian => s.rubrik.idea.map((i) => i.maksud).join(' • '),
    };
  }
}

/// Nota julat gred rasmi UPKK.
class _NotaGred extends StatelessWidget {
  const _NotaGred({required this.gred});

  final Gred gred;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Warna.latarNota,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Warna.tepiNota, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Warna.tepiNota,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('Julat gred UPKK', style: Teks.sederhana),
            ],
          ),
          const SizedBox(height: 10),
          for (final g in Gred.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: g.warna.withValues(alpha: g == gred ? 1 : 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      g.huruf,
                      style: Teks.label.copyWith(
                        fontWeight: FontWeight.w900,
                        color: g == gred ? Colors.white : g.warna,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      g.nama,
                      style: Teks.biasa.copyWith(
                        fontWeight: g == gred
                            ? FontWeight.w900
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    g.julatTeks,
                    style: Teks.label.copyWith(
                      color: Colors.black54,
                      fontWeight: g == gred ? FontWeight.w900 : FontWeight.w500,
                    ),
                  ),
                  if (g == gred) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_left_rounded, color: g.warna, size: 20),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
