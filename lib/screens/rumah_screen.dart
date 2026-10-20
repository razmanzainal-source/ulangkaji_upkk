import 'package:flutter/material.dart';

import '../models/kertas.dart';
import '../services/bank_kertas.dart';
import '../services/kemajuan.dart';
import '../tema.dart';
import '../widgets/maskot.dart';
import 'info_screen.dart';
import 'kemajuan_screen.dart';
import 'kertas_sebenar_screen.dart';
import 'pilih_subjek_screen.dart';

/// Skrin utama app.
///
/// Empat tab yang sejajar dengan cara murid mengulang kaji:
///
///   1. **Percubaan** — jawab satu kertas penuh mengikut format UPKK.
///   2. **Kertas Sebenar** — baca imbasan kertas tahun lepas.
///   3. **Kemajuan** — lihat markah dan gred setiap subjek.
///   4. **Info** — tetapan, kredit dan penafian.
class RumahScreen extends StatefulWidget {
  const RumahScreen({super.key});

  @override
  State<RumahScreen> createState() => _RumahScreenState();
}

class _RumahScreenState extends State<RumahScreen> {
  int _tab = 0;

  /// Skrin disimpan supaya keadaan senarai (kedudukan tatal) tidak hilang
  /// apabila murid menukar tab.
  late final List<Widget> _skrin = [
    const PilihSubjekScreen(),
    const SenaraiKertasSebenar(),
    const KemajuanScreen(),
    const InfoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _skrin),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        indicatorColor: Warna.utamaLembut,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_note_rounded),
            selectedIcon: Icon(Icons.edit_note_rounded, color: Warna.utama),
            label: 'Percubaan',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_copy_outlined),
            selectedIcon: Icon(Icons.folder_copy_rounded, color: Warna.utama),
            label: 'Kertas',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded, color: Warna.utama),
            label: 'Kemajuan',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline_rounded),
            selectedIcon: Icon(Icons.info_rounded, color: Warna.utama),
            label: 'Info',
          ),
        ],
      ),
    );
  }
}

/// Kepala halaman yang dikongsi oleh senarai subjek dan Kertas Sebenar.
///
/// Raz sentiasa muncul di sini supaya murid mengenali penjuru atas skrin
/// sebagai "rumah" dan tahu tempat untuk kembali.
class KepalaRaz extends StatelessWidget {
  const KepalaRaz({
    super.key,
    required this.tajuk,
    required this.sari,
    this.mood = MoodMaskot.gembira,
    this.kanak,
  });

  final String tajuk;
  final String sari;
  final MoodMaskot mood;

  /// Kandungan tambahan di bawah sari kata (contohnya cip statistik).
  final Widget? kanak;

  @override
  Widget build(BuildContext context) {
    const bucu = BorderRadius.only(
      bottomLeft: Radius.circular(28),
      bottomRight: Radius.circular(28),
    );

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: _kecerunan, borderRadius: bucu),
      // Penjajaran lutsinar mesti dipangkas pada bucu bulat kepala, jadi
      // `ClipRRect` berada **di dalam** `Container` dan padding dipindahkan
      // ke dalamnya. Jika tidak, bulatan terpotong pada tepi padding dan
      // meninggalkan garis lurus yang jelas.
      child: ClipRRect(
        borderRadius: bucu,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(right: -30, top: -38, child: _Bulatan(104, Colors.white24)),
            Positioned(right: 78, top: 82, child: _Bulatan(46, Colors.white12)),
            Positioned(left: -40, bottom: -58, child: _Bulatan(132, Colors.white10)),
            Positioned(right: 118, bottom: -26, child: _Bulatan(60, Colors.white12)),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 54, 18, 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tajuk,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.15,
                            shadows: [
                              Shadow(color: Color(0x33000000), blurRadius: 6),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          sari,
                          style: Teks.label.copyWith(
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                        if (kanak != null) ...[
                          const SizedBox(height: 14),
                          kanak!,
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Maskot(saiz: 96, mood: mood),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kecerunan kepala halaman — dikongsi supaya semua kepala kelihatan seragam.
const _kecerunan = LinearGradient(
  colors: [Warna.utama, Warna.utamaMuda],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Bulatan lutsinar untuk hiasan kepala halaman.
///
/// Kepala gradien rata tanpa sebarang bentuk kelihatan muram dan besar
/// dengan sendirinya; bulatan ini memberi kedalaman tanpa bersaing dengan
/// teks kerana warnanya putih pada ketulisan rendah.
class _Bulatan extends StatelessWidget {
  const _Bulatan(this.saiz, this.warna);

  final double saiz;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: saiz,
      height: saiz,
      decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
    );
  }
}

/// Cip statistik kecil di atas kepala halaman.
class CipStat extends StatelessWidget {
  const CipStat({
    super.key,
    required this.ikon,
    required this.teks,
  });

  final IconData ikon;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 15, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            teks,
            style: Teks.label.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Senarai subjek yang perlu dijawab oleh murid.
///
/// Markah terbaik dipaparkan terus pada kad subjek supaya murid nampak kemajuan
/// tanpa perlu membuka tab Kemajuan.
List<Subjek> subjekTersedia() => BankKertas.instance.subjek;

/// Ringkasan pendek satu subjek untuk kad.
String ringkasanSubjek(Subjek subjek) {
  final bilangan = BankKertas.instance.bilanganSoalan(subjek.id);
  if (bilangan == 0) return 'Bank soalan belum dimuatkan';
  return '$bilangan soalan dalam bank';
}

/// Markah terbaik subjek dalam bentuk teks, atau `null` jika belum ada.
String? markahTerbaik(Subjek subjek) {
  final ringkasan = Kemajuan.instance.ringkasan(subjek.id);
  if (!ringkasan.adaRekod) return null;
  return '${ringkasan.markahTerbaik}/70 • Gred ${ringkasan.gredTerbaik.huruf}';
}
