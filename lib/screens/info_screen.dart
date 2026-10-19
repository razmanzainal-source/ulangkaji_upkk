import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/gred.dart';
import '../services/bank_kertas.dart';
import '../services/kemajuan.dart';
import '../services/simpan_gambar.dart';
import '../services/tetapan.dart';
import '../tema.dart';
import '../widgets/dialog_nama.dart';
import '../widgets/maskot.dart';

/// Tab "Info" — penerangan app, tetapan dan kredit.
///
/// Skrin ini penting untuk **ibu bapa**, bukan murid. Ia menerangkan apa yang
/// app ini buat, dari mana soalan datang, apa yang disimpan (dan tidak
/// disimpan), serta siapa yang membinanya.
class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  /// Versi app — dipaparkan pada skrin Info.
  static const String versi = '1.0.0';

  /// Alamat e-mel pembina app, untuk pertanyaan dan pembetulan.
  static const String emel = 'razman.zainal@gmail.com';

  /// Nama pemegang hak cipta app.
  static const String pemilik = 'Razman Zainal';

  /// Tahun hak cipta.
  static const int tahun = 2026;

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  @override
  Widget build(BuildContext context) {
    final jumlahSoalan = BankKertas.instance.subjek
        .fold<int>(0, (j, s) => j + BankKertas.instance.bilanganSoalan(s.id));
    final jumlahMuka = BankKertas.instance.semuaKertasSebenar
        .fold<int>(0, (j, k) => j + k.muka);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const _Kepala(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Kotak(
                tajuk: 'Apa app ini',
                ikon: Icons.info_rounded,
                kanak: const [
                  _Perenggan(
                    'Ulangkaji UPKK ialah app ulang kaji untuk murid Tahun 5 '
                    'yang akan menduduki Ujian Penilaian Kelas Al-Quran dan '
                    'Fardu Ain (UPKK).',
                  ),
                  _Perenggan(
                    'App ini mengandungi enam subjek bertulis UPKK: Adab, '
                    'Akidah, Bahasa Arab, Ibadah, Jawi dan Khat, serta Sirah. '
                    'Setiap kertas percubaan dibina mengikut format rasmi '
                    'UPKK — 70 markah, 1 jam 15 minit, bahagian A hingga E '
                    'mengikut subjek.',
                  ),
                  _Perenggan(
                    'Semua soalan dalam app ini ditulis sendiri untuk app ini '
                    'berdasarkan format dan skop sukatan UPKK. Ia bukan '
                    'soalan bocor dan bukan ramalan.',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Kotak(
                tajuk: 'Kandungan',
                ikon: Icons.library_books_rounded,
                kanak: [
                  _BarisNilai(
                    label: 'Subjek',
                    nilai: '${BankKertas.instance.subjek.length}',
                  ),
                  _BarisNilai(
                    label: 'Soalan dalam bank',
                    nilai: '$jumlahSoalan',
                  ),
                  _BarisNilai(
                    label: 'Kertas sebenar',
                    nilai: '${BankKertas.instance.semuaKertasSebenar.length} '
                        'kertas • $jumlahMuka muka',
                  ),
                  const _BarisNilai(label: 'Versi', nilai: InfoScreen.versi),
                ],
              ),
              const SizedBox(height: 12),
              _Kotak(
                tajuk: 'Kertas sebenar',
                ikon: Icons.folder_copy_rounded,
                kanak: const [
                  _Perenggan(
                    'Tab "Kertas" mengandungi imbasan kertas UPKK 2024 dan '
                    '2025 untuk setiap subjek. Kertas ini dipaparkan sebagai '
                    'gambar, bukan ditulis semula — jadi susun atur, arahan '
                    'dan bentuk soalannya sama seperti kertas sebenar.',
                  ),
                  _Perenggan(
                    'Gunakan kertas sebenar untuk mengenal bentuk kertas. '
                    'Gunakan kertas percubaan dalam app untuk berlatih '
                    'menjawab dalam masa yang ditetapkan.',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Gred(),
              const SizedBox(height: 12),
              _Tetapan(),
              const SizedBox(height: 12),
              _Kotak(
                tajuk: 'Privasi',
                ikon: Icons.lock_rounded,
                kanak: const [
                  _Perenggan(
                    'App ini berfungsi sepenuhnya tanpa Internet. Ia tidak '
                    'meminta akaun, tidak menghantar apa-apa, dan tidak '
                    'mengumpul sebarang data.',
                  ),
                  _Perenggan(
                    'Markah dan rekod percubaan disimpan di dalam telefon ini '
                    'sahaja, dan boleh dipadam pada bila-bila masa dengan '
                    'butang di bawah.',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _Sumbangan(),
              const SizedBox(height: 12),
              _Kredit(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Laluan kod QR sumbangan.
///
/// Kod QR **tidak** dipaparkan terus dalam skrin info (ia besar dan mengganggu
/// bacaan); ia dibuka dalam tetingkap timbul melalui butang "Kod QR sumbangan".
const String qrDonasi = 'assets/gambar/qr_donasi.png';

/// Nama pemegang akaun yang tertera pada kod QR sumbangan.
const String namaAkaunDonasi = 'Razman Bin Md Zainal';

/// Kad sumbangan — app ini percuma dan tiada iklan.
///
/// Sumbangan **sukarela sepenuhnya**: tiada kandungan app dikunci di belakang
/// bayaran, dan tiada gesaan berulang. Ia hanya dinyatakan sekali di sini,
/// untuk ibu bapa yang bertanya bagaimana hendak membalas.
class _Sumbangan extends StatelessWidget {
  const _Sumbangan();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Warna.utamaLembut,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Warna.utamaMuda, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded, size: 20, color: Warna.utama),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'App ini percuma dan tiada iklan',
                  style: Teks.biasa.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Kalau app ini membantu anak atau murid awak, sumbangan sukarela '
            'amat dihargai — bagi kos penyelenggaraan, suara rakaman dan '
            'penambahan soalan baharu.',
            style: Teks.biasa.copyWith(height: 1.5, color: Colors.black87),
          ),
          const SizedBox(height: 14),
          Center(
            child: FilledButton.icon(
              onPressed: () => _bukaQr(context),
              icon: const Icon(Icons.qr_code_2_rounded, size: 20),
              label: const Text(
                'Kod QR sumbangan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Warna.utama,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kod QR boleh dilihat, kemudian disimpan ke galeri telefon atau '
            'dimuat turun.',
            textAlign: TextAlign.center,
            style: Teks.label.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  /// Buka kod QR sumbangan di dalam tetingkap timbul.
  Future<void> _bukaQr(BuildContext context) => showDialog<void>(
        context: context,
        builder: (_) => const DialogQrDonasi(),
      );
}

/// Tetingkap timbul kod QR sumbangan — boleh dilihat dan disimpan.
class DialogQrDonasi extends StatefulWidget {
  const DialogQrDonasi({super.key});

  @override
  State<DialogQrDonasi> createState() => _DialogQrDonasiState();
}

class _DialogQrDonasiState extends State<DialogQrDonasi> {
  bool _menyimpan = false;

  Future<void> _simpan() async {
    setState(() => _menyimpan = true);

    var berjaya = false;
    try {
      final data = await rootBundle.load(qrDonasi);
      berjaya = await simpanGambarKeGaleri(
        data.buffer.asUint8List(),
        nama: 'qr_sumbangan_ulangkaji_upkk',
      );
    } catch (_) {
      berjaya = false;
    }

    if (!mounted) return;
    setState(() => _menyimpan = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          berjaya
              ? 'Kod QR disimpan. Semak dalam Galeri atau folder Muat Turun.'
              : 'Kod QR tidak dapat disimpan. Cuba tangkap skrin, atau imbas '
                  'terus daripada paparan ini.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Kod QR sumbangan', style: Teks.sederhana),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Terima kasih atas sokongan! Imbas kod QR ini dengan aplikasi '
              'bank atau e-dompit, atau simpan untuk digunakan kemudian.',
              textAlign: TextAlign.center,
              style: Teks.label.copyWith(height: 1.45),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                qrDonasi,
                width: 250,
                errorBuilder: (_, _, _) => Text(
                  'Kod QR tidak dapat dipaparkan.',
                  style: Teks.label.copyWith(color: Warna.salah),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              namaAkaunDonasi,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _menyimpan ? null : () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
        FilledButton.icon(
          onPressed: _menyimpan ? null : _simpan,
          icon: _menyimpan
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Icon(Icons.download_rounded, size: 19),
          label: Text(_menyimpan ? 'Menyimpan…' : 'Simpan'),
          style: FilledButton.styleFrom(
            backgroundColor: Warna.utama,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _Kepala extends StatelessWidget {
  const _Kepala();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 54, 18, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Warna.utama, Warna.utamaMuda],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          const Maskot(saiz: 116, mood: MoodMaskot.gembira),
          const SizedBox(height: 10),
          const Text(
            'Ulangkaji UPKK',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Versi ${InfoScreen.versi} • Percuma',
            style: Teks.label.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

/// Kotak kad dengan tajuk dan ikon.
class _Kotak extends StatelessWidget {
  const _Kotak({
    required this.tajuk,
    required this.ikon,
    required this.kanak,
  });

  final String tajuk;
  final IconData ikon;
  final List<Widget> kanak;

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
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Warna.utamaLembut,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(ikon, size: 19, color: Warna.utama),
              ),
              const SizedBox(width: 11),
              Text(tajuk, style: Teks.sederhana),
            ],
          ),
          const SizedBox(height: 12),
          ...kanak,
        ],
      ),
    );
  }
}

class _Perenggan extends StatelessWidget {
  const _Perenggan(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        teks,
        style: Teks.biasa.copyWith(height: 1.5, color: Colors.black87),
      ),
    );
  }
}

class _BarisNilai extends StatelessWidget {
  const _BarisNilai({required this.label, required this.nilai});

  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: Teks.biasa)),
          Text(
            nilai,
            style: Teks.biasa.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Jadual gred rasmi UPKK.
class _Gred extends StatelessWidget {
  const _Gred();

  @override
  Widget build(BuildContext context) {
    return _Kotak(
      tajuk: 'Julat gred UPKK',
      ikon: Icons.emoji_events_rounded,
      kanak: [
        for (final g in Gred.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: g.warna.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    g.huruf,
                    style: Teks.sederhana.copyWith(
                      color: g.warna,
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    g.nama,
                    style: Teks.biasa.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  g.julatTeks,
                  style: Teks.biasa.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Tetapan bunyi dan butang padam rekod.
class _Tetapan extends StatefulWidget {
  const _Tetapan();

  @override
  State<_Tetapan> createState() => _TetapanState();
}

class _TetapanState extends State<_Tetapan> {
  @override
  Widget build(BuildContext context) {
    return _Kotak(
      tajuk: 'Tetapan',
      ikon: Icons.settings_rounded,
      kanak: [
        // Nama anak diletakkan paling atas kerana ia perkara pertama yang
        // ibu bapa mahu betulkan apabila Upik menyapa nama yang salah.
        Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_rounded, color: Warna.utama),
            title: const Text('Nama anak', style: Teks.biasa),
            subtitle: Text(
              Tetapan.instance.adaNama
                  ? Tetapan.instance.namaAnak
                  : 'Belum ditetapkan — Upik belum tahu nama murid.',
              style: Teks.label.copyWith(color: Colors.black54),
            ),
            trailing: const Icon(Icons.edit_outlined, size: 20),
            onTap: () => _tukarNama(context),
          ),
        ),
        const Divider(height: 20),
        // `SwitchListTile` melukis latar dan kesan sentuh (ink) pada `Material`
        // terdekat di atasnya. Di sini yang terdekat ialah `Material` skrin,
        // manakala kotak putih [_Kotak] dilukis **selepas** itu — jadi kesan
        // sentuh hilang di belakang kotak dan Flutter melemparkan ralat
        // (dilihat dalam `flutter run`). Satu `Material` lutsinar di dalam kotak
        // meletakkan kesan itu di atas latar putih, di mana ia sepatutnya
        // kelihatan.
        Material(
          color: Colors.transparent,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: Tetapan.instance.bunyiHidup,
            activeThumbColor: Warna.utama,
            title: const Text('Bunyi', style: Teks.biasa),
            subtitle: Text(
              'Suara membaca soalan dan maklum balas jawapan.',
              style: Teks.label.copyWith(color: Colors.black54),
            ),
            onChanged: (hidup) async {
              await Tetapan.instance.tetapkanBunyi(hidup);
              if (mounted) setState(() {});
            },
          ),
        ),
        const Divider(height: 20),
        Text(
          'Rekod kemajuan disimpan dalam peranti ini sahaja.',
          style: Teks.label.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _padam(context),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Padam semua rekod', style: Teks.biasa),
          style: OutlinedButton.styleFrom(
            foregroundColor: Warna.salah,
            side: const BorderSide(color: Warna.salah),
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _tukarNama(BuildContext konteks) async {
    final nama = await tanyaNama(
      konteks,
      nilaiAwal: Tetapan.instance.namaAnak,
      tukar: true,
    );
    if (nama == null || nama.isEmpty) return;

    await Tetapan.instance.tetapkanNama(nama);
    if (mounted) setState(() {});
  }

  Future<void> _padam(BuildContext konteks) async {
    final pasti = await showDialog<bool>(
      context: konteks,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Padam semua rekod?', style: Teks.besar),
        content: const Text(
          'Semua markah dan percubaan akan dibuang. Tindakan ini tidak boleh '
          'dibatalkan.',
          style: Teks.biasa,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            style: FilledButton.styleFrom(backgroundColor: Warna.salah),
            child: const Text('Padam'),
          ),
        ],
      ),
    );
    if (pasti != true) return;
    await Kemajuan.instance.padamSemua();
    if (!konteks.mounted) return;
    ScaffoldMessenger.of(konteks).showSnackBar(
      const SnackBar(
        content: Text('Semua rekod telah dipadam.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() {});
  }
}

/// Kredit pembina dan hak cipta.
class _Kredit extends StatelessWidget {
  const _Kredit();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Warna.utama, Warna.utamaMuda],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Maskot(saiz: 84, mood: MoodMaskot.gembira),
          const SizedBox(height: 10),
          const Text(
            'Dibina untuk anak-anak KAFA',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'App ini percuma. Kongsikan kepada guru dan ibu bapa lain — '
            'semoga ia bermanfaat.',
            textAlign: TextAlign.center,
            style: Teks.label.copyWith(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mail_outline_rounded,
                    size: 17, color: Colors.white),
                const SizedBox(width: 7),
                SelectableText(
                  InfoScreen.emel,
                  style: Teks.biasa.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Maklum balas, pembetulan ejaan Jawi dan cadangan soalan amat '
            'dialu-alukan.',
            textAlign: TextAlign.center,
            style: Teks.label.copyWith(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          Text(
            '© ${InfoScreen.tahun} ${InfoScreen.pemilik}\nHak cipta terpelihara.',
            textAlign: TextAlign.center,
            style: Teks.label.copyWith(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }
}
