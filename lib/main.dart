import 'package:flutter/material.dart';

import 'screens/kertas_screen.dart';
import 'screens/rumah_screen.dart';
import 'services/bank_kertas.dart';
import 'services/kemajuan.dart';
import 'services/suara.dart';
import 'services/tetapan.dart';
import 'tema.dart';
import 'widgets/maskot.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AplikasiUlangkajiUpkk());
}

/// App Ulangkaji UPKK.
///
/// App ini berfungsi **tanpa Internet**: semua soalan, skema jawapan dan
/// imbasan kertas tahun lepas dibundelkan sebagai aset. Ia juga tidak
/// mengumpul data murid — rekod kemajuan disimpan di dalam peranti sahaja.
class AplikasiUlangkajiUpkk extends StatelessWidget {
  const AplikasiUlangkajiUpkk({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ulangkaji UPKK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Warna.utama,
          primary: Warna.utama,
        ),
        scaffoldBackgroundColor: Warna.latarSkrin,
        fontFamily: null,
        appBarTheme: const AppBarTheme(
          backgroundColor: Warna.utama,
          foregroundColor: Colors.white,
        ),
      ),
      home: const SkrinMuatTurun(),
    );
  }
}

/// Skrin muat turun — membaca bank soalan dan rekod sebelum app dibuka.
///
/// Bacaan mengambil masa yang singkat (fail JSON tempatan), tetapi ia dilakukan
/// sekali sahaja di hadapan supaya skrin lain tidak perlu mengendalikan keadaan
/// "bank belum sedia".
class SkrinMuatTurun extends StatefulWidget {
  const SkrinMuatTurun({super.key});

  @override
  State<SkrinMuatTurun> createState() => _SkrinMuatTurunState();
}

class _SkrinMuatTurunState extends State<SkrinMuatTurun> {
  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    await Tetapan.instance.muat();
    await Kemajuan.instance.muat();
    await BankKertas.instance.muat();

    // Skrin kertas memerlukan senarai subjek untuk mendapatkan warna dan kod
    // subjek; ia diambil daripada bank yang baru dimuatkan.
    tetapkanSubjekKertas(BankKertas.instance.subjek);

    // Suara disediakan di belakang tabir — kegagalan suara tidak boleh
    // menghalang murid daripada menjawab.
    unawaited(Suara.instance.sedia());

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RumahScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Warna.utama,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Maskot(saiz: 150, mood: MoodMaskot.gembira),
            const SizedBox(height: 18),
            const Text(
              'Ulangkaji UPKK',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ujian Penilaian Kelas Al-Quran dan Fardu Ain',
              style: Teks.label.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 34),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Jalankan kerja tanpa menunggu — untuk tugas latar belakang yang kegagalannya
/// tidak sepatutnya menghalang app.
void unawaited(Future<void> kerja) {
  kerja.catchError((Object _) {});
}
