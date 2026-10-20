import 'dart:async';

import 'package:flutter/material.dart';

import '../models/jawapan.dart';
import '../models/kertas.dart';
import '../services/kemajuan.dart';
import '../services/pemarkah.dart';
import '../services/suara.dart';
import '../tema.dart';
import '../widgets/bunga_api.dart';
import '../widgets/butang_pilihan.dart';
import '../widgets/dwibahasa.dart';
import '../widgets/maskot.dart';
import '../widgets/papan_betul_salah.dart';
import '../widgets/papan_kekunci_tulisan.dart';
import '../widgets/papan_padan.dart';
import '../widgets/papan_susun.dart';
import '../widgets/papan_taip.dart';
import '../widgets/papan_tempat_kosong.dart';
import 'keputusan_screen.dart';
import 'latihan_selesai_screen.dart';

/// Skrin menjawab satu kertas UPKK penuh.
///
/// Murid menjawab satu soalan pada satu masa, tetapi setiap halaman dibina
/// supaya menyerupai kertas sebenar:
///
///   * **Kulit kertas** di hadapan — kod subjek, markah, masa dan arahan,
///     sama seperti yang tercetak pada kertas UPKK.
///   * **Jalur bahagian** di atas setiap soalan — `بهاضين A ﴾ 10 مرکه ﴿`
///     berserta arahan bahagian itu.
///   * **Nombor soalan dan markah** di tepi soalan, seperti pada kertas.
///
/// Masa menjawab ialah 1 jam 15 minit, sama seperti UPKK. Kertas dihantar
/// secara automatik apabila masa tamat, jadi murid membiasakan diri menjawab
/// dalam tempoh sebenar.
class KertasScreen extends StatefulWidget {
  const KertasScreen({super.key, required this.kertas});

  final Kertas kertas;

  @override
  State<KertasScreen> createState() => _KertasScreenState();
}

class _KertasScreenState extends State<KertasScreen> {
  /// Halaman semasa: `-1` kulit kertas, `0..n-1` soalan, `n` semak.
  int _halaman = -1;

  final Map<String, JawapanMurid> _jawapan = {};

  /// Pengawal medan taip — mesti kekal hidup walaupun halaman dibina semula.
  final Map<String, TextEditingController> _kawalan = {};

  /// Pengawal bagi setiap kotak bagi soalan bertulis **berbilang baris**.
  ///
  /// Kertas asal memberi satu ruang bernombor bagi setiap isi yang diminta
  /// ("Jelaskan lima akibat" = lima baris), jadi app turut memaparkan lima
  /// kotak bernombor dan memecahkan jawapan itu sendiri.
  final Map<String, List<TextEditingController>> _kawalanBaris = {};

  /// Baris yang sedang menjadi sasaran papan kekunci bagi setiap soalan.
  ///
  /// Papan kekunci Jawi/Arab dalam app menulis kepada **satu** medan sahaja,
  /// jadi skrin mesti menyimpan medan mana yang sedang dipilih. Nilai lalai
  /// `0` supaya menaip terus berfungsi sebaik sahaja papan kekunci terbuka
  /// tanpa murid perlu mengetuk kotak dahulu.
  final Map<String, ValueNotifier<int?>> _barisAktif = {};

  /// Susunan paparan (kocokan) bagi soalan padan, susun dan tempat kosong.
  final Map<String, Paparan> _paparan = {};

  /// Indeks kiri yang sedang dipilih bagi soalan padan.
  final Map<String, int?> _padanTerpilih = {};

  /// Soalan yang sudah dipuji atau sudah ditegur.
  ///
  /// Murid boleh menekan pilihan yang sama berulang kali (dan kanak-kanak
  /// memang berbuat demikian). Tanpa set ini, satu jawapan betul boleh
  /// menghasilkan lima letupan bunga api dalam tiga saat.
  final Set<String> _sudahDipuji = {};
  final Set<String> _sudahDitegur = {};

  /// Soalan yang jawapannya sudah **dimuktamadkan** oleh murid — menekan
  /// pilihan, ✓/✗, padan, atau "Siap" pada medan taip.
  ///
  /// Pembetulan hanya dipaparkan untuk soalan ini. Semasa murid menaip huruf
  /// satu demi satu, jawapannya belum muktamad dan panel jawapan betul akan
  /// mendedahkan jawapan sebelum dia siap mencuba.
  final Set<String> _dimuktamadkan = {};

  /// Soalan bertulis yang papannya ditutup sendiri oleh murid.
  ///
  /// Papan kekunci Jawi/Arab **terbuka sendiri** pada setiap soalan bertulis:
  /// murid tidak sepatutnya perlu mencari butang untuk mula menulis. Set ini
  /// hanya menyimpan soalan yang sengaja ditutup, supaya papan itu tidak
  /// terbuka semula setiap kali skrin dibina semula (contohnya semasa maskot
  /// beranimasi atau bunga api meletup).
  final Set<String> _kekunciDitutup = {};

  /// Bertambah satu setiap kali murid mendapat soalan betul.
  ///
  /// Bertindak sebagai kunci [BungaApi]: nilai baharu bermakna widget dibina
  /// semula, jadi letupan kedua tidak dilangkau. Nilai `0` bermakna tiada
  /// letupan — ia dikembalikan kepada `0` oleh `BungaApi.onTamat`.
  int _letupan = 0;

  /// Bilangan jawapan betul berturut-turut.
  ///
  /// Dipakai untuk menambah hangat pujian dan membesarkan letupan, supaya
  /// app tidak berbunyi dan berkelip sama sepanjang masa.
  int _beruntun = 0;

  /// Petunjuk "jawab dahulu" sedang dipaparkan di atas bar navigasi.
  ///
  /// Latih tubi **mewajibkan** satu jawapan bagi setiap soalan sebelum murid
  /// boleh meneruskan — tidak kisah betul atau salah (lihat [_bolehTerus]).
  /// Kerana itu butang "Seterusnya" kadang-kadang menekan tanpa bergerak, dan
  /// murid perlu tahu sebabnya. Petunjuk ini muncul di tempat matanya berada:
  /// betul-betul di atas butang yang baru ditekan, bukan sebagai `SnackBar`
  /// yang meluncur turun dari atas dan kemudian tertutup oleh papan kekunci.
  bool _galakJawab = false;

  /// Memendekkan tempoh petunjuk [galakJawab] supaya ia hilang sendiri.
  Timer? _pemasaGalakan;

  late int _saat;
  Timer? _pemasa;

  Kertas get _kertas => widget.kertas;
  List<SoalanKertas> get _soalan => _kertas.semuaSoalan;
  int get _bilangan => _soalan.length;

  @override
  void initState() {
    super.initState();
    _saat = _kertas.masaMinit * 60;
    _pemasa = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_saat > 0) _saat--;
      });
      // Had masa hanya milik **kertas percubaan**. Latih tubi tiada had masa:
      // menjalankan jam di belakang tabir untuk latihan sepuluh soalan bermakna
      // latihan yang ditinggalkan terbuka boleh "Masa tamat" lalu menghantar
      // dirinya sendiri — pengalaman yang tidak sepatutnya wujud.
      if (_saat <= 0 && !_latihTubi) {
        _pemasa?.cancel();
        _hantar(auto: true);
      }
    });
  }

  @override
  void dispose() {
    _pemasa?.cancel();
    _pemasaGalakan?.cancel();
    for (final k in _kawalan.values) {
      k.dispose();
    }
    for (final k in _kawalanBaris.values) {
      for (final baris in k) {
        baris.dispose();
      }
    }
    for (final n in _barisAktif.values) {
      n.dispose();
    }
    // Bunyi **tidak** dihentikan apabila skrin ini menyerahkan tugas kepada
    // skrin keputusan/penutup: skrin baharu memulakan nada sambutannya pada
    // bingkai pertama, dan laluan lama hanya dilupuskan selepas peralihan
    // tamat (~300 ms) — menghentikan bunyi di sini memotong nada itu separuh
    // jalan. Apabila murid meninggalkan kertas tanpa menghantar, tiada skrin
    // baharu, jadi bunyi mesti dihentikan.
    if (!_menyerahkan) Suara.instance.berhenti();
    super.dispose();
  }

  /// Benar apabila skrin ini sudah menyerahkan tugas kepada skrin lain.
  bool _menyerahkan = false;

  // --- Keadaan jawapan -----------------------------------------------------

  /// Simpan jawapan bagi satu soalan.
  ///
  /// [raikan] benar apabila jawapan ini ialah jawapan **akhir** murid untuk
  /// soalan itu (menekan "Siap" atau sekeping kad), dan hanya pada masa itu
  /// nada, pujian dan bunga api dimainkan. Semasa murid sedang menaip huruf
  /// satu demi satu, jawapannya disimpan senyap sahaja — kalau tidak, satu
  /// jawapan Jawi yang betul akan disambut bunga api ketika murid masih belum
  /// menamatkan ayatnya.
  void _simpan(SoalanKertas s, JawapanMurid jawapan, {bool raikan = true}) {
    setState(() {
      _jawapan[s.id] = jawapan;
      // Petunjuk "jawab dahulu" tidak relevan lagi — kini ada jawapan.
      _galakJawab = false;
    });
    _pemasaGalakan?.cancel();

    if (raikan) _dimuktamadkan.add(s.id);
    if (!raikan) return;

    // Pujian dan teguran dikawal oleh [_sudahDipuji] dan [_sudahDitegur] —
    // satu soalan hanya sekali disambut, walau berapa kali jawapannya
    // berubah. Tanpa kawalan itu, murid yang menekan pilihan yang sama
    // berulang kali akan mengumpul bunga api tanpa henti.
    if (s.betulPenuh(jawapan)) {
      _puji(s);
    } else if (s.lengkap(jawapan) && s.markahDiperoleh(jawapan) == 0) {
      _tegur(s);
    }
  }

  /// Adakah kertas ini **latih tubi** dan bukan kertas percubaan?
  ///
  /// Perbezaannya bukan sekadar label: latih tubi ialah tempat murid mencuba
  /// tanpa tekanan, jadi jawapan betul disambut dengan nada ceria. Semasa
  /// menjawab **kertas percubaan**, murid perlu rasa seperti sedang menjawab
  /// kertas sebenar — dan kertas sebenar tidak berbunyi setiap kali jawapan
  /// betul. Bunyi di situ hanya mengganggu tumpuan.
  bool get _latihTubi => widget.kertas.jenisSumber == 'latihan';

  /// Arahan tulisan pada kulit kertas: (Jawi, Rumi).
  ///
  /// Subjek Bahasa Arab menuntut jawapan bertanda baris dalam tulisan Arab,
  /// bukan Jawi. Kulit kertas yang menyuruh "jawab dalam tulisan Jawi" untuk
  /// subjek itu ialah arahan yang **salah** — murid yang mengikutinya menulis
  /// jawapan yang tidak boleh dimarkah.
  (String, String) get _arahanTulisan {
    final arab = _subjekKertas()?.jawapanArab ?? false;
    return arab
        ? (
            'جواب سموا سوءالن دالم توليسن عرب.',
            'Jawab semua soalan dalam tulisan Arab.',
          )
        : (
            'جواب سموا سوءالن دالم توليسن جاوي.',
            'Jawab semua soalan dalam tulisan Jawi.',
          );
  }

  /// Raikan jawapan betul — **latih tubi sahaja**.
  ///
  /// Kertas percubaan menyerupai kertas sebenar, dan kertas sebenar tiada
  /// bunga api mahupun lencana rentetan. Murid yang sedang menjawab kertas
  /// perlu rasa seperti dalam dewan peperiksaan: skrin berubah hanya dengan
  /// penanda ✓/✗ di bawah jawapannya. Perayaan di tengah kertas percubaan
  /// mengingatkannya bahawa dia sedang dinilai, dan itu yang ditakuti.
  ///
  /// Oleh itu tiada apa pun yang dikemas kini di sini melainkan latih tubi —
  /// [_letupan] dan [_beruntun] kekal `0` sepanjang kertas percubaan, jadi
  /// widget bunga api dan lencana rentetan tidak pernah dipaparkan walaupun
  /// mereka masih ada dalam pokok widget.
  ///
  /// Tiada pujian bersuara pada setiap jawapan betul dalam mana-mana mod.
  ///
  /// Ayat "Betul! Syabas!" selepas setiap soalan kelihatan mesra di atas
  /// kertas, tetapi dalam tangan ia menjadi dua masalah: ia melewatkan murid
  /// yang sedang laju menjawab, dan selepas sepuluh soalan ia menjadi bunyi
  /// latar yang tidak lagi didengar.
  ///
  /// Sebaliknya, dalam **latih tubi** sahaja, Raz bersuara apabila murid
  /// mencapai [Suara.ambangRentetan] jawapan betul berturut-turut, dan
  /// setiap kelipatan tiga selepas itu (3, 6, 9…). Pujian tiba apabila
  /// murid benar-benar konsisten, jadi ia bermakna — dan tiga ayat yang
  /// bergilir mengelakkan bunyi daripada berulang.
  ///
  /// Kertas percubaan kekal senyap sepenuhnya.
  void _puji(SoalanKertas s) {
    if (!_sudahDipuji.add(s.id)) return;
    if (!_latihTubi) return;

    setState(() {
      _beruntun++;
      _letupan++;
    });
    unawaited(Suara.instance.mainkanKesan(Suara.kesanBetul));

    // Pujian bersuara pada rentetan 3, 6, 9… sahaja. Nada ceria di atas
    // sudah mengesahkan setiap jawapan betul; suara ini menambah semangat
    // tanpa mengulanginya setiap kali.
    final ambang = Suara.ambangRentetan;
    if (_beruntun >= ambang && _beruntun % ambang == 0) {
      unawaited(
        Suara.instance.sebutKunci(
          Suara.kunciRentetan(_beruntun ~/ ambang),
        ),
      );
    }
  }

  /// Tegur dengan lembut apabila jawapan lengkap tetapi langsung tiada markah.
  ///
  /// Jawapan separa betul sengaja **dibiarkan senyap**: murid yang sudah
  /// mendapat sebahagian markah tidak perlu ditegur, dan penanda ✓/✗ serta
  /// jumlah markah di bawah sudah cukup memberitahu.
  ///
  /// Teguran bersuara hanya untuk latih tubi — semasa kertas percubaan, murid
  /// tidak sepatutnya diberitahu jawapannya salah semasa dia masih menjawab.
  void _tegur(SoalanKertas s) {
    if (!_sudahDitegur.add(s.id)) return;

    setState(() => _beruntun = 0);
    if (!_latihTubi) return;

    unawaited(Suara.instance.mainkanKesan(Suara.kesanSalah));
    unawaited(
      Suara.instance.sebutKunci(Suara.kunciCubaLagi, sandaran: Suara.teksCubaLagi),
    );
  }

  /// Bantuan suara bagi satu teks yang murid perlu baca.
  ///
  /// Bantuan ini wujud **hanya dalam latih tubi**. Kertas percubaan mesti
  /// menyerupai kertas sebenar, dan kertas sebenar tidak membacakan soalan
  /// atau pilihan jawapan kepada murid — bantuan di situ akan mengubah markah,
  /// bukan menguji pemahaman.
  ///
  /// [teks] ialah teks yang **didengar**, bukan teks yang dipaparkan: Rumi
  /// bagi subjek Jawi (enjin suara Melayu tidak boleh membaca Jawi) dan teks
  /// Arab bagi subjek Bahasa Arab. Rakaman dikongsi mengikut teks (lihat
  /// [Suara.kunciPilihan]), jadi teks yang berulang tidak berbunyi dua kali
  /// dan tidak mengambil dua kali ruang.
  void _dengar(String teks) {
    if (!_latihTubi || teks.trim().isEmpty) return;
    unawaited(Suara.instance.sebutPilihan(teks));
  }

  /// Butang dengar bagi satu teks, atau `null` apabila tiada apa yang boleh
  /// disebut — kertas percubaan, teks kosong, atau pilihan gambar (emoji).
  VoidCallback? _butangDengar(String teks) {
    if (!_latihTubi || teks.trim().isEmpty) return null;
    return () => _dengar(teks);
  }

  /// Adakah soalan ini sudah ada jawapan?
  bool _sudahJawab(SoalanKertas s) {
    final j = _jawapan[s.id];
    return switch (s.jenis) {
      JenisKertas.bulat || JenisKertas.objektif => j is JawapanPilihanKertas &&
          j.pilihan.any((p) => p >= 0),
      JenisKertas.betulSalah =>
        j is JawapanBetulSalah && j.jawapan.any((e) => e != null),
      JenisKertas.suai => j is JawapanPadan && j.padanan.isNotEmpty,
      JenisKertas.susun => j is JawapanSusun && j.susunan.isNotEmpty,
      JenisKertas.tempatKosong =>
        j is JawapanTempatKosong && j.isi.isNotEmpty,
      JenisKertas.tulis || JenisKertas.huraian =>
        j is JawapanTaip && j.teks.trim().isNotEmpty,
    };
  }

  int get _bilanganDijawab => _soalan.where(_sudahJawab).length;

  /// Adakah murid dibenarkan meninggalkan soalan semasa?
  ///
  /// Dalam **latih tubi**, setiap soalan wajib dijawab dahulu — tidak kisah
  /// betul atau salah. Ini yang menjadikan latihan berkesan: murid yang
  /// melangkapi soalan sukar berpindah kepada soalan seterusnya tanpa belajar
  /// apa-apa, dan kerana tiada siapa yang menandakannya, kesilapan itu tidak
  /// pernah dibetulkan. Dengan gate ini murid terpaksa mencuba, dan panel
  /// pembetulan terus menunjukkan jawapan betul di situ.
  ///
  /// **Kertas percubaan tidak dikunci.** Peperiksaan sebenar membenarkan
  /// murid melangkapi soalan yang sukar dan kembali kepadanya kemudian —
  /// itu sebahagian daripada kemahiran peperiksaan yang app ini mahu latih.
  bool get _bolehTerus {
    if (!_latihTubi) return true;
    final s = _soalanSemasa;
    return s != null && _sudahJawab(s);
  }

  /// Beritahu murid supaya menjawab dahulu, lalu paparkan petunjuk.
  ///
  /// Bunyi dan petunjuk visual digunakan bersama: kanak-kanak yang menekan
  /// butang yang "rosak" berasa keliru, jadi app mesti menerangkan sebabnya
  /// pada masa yang sama — bukan sekadar enggan bergerak.
  void _galakJawabSekarang() {
    if (!mounted) return;
    setState(() => _galakJawab = true);
    _pemasaGalakan?.cancel();
    _pemasaGalakan = Timer(const Duration(seconds: 5), () {
      if (mounted && _galakJawab) setState(() => _galakJawab = false);
    });
    unawaited(
      Suara.instance.sebutKunci(
        Suara.kunciJawabDulu,
        sandaran: Suara.teksJawabDulu,
      ),
    );
  }

  Paparan _paparanBagi(SoalanKertas s) => _paparan.putIfAbsent(
        s.id,
        () => Paparan.bina(
          id: s.id,
          bilanganKanan: s.pasangan.length,
          bilanganSusun: s.jenis == JenisKertas.susun
              ? (s.urutan.length > 1 ? s.urutan.length : 0)
              : 0,
          bilanganBank: s.bank.length,
        ),
      );

  TextEditingController _kawalanBagi(SoalanKertas s) => _kawalan.putIfAbsent(
        s.id,
        () {
          final j = _jawapan[s.id];
          return TextEditingController(
            text: j is JawapanTaip ? j.teks : '',
          );
        },
      );

  /// Benar apabila soalan ini dipaparkan sebagai beberapa kotak bernombor.
  ///
  /// Kertas asal memberi satu ruang bernombor bagi setiap isi yang diminta,
  /// dan data bank mengesahkannya: kesemua 153 soalan `tulis` **dan**
  /// kesemua 139 soalan `huraian` berbentuk "Jelaskan N ..." dengan tepat
  /// N isi dalam rubriknya dan N markah. Tiada satu pun daripada 292 soalan
  /// ini berupa karangan bebas yang ruangnya satu petak besar, jadi gerbang
  /// ini memakai bilangan isi dan bukan nama bahagiannya.
  ///
  /// Pemarkahan tidak berubah: semua baris digabungkan semula menjadi satu
  /// jawapan sebelum dibandingkan dengan rubrik, sama seperti skema kertas
  /// asli yang menilai keseluruhan ruang jawapan secara serentak.
  bool _berbilangBaris(SoalanKertas s) =>
      (s.jenis == JenisKertas.tulis || s.jenis == JenisKertas.huraian) &&
      s.rubrik.idea.length > 1;

  /// Pengawal bagi setiap kotak soalan berbilang baris.
  List<TextEditingController> _barisBagi(SoalanKertas s) =>
      _kawalanBaris.putIfAbsent(s.id, () {
        // Pulihkan jawapan yang sudah disimpan. Kertas ini dahulunya sentiasa
        // satu kotak, jadi teks tersimpan biasanya tiada baris baru — tetapi
        // apa-apa baris tambahan kekal disambung supaya tiada tulisan murid
        // hilang semasa pertukaran bentuk.
        final tersimpan = switch (_jawapan[s.id]) {
          JawapanTaip j => j.teks,
          _ => '',
        };
        final bahagi = tersimpan.isEmpty ? <String>[] : tersimpan.split('\n');
        final n = s.rubrik.idea.length;
        final isi = List<String>.filled(n, '');
        for (var i = 0; i < bahagi.length; i++) {
          if (i >= n) {
            isi[n - 1] = isi[n - 1].isEmpty
                ? bahagi[i]
                : '${isi[n - 1]}\n${bahagi[i]}';
          } else {
            isi[i] = bahagi[i];
          }
        }
        return [
          for (final teks in isi) TextEditingController(text: teks),
        ];
      });

  /// Notifier baris aktif bagi soalan berbilang baris.
  ValueNotifier<int?> _barisAktifBagi(SoalanKertas s) =>
      _barisAktif.putIfAbsent(s.id, () => ValueNotifier<int?>(0));

  /// Pengawal yang sedang menerima taipan daripada papan kekunci dalam app.
  ///
  /// Papan kekunci hanya mempunyai satu aliran aksara, jadi ia mesti tahu
  /// kotak mana yang hendak ditulis. Soalan satu kotak terus menggunakan
  /// [_kawalanBagi].
  TextEditingController _kawalanAktif(SoalanKertas s) {
    final baris = _kawalanBaris[s.id];
    if (baris == null || baris.isEmpty) return _kawalanBagi(s);
    final i = _barisAktif[s.id]?.value;
    return (i == null || i < 0 || i >= baris.length) ? baris.first : baris[i];
  }

  /// Teks jawapan penuh bagi soalan bertulis.
  ///
  /// Semua kotak digabungkan dengan baris baru supaya pemarkahan tetap
  /// melihat **satu** jawapan — itulah cara skema kertas asli menilainya.
  String _teksAkhir(SoalanKertas s) {
    final baris = _kawalanBaris[s.id];
    if (baris == null || baris.isEmpty) return _kawalanBagi(s).text;
    return baris.map((k) => k.text).join('\n');
  }

  // --- Papan kekunci Jawi/Arab ---------------------------------------------

  /// Soalan yang sedang dipaparkan, atau `null` di kulit dan halaman semak.
  SoalanKertas? get _soalanSemasa =>
      _halaman >= 0 && _halaman < _bilangan ? _soalan[_halaman] : null;

  /// Tulisan yang wajib digunakan oleh soalan semasa, atau `null` jika soalan
  /// ini tidak memerlukan tulisan Jawi atau Arab.
  ///
  /// Soalan bertulis UPKK **wajib** dijawab dalam tulisan Jawi — itu arahan
  /// yang tercetak pada kulit kertas sebenar. Subjek Bahasa Arab pula menuntut
  /// jawapan bertanda baris penuh. Kerana itu papan kekunci yang betul terbuka
  /// sendiri untuk soalan sebegini, tanpa menunggu murid menekan apa-apa.
  TulisanKekunci? get _tulisanDiperlukan {
    final s = _soalanSemasa;
    if (s == null) return null;
    final bertulis = switch (s.jenis) {
      JenisKertas.tulis || JenisKertas.huraian => true,
      // Soalan susun yang tidak cukup kad untuk disusun jatuh kembali kepada
      // jawapan bertulis, jadi ia pun memerlukan papan kekunci ini.
      JenisKertas.susun => s.urutan.length < 2,
      _ => false,
    };
    if (!bertulis) return null;
    return s.jawapanArab ? TulisanKekunci.arab : TulisanKekunci.jawi;
  }

  /// Hentikan bunyi yang sedang berbunyi sebaik sahaja halaman bertukar.
  ///
  /// Murid boleh menekan butang pembesar suara — sama ada membaca soalan atau
  /// jawapan betul — kemudian terus menekan "Seterusnya". Tanpa ini bunyi itu
  /// berterusan menembusi soalan seterusnya dan bertindih dengan bacaan yang
  /// baharu, dan murid tidak lagi tahu ayat mana yang sedang didengarinya.
  ///
  /// Panggil ini **hanya** apabila halaman benar-benar bertukar. Menekan
  /// "Sebelum" pada halaman pertama (butang sudah mati) atau butang galakan
  /// dalam latih tubi tidak mengubah soalan — bunyi yang sedang berjalan di
  /// situ masih relevan kepada murid. Begitu juga apabila kertas dihantar:
  /// di situ [`dispose`] sudah mengendalikannya, dan menghentikan bunyi lebih
  /// awal akan memotong nada sambutan skrin baharu, kerana laluan lama hanya
  /// dilupuskan selepas peralihan tamat.
  void _berhentiBunyiHalaman() {
    Suara.instance.berhenti();
  }

  /// Benar apabila papan kekunci Jawi/Arab dipaparkan sekarang.
  bool get _papanTerbuka {
    final s = _soalanSemasa;
    if (s == null || _tulisanDiperlukan == null) return false;
    return !_kekunciDitutup.contains(s.id);
  }

  /// Had aksara bagi **satu** kotak jawapan.
  ///
  /// Kotak bernombor sentiasa 120 aksara: ruang yang dicetak pada kertas asal
  /// mempunyai saiz yang sama bagi setiap baris tanpa mengira bahagian, dan
  /// setiap isi rubrik hanyalah satu ayat pendek. Tanpa had ini, soalan
  /// `huraian` dengan lima kotak akan menawarkan 2000 aksara — lima kali
  /// ruang yang benar-benar diperlukan.
  ///
  /// Soalan yang kekal satu petak panjang mengekalkan had lamanya: inilah
  /// ruang karangan tunggal yang memang luas.
  int _hadTaip(SoalanKertas s) {
    if (_berbilangBaris(s)) return 120;
    return s.jenis == JenisKertas.huraian ? 400 : 120;
  }

  /// Masukkan satu aksara pada kedudukan kursor.
  void _taipAksara(SoalanKertas s, String aksara) {
    final kawalan = _kawalanAktif(s);
    final teks = kawalan.text;
    final pemilihan = kawalan.selection;

    // Medan yang belum pernah disentuh tidak mempunyai kedudukan kursor yang
    // sah (-1), jadi huruf baharu ditambah di hujung teks.
    final sah = pemilihan.isValid && pemilihan.end <= teks.length;
    final dari = sah ? pemilihan.start : teks.length;
    final hingga = sah ? pemilihan.end : teks.length;

    final baharu = teks.replaceRange(dari, hingga, aksara);
    if (baharu.length > _hadTaip(s)) return;

    kawalan.value = TextEditingValue(
      text: baharu,
      selection: TextSelection.collapsed(offset: dari + aksara.length),
    );
    // Disimpan senyap: jawapan tidak hilang kalau murid terus menekan
    // "Seterusnya", tetapi bunga api hanya meletup apabila dia menekan "Siap".
    _simpan(s, JawapanTaip(baharu), raikan: false);
  }

  /// Padam satu aksara sebelum kedudukan kursor.
  void _padamAksara(SoalanKertas s) {
    final kawalan = _kawalanAktif(s);
    final teks = kawalan.text;
    if (teks.isEmpty) return;

    final pemilihan = kawalan.selection;
    final sah = pemilihan.isValid && pemilihan.end <= teks.length;
    final dari = sah ? pemilihan.start : teks.length;
    final hingga = sah ? pemilihan.end : teks.length;

    // Kursor di hujung teks (kes biasa) memadam huruf terakhir; kursor yang
    // memilih beberapa aksara memadam pilihan itu.
    final mula = dari == hingga ? (dari > 0 ? dari - 1 : 0) : dari;
    final baharu = teks.replaceRange(mula, hingga, '');

    kawalan.value = TextEditingValue(
      text: baharu,
      selection: TextSelection.collapsed(offset: mula),
    );
    _simpan(s, JawapanTaip(baharu), raikan: false);
  }

  /// Murid menekan kekunci "Siap" — jawapan disemak dan diraikan.
  void _siapTaip(SoalanKertas s) {
    // Murid sudah selesai menaip, jadi papan kekunci ditutup. Tanpa ini panel
    // pembetulan — yang muncul serta-merta apabila jawapan salah — terkurung
    // di belakang kekunci dan butang speaker jawapan betul padanya tidak
    // boleh ditekan. Murid terpaksa menyembunyikan kekunci secara manual
    // dahulu, iaitu dua ketikan yang tidak sepatutnya diperlukan.
    //
    // Medan jawapan masih boleh disentuh untuk membuka semula kekunci
    // (lihat `onSentuh`), jadi menaip semula kekal mudah.
    setState(() => _kekunciDitutup.add(s.id));
    _simpan(s, JawapanTaip(_teksAkhir(s).trim()));
  }

  // --- Hantar --------------------------------------------------------------

  /// Murid menekan "Hantar kertas" (percubaan) atau "Selesai" (latih tubi).
  ///
  /// Latih tubi **tidak** melalui sebarang dialog dan tidak pernah menanda
  /// kertas: ia bukan peperiksaan, jadi tiada "Hantar kertas?" dan tiada
  /// markah atau gred. Kertas percubaan kekal dengan pengesahan kerana di situ
  /// jawapan yang belum lengkap benar-benar hilang.
  Future<void> _hantar({bool auto = false}) async {
    _pemasa?.cancel();
    final dijumpai = _bilanganDijawab;

    if (_latihTubi) {
      if (!mounted) return;
      await _simpanRekod();
      if (!mounted) return;
      final saat = _kertas.masaMinit * 60 - _saat;
      _menyerahkan = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LatihanSelesaiScreen(
            kertas: _kertas,
            jawapan: _jawapan,
            saat: saat,
          ),
        ),
      );
      return;
    }

    if (!auto && dijumpai < _bilangan) {
      final teruskan = await showDialog<bool>(
        context: context,
        builder: (konteks) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Hantar kertas?', style: Teks.besar),
          content: Text(
            'Masih ada ${_bilangan - dijumpai} soalan belum dijawab. '
            'Kertas akan ditanda sekarang dan tidak boleh diubah lagi.',
            style: Teks.biasa,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(konteks, false),
              child: const Text('Belum'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(konteks, true),
              style: FilledButton.styleFrom(backgroundColor: Warna.utama),
              child: const Text('Hantar'),
            ),
          ],
        ),
      );
      if (teruskan != true) {
        if (mounted) setState(() {});
        return;
      }
    } else if (auto) {
      final teruskan = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (konteks) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Masa tamat', style: Teks.besar),
          content: const Text(
            'Masa menjawab 1 jam 15 minit sudah habis. Kertas akan ditanda '
            'sekarang.',
            style: Teks.biasa,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(konteks, true),
              style: FilledButton.styleFrom(backgroundColor: Warna.utama),
              child: const Text('Tanda kertas'),
            ),
          ],
        ),
      );
      if (teruskan != true) return;
    }

    if (!mounted) return;
    await _simpanRekod();
    if (!mounted) return;
    // Masa yang sama dengan rekod yang baru disimpan — kad perkongsian mesti
    // memaparkan masa yang sepadan dengan rekod dalam Kemajuan.
    final saat = _kertas.masaMinit * 60 - _saat;
    _menyerahkan = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => KeputusanScreen(
          kertas: _kertas,
          jawapan: _jawapan,
          saat: saat,
        ),
      ),
    );
  }

  /// Rekod percubaan ini dan majukan giliran soalan subjek.
  ///
  /// Rekod latih tubi ditandakan [RekodPercubaan.latihan] supaya ia tidak
  /// diambil kira sebagai markah terbaik subjek atau purata percubaan — tetapi
  /// ia tetap disimpan, supaya rentetan hari ulang kaji tidak terputus.
  Future<void> _simpanRekod() async {
    final masa = _kertas.masaMinit * 60 - _saat;
    await Kemajuan.instance.simpanPercubaan(
      RekodPercubaan(
        tarikh: DateTime.now(),
        subjekId: _kertas.subjekId,
        kertasId: _kertas.id,
        tajuk: _kertas.tajuk,
        markah: _kertas.markahDiperoleh(_jawapan),
        markahPenuh: _kertas.markahTersedia,
        saat: masa,
        markahBahagian: {
          for (final b in _kertas.bahagian)
            b.nama: _kertas.markahBahagian(b.nama, _jawapan),
        },
        latihan: _latihTubi,
      ),
    );
    for (final s in _soalan) {
      await Kemajuan.instance.rekodJawapan(
        soalanId: s.id,
        betul: s.betulPenuh(_jawapan[s.id]),
      );
    }
    await Kemajuan.instance.majukanGiliran(_kertas.subjekId);
  }

  // --- Bina ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Latih tubi bukan kertas: murid boleh keluar bila-bila masa tanpa
      // ditanya apa-apa. Prompt "Keluar kertas?" hanya masuk akal untuk kertas
      // percubaan, kerana di situlah jawapan yang separuh siap akan hilang.
      canPop: _latihTubi,
      onPopInvokedWithResult: (keluar, _) async {
        if (keluar) return;
        final pengemudi = Navigator.of(context);
        final keluarTanpaSimpan = await showDialog<bool>(
          context: context,
          builder: (konteks) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Keluar kertas?', style: Teks.besar),
            content: const Text(
              'Jawapan yang telah ditulis tidak akan disimpan.',
              style: Teks.biasa,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(konteks, false),
                child: const Text('Terus menjawab'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(konteks, true),
                style: FilledButton.styleFrom(backgroundColor: Warna.salah),
                child: const Text('Keluar'),
              ),
            ],
          ),
        );
        if (keluarTanpaSimpan == true && mounted) pengemudi.pop();
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Warna.latarSkrin,
            appBar: _barAtas(),
            // Semasa murid menjawab kertas — bukan latih tubi — baris Rumi
            // ditanggalkan supaya paparan menyerupai kertas UPKK sebenar, yang
            // 100% Jawi. Halaman semak dan skrin keputusan kekal menunjukkan
            // Rumi kerana di situlah murid belajar daripada kesilapannya.
            body: _halaman == -1
                ? _kulit()
                : _halaman >= _bilangan
                    ? _semak()
                    : TunjukRumi(tunjuk: _latihTubi, child: _halamanSoalan()),
            bottomNavigationBar: _barBawah(),
          ),
          // Bunga api dilukis di atas kertas tetapi tidak menangkap sentuhan,
          // jadi murid boleh terus menjawab semasa ia berbunga.
          if (_letupan > 0)
            Positioned.fill(
              child: BungaApi(
                key: ValueKey(_letupan),
                letupan: (2 + _beruntun).clamp(2, 5),
                onTamat: () {
                  if (mounted) setState(() => _letupan = 0);
                },
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _barAtas() {
    final minit = _saat ~/ 60;
    final detik = _saat % 60;
    final genting = _saat <= 300;
    return AppBar(
      backgroundColor: Warna.utama,
      foregroundColor: Colors.white,
      elevation: 0,
      // Latih tubi boleh ditinggalkan bila-bila masa — butang X menjadikannya
      // satu ketukan, bukan satu tekaan. Kertas percubaan kekal dengan anak
      // panah kembali yang bertanya "Keluar kertas?" dahulu.
      leading: _latihTubi
          ? IconButton(
              tooltip: 'Keluar latihan',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_kertas.tajuk, style: Teks.biasa.copyWith(color: Colors.white)),
          Text(
            _halaman < 0
                ? 'Kulit kertas'
                : _halaman >= _bilangan
                    ? 'Semak jawapan'
                    : 'Soalan ${_halaman + 1} daripada $_bilangan',
            style: Teks.label.copyWith(color: Colors.white70),
          ),
        ],
      ),
      actions: [
        // Lencana rentetan: ganjaran yang berterusan sepanjang kertas, supaya
        // murid yang sudah sepuluh soalan betul rasa usahanya dikira.
        if (_beruntun >= 2)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 16,
                  color: Color(0xFFFF7043),
                ),
                const SizedBox(width: 3),
                Text(
                  '$_beruntun',
                  style: Teks.biasa.copyWith(
                    color: Warna.utama,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        // Jam undur hanya untuk kertas percubaan. Latih tubi tiada had masa
        // rasmi, jadi jam yang berdetik di atasnya cuma menambah tekanan yang
        // tidak perlu.
        if (!_latihTubi)
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: genting ? Warna.salah : Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  '$minit:${detik.toString().padLeft(2, '0')}',
                  style: Teks.biasa.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget? _barBawah() {
    if (_halaman < 0) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _bilangan == 0
                ? null
                : () {
                    _berhentiBunyiHalaman();
                    setState(() => _halaman = 0);
                  },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text(
              'Mula menjawab',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Warna.utama,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      );
    }

    final s = _soalanSemasa;
    final tulisan = _tulisanDiperlukan;
    final terbuka = _papanTerbuka && s != null && tulisan != null;

    // Papan kekunci Jawi/Arab berada di bawah bar navigasi, iaitu di tempat
    // papan kekunci telefon biasa berada. Murid menaip, kemudian terus menekan
    // "Seterusnya" yang terletak betul-betul di atasnya.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _barNavigasi(adaKekunci: terbuka),
        if (terbuka) ...[
          _kepalaKekunci(s, tulisan),
          PapanKekunciTulisan(
            key: ValueKey('kekunci-${s.id}'),
            tulisan: tulisan,
            warna: _subjekKertas()?.warna ?? Warna.utama,
            onAksara: (aksara) => _taipAksara(s, aksara),
            onHapus: () => _padamAksara(s),
            onSelesai: () => _siapTaip(s),
          ),
        ],
      ],
    );
  }

  /// Kepala papan kekunci — nama tulisan dan butang sembunyikan.
  ///
  /// Papan ini sengaja boleh disembunyikan: pada telefon kecil, soalan
  /// `huraian` yang panjang memerlukan seluruh skrin. Menyentuh medan jawapan
  /// akan membukanya semula.
  Widget _kepalaKekunci(SoalanKertas s, TulisanKekunci tulisan) {
    return Material(
      color: const Color(0xFFE4E4E9),
      child: InkWell(
        onTap: () => setState(() => _kekunciDitutup.add(s.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 10, 2),
          child: Row(
            children: [
              const Icon(
                Icons.keyboard_alt_outlined,
                size: 16,
                color: Colors.black54,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Papan kekunci ${tulisan.nama} — ketik huruf, '
                  'kemudian tekan سياڤ',
                  style: Teks.label.copyWith(color: Colors.black54),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Petunjuk kecil di atas bar navigasi apabila "Seterusnya" ditekan awal.
  ///
  /// Ia berwarna pink lembut, bukan merah: ini bukan kesalahan, hanya satu
  /// langkah yang belum boleh diambil. Ayatnya pendek kerana penerima ialah
  /// kanak-kanak Tahun 5 yang baru sahaja menekan butang.
  Widget _petunjukJawabDulu() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Warna.utamaLembut,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Warna.utamaMuda),
        ),
        child: Row(
          children: [
            const Icon(Icons.edit_note_rounded, size: 18, color: Warna.utama),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Jawab soalan ini dahulu.',
                style: Teks.biasa.copyWith(
                  color: Warna.utama,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _barNavigasi({bool adaKekunci = false}) {
    final terakhir = _halaman >= _bilangan;
    final isi = Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_galakJawab) ...[
            _petunjukJawabDulu(),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _halaman <= 0
                      ? null
                      : () {
                          _berhentiBunyiHalaman();
                          setState(() => _halaman--);
                        },
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: Text(
                    'Sebelum',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Teks.biasa.copyWith(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Warna.utama,
                    minimumSize: const Size.fromHeight(50),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    side: const BorderSide(color: Warna.utama),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Kedua-dua butang berkongsi lebar yang sama. Butang "Sebelum"
              // yang lebih kecil daripada "Seterusnya" membuatkan perkataan
              // "Sebelum" terpotong pada telefon kecil, dan kanak-kanak
              // teragak-agak menekan butang yang kelihatan separuh siap.
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    if (terakhir) {
                      _hantar();
                    } else if (!_bolehTerus) {
                      // Latih tubi menuntut satu jawapan bagi setiap soalan
                      // sebelum murid bergerak maju — lihat [_bolehTerus].
                      _galakJawabSekarang();
                    } else {
                      _berhentiBunyiHalaman();
                      setState(() {
                        _halaman++;
                        _galakJawab = false;
                      });
                    }
                  },
                  icon: Icon(
                    terakhir
                        ? Icons.done_all_rounded
                        : Icons.chevron_right_rounded,
                  ),
                  label: Text(
                    terakhir
                        ? (_latihTubi ? 'Selesai' : 'Hantar kertas')
                        : 'Seterusnya',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Teks.biasa.copyWith(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: terakhir ? Warna.betul : Warna.utama,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (adaKekunci) {
      // Papan kekunci di bawah sudah mengendalikan ruang selamat peranti,
      // jadi bar ini tidak perlu menambahnya lagi.
      return Container(
        color: Warna.latarSkrin,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1, color: Color(0xFFE0E0E4)),
            isi,
          ],
        ),
      );
    }
    return SafeArea(child: isi);
  }

  // --- Kulit kertas --------------------------------------------------------

  Widget _kulit() {
    final subjek = _subjekKertas();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  color: Warna.utama,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  children: [
                    Text(
                      'اولڠ کاجي UPKK',
                      textDirection: TextDirection.rtl,
                      style: Teks.jawi.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'ULANGKAJI UPKK',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // Kulit kertas mesti menyebut jenisnya sendiri: sebelum
                      // ini setiap kulit berkata "Percubaan", jadi murid yang
                      // membuka latih tubi sepuluh soalan nampak kulit kertas
                      // peperiksaan penuh.
                      _latihTubi
                          ? 'Latih tubi • Ulang kaji pantas'
                          : 'Percubaan • Format Ujian Penilaian Kelas '
                              'Al-Quran dan Fardu Ain',
                      textAlign: TextAlign.center,
                      style: Teks.label.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                child: Column(
                  children: [
                    _barisKulit('SUBJEK', subjek?.nama ?? _kertas.subjekId),
                    _barisKulit('KOD', subjek?.kod ?? '—'),
                    // Latih tubi bukan kertas peperiksaan, jadi ia tiada jadual
                    // masa rasmi. Memaparkan "1 jam 15 minit" di atas latihan
                    // sepuluh soalan hanya mengelirukan.
                    if (!_latihTubi) _barisKulit('MASA', FormatUpkk.masaTeks),
                    // Latih tubi bukan kertas: tiada markah untuk dikira, jadi
                    // baris ini hanya mengelirukan ("10 markah (15 tersedia)").
                    if (!_latihTubi)
                      _barisKulit(
                        'MARKAH',
                        '${_kertas.markahPenuh} markah'
                            '${_kertas.markahTersedia != _kertas.markahPenuh ? ' (${_kertas.markahTersedia} tersedia)' : ''}',
                      ),
                    _barisKulit('SOALAN', '$_bilangan soalan'),
                    const SizedBox(height: 14),
                    const Divider(color: Warna.garisKertas),
                    const SizedBox(height: 10),
                    // Arahan tulisan mengikut subjek: kertas Bahasa Arab yang
                    // menyuruh murid "jawab dalam tulisan Jawi" ialah arahan
                    // yang salah, dan murid yang mengikutinya kehilangan markah.
                    Dwibahasa(
                      jawi: _arahanTulisan.$1,
                      rumi: _arahanTulisan.$2,
                      gayaJawi: Teks.jawiKecil,
                      selaras: TextAlign.center,
                    ),
                    // Peringatan "jangan jawab dalam buku" ialah arahan pengawas
                    // peperiksaan, bukan sesuatu yang boleh dilakukan pada
                    // telefon. Ia dikekalkan pada kertas percubaan kerana kertas
                    // itu meniru kulit kertas sebenar, dan dibuang pada latih
                    // tubi.
                    if (!_latihTubi) ...[
                      const SizedBox(height: 8),
                      const Dwibahasa(
                        jawi: 'تياد سوءالن يڠ بوليه دجواب دالم بوكو اين.',
                        rumi: 'Kertas ini tidak boleh dijawab dalam buku.',
                        gayaJawi: Teks.jawiKecil,
                        selaras: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Warna.latarNota,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Warna.tepiNota, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _latihTubi
                                ? Icons.lightbulb_outline_rounded
                                : Icons.schedule_rounded,
                            color: Warna.tepiNota,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _latihTubi
                                  ? 'Latih tubi tidak mengubah markah terbaik '
                                      'subjek anda. Ini masa untuk mencuba — '
                                      'sebelum menjawab kertas percubaan.'
                                  : 'Masa menjawab bermula sebaik anda tekan '
                                      '"Mula menjawab". Bersedia?',
                              style: Teks.label.copyWith(height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Maskot(saiz: 72, mood: MoodMaskot.fikir),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _kertas.sumber,
                            style: Teks.label.copyWith(color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _jadualBahagian(),
      ],
    );
  }

  Subjek? _subjekKertas() {
    for (final s in _petaSubjek) {
      if (s.id == _kertas.subjekId) return s;
    }
    return null;
  }

  /// Jadual bahagian dan markah, seperti nota pada kulit kertas sebenar.
  Widget _jadualBahagian() {
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
          const Text('Bahagian kertas ini', style: Teks.sederhana),
          const SizedBox(height: 10),
          for (final b in _kertas.bahagian)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Warna.utamaLembut,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      b.nama,
                      style: Teks.sederhana.copyWith(color: Warna.utama),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${b.soalan.length} soalan',
                          style: Teks.biasa.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (!_latihTubi)
                          Text(
                            '${b.markah} markah',
                            style: Teks.label.copyWith(color: Colors.black54),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: b.markah / FormatUpkk.jumlahMarkah,
                        minHeight: 7,
                        backgroundColor: Warna.utamaLembut,
                        valueColor:
                            const AlwaysStoppedAnimation(Warna.utamaMuda),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _barisKulit(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: Teks.label.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.black54,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Expanded(
            child: Text(
              nilai,
              style: Teks.biasa.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // --- Halaman soalan ------------------------------------------------------

  Widget _halamanSoalan() {
    final s = _soalan[_halaman];
    final subjek = _subjekKertas();
    final warna = subjek?.warna ?? Warna.utama;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _jalurBahagian(s, warna),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: warna.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: warna,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '${s.nombor}.',
                      style: Teks.biasa.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _latihTubi
                        ? const SizedBox.shrink()
                        : Text(
                            '${s.markahBolehDapat} markah',
                            style: Teks.label.copyWith(
                              color: Colors.black54,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  // Bantuan suara soalan — latih tubi sahaja. Murid yang belum
                  // lancar membaca Jawi mendengar soalan sebelum menjawab;
                  // semasa kertas percubaan butang ini tiada, kerana kertas
                  // sebenar tidak membacakan soalan.
                  if (_latihTubi)
                    IconButton(
                      tooltip: 'Dengar soalan',
                      onPressed: () => Suara.instance.sebutKunci(
                        Suara.kunciSoalan(s.id),
                        sandaran: s.rumi.isEmpty ? s.soalan : s.rumi,
                      ),
                      icon: Icon(Icons.volume_up_rounded, color: warna),
                    ),
                ],
              ),
              if (s.soalan.isNotEmpty) ...[
                const SizedBox(height: 8),
                Dwibahasa(jawi: s.soalan, rumi: s.rumi),
              ],
              const SizedBox(height: 16),
              _badanSoalan(s, warna),
              // Pembetulan — latih tubi sahaja (lihat [_perluPembetulan]).
              if (_perluPembetulan(s)) ...[
                const SizedBox(height: 14),
                _pembetulan(s),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Jalur bahagian — ditulis seperti kepala bahagian pada kertas sebenar.
  Widget _jalurBahagian(SoalanKertas s, Color warna) {
    final format = _formatBahagian(s.bahagian);
    final bahagian = _kertas.bahagianBernama(s.bahagian);
    final arahan = format?.arahan ?? bahagian?.arahan ?? '';
    final arahanRumi = format?.arahanRumi ?? bahagian?.arahanRumi ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Warna.kepalaKertas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Warna.garisKertas, width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'بهاضين',
                textDirection: TextDirection.rtl,
                style: Teks.jawiKecil.copyWith(color: Colors.black87),
              ),
              const SizedBox(width: 6),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: warna,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.bahagian,
                  style: Teks.biasa.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Markah bahagian di kanan. Ia dibalut `FittedBox` supaya teks
              // Jawi yang lebar tidak melimpah keluar jalur pada telefon
              // sempit — lebih baik ia mengecil sedikit daripada terpotong.
              // Latih tubi tidak memaparkan markah langsung.
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _latihTubi
                      ? const SizedBox.shrink()
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '﴾ ${format?.markah ?? bahagian?.markah ?? 0} مرکه ﴿',
                            textDirection: TextDirection.rtl,
                            style: Teks.jawiKecil.copyWith(
                              color: Colors.black87,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (arahan.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: Warna.garisKertas),
            const SizedBox(height: 8),
            Dwibahasa(
              jawi: arahan,
              rumi: arahanRumi,
              gayaJawi: Teks.jawiKecil,
              selaras: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  BahagianFormat? _formatBahagian(String nama) {
    final subjek = _subjekKertas();
    if (subjek == null) return null;
    for (final b in subjek.bahagian) {
      if (b.nama == nama) return b;
    }
    return null;
  }

  // --- Pembetulan latih tubi -----------------------------------------------

  /// Benar apabila soalan ini perlu memaparkan **pembetulan**.
  ///
  /// Ibu bapa meminta maklum balas pembetulan dalam latih tubi: tanda ✗ semata
  /// — mata memberitahu murid dia salah, tetapi tidak memberi jalan untuk
  /// membetulkan diri. Panel ini tiada dalam kertas percubaan — di situ jawapan
  /// betul hanya dibuka apabila kertas dihantar, supaya murid tidak boleh
  /// membetulkan diri sambil diperiksa.
  ///
  /// Panel muncul hanya apabila jawapan sudah **dimuktamadkan** dan lengkap
  /// tetapi belum betul sepenuhnya — jawapan separa yang sedang dibina tidak
  /// patut didedahkan.
  bool _perluPembetulan(SoalanKertas s) {
    if (!_latihTubi || !_dimuktamadkan.contains(s.id)) return false;

    final jawapan = _jawapan[s.id];
    if (jawapan == null || s.betulPenuh(jawapan)) return false;

    // `susun` tiada saat "selesai" (lihat `SoalanKertas.lengkap`): murid
    // mengalihkan kad sehingga dia berpuas hati. Maka pembetulan menunggu
    // sehingga semua kad sudah berada pada tempatnya.
    if (s.jenis == JenisKertas.susun) {
      return jawapan is JawapanSusun &&
          jawapan.susunan.length == s.urutan.length;
    }
    return s.lengkap(jawapan);
  }

  /// Panel jawapan betul di bawah ruang jawapan.
  ///
  /// Rupanya sama dengan kad nota penerangan yang sedia ada dalam app (latar
  /// krim, tepi amber) supaya ia kelihatan seperti nota guru, bukan seperti
  /// satu lagi kegagalan berwarna merah.
  Widget _pembetulan(SoalanKertas s) {
    final teks = _teksPembetulan(s);
    if (teks.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Warna.latarNota,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Warna.tepiNota, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                size: 18,
                color: Warna.tepiNota,
              ),
              const SizedBox(width: 6),
              // Dibungkus `Expanded` supaya baris ini menyimpul dan tidak
              // melimpah keluar panel pada telefon sempit — panel pembetulan
              // lebih penting daripada barisan tajuk yang kemas.
              Expanded(
                child: Text(
                  'Pembetulan — jawapan sebenar',
                  style: Teks.label.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              // Dengar jawapan betul. Butang ini muncul hanya apabila ada teks
              // yang boleh dibacakan (lihat [_teksPembetulanDengar]).
              //
              // Ia sengaja **tidak** membacakan sendiri: senarai seperti
              // sepuluh malaikat mengambil masa agak panjang, dan murid yang
              // sudah nampak jawapannya tidak perlu mendengarnya. Memberi
              // kawalan kepada murid juga selari dengan butang speaker pada
              // setiap pilihan jawapan.
              if (_teksPembetulanDengar(s) != null)
                IconButton(
                  tooltip: 'Dengar jawapan betul',
                  onPressed: () => _dengar(_teksPembetulanDengar(s)!),
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    size: 22,
                    color: Warna.utama,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (final baris in teks.split('\n'))
            if (baris.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  baris.trim(),
                  style: Teks.biasa.copyWith(height: 1.4),
                ),
              ),
        ],
      ),
    );
  }

  /// Teks jawapan betul untuk panel pembetulan.
  ///
  /// Soalan bertulis memakai **jawapan contoh** dahulu. Jika bank tiada
  /// jawapan contoh (soalan huraian dinilai dengan rubrik), idea rubrik yang
  /// dipaparkan — sekurang-kurangnya murid nampak perkara apa yang sepatutnya
  /// ada dalam jawapannya, bukan sekadar "salah".
  String _teksPembetulan(SoalanKertas s) {
    final contoh = s.jawapanPenuhTeks.trim();
    if (contoh.isNotEmpty) return contoh;
    return s.rubrik.idea.map((i) => '• ${i.maksud}').join('\n').trim();
  }

  /// Teks pembetulan yang **boleh dibacakan** — medan Rumi, atau medan Arab
  /// bagi subjek Bahasa Arab.
  ///
  /// Hanya soalan **bertulis** (`tulis` dan `huraian`) yang mempunyai teks
  /// di sini. Soalan lain sengaja dilangkau kerana jawapan betulnya masih
  /// terpapar di skrin dengan butang speaker sendiri — menambah butang kedua
  /// pada panel pembetulan hanya mengulang bunyi yang murid sudah boleh
  /// dapat, sambil memaksa app membundel ratusan klip yang hampir serupa.
  ///
  /// Sebaliknya, jawapan contoh bagi soalan bertulis **tiada** klip langsung
  /// (ia dijana daripada medan `jawapanContoh`), jadi butang ini ialah satu-
  /// satunya cara murid mendengar jawapan yang sepatutnya ditulisnya.
  ///
  /// `null` apabila tiada teks yang boleh dibacakan.
  String? _teksPembetulanDengar(SoalanKertas s) {
    if (s.jenis != JenisKertas.tulis && s.jenis != JenisKertas.huraian) {
      return null;
    }
    final dengar = s.jawapanPenuhDengar.trim();
    return dengar.isEmpty ? null : dengar;
  }

  // --- Badan jawapan mengikut jenis soalan ---------------------------------

  Widget _badanSoalan(SoalanKertas s, Color warna) {
    return switch (s.jenis) {
      JenisKertas.bulat || JenisKertas.objektif => _pilihan(s, warna),
      JenisKertas.betulSalah => _betulSalah(s, warna),
      JenisKertas.suai => _padan(s, warna),
      JenisKertas.susun => _susun(s, warna),
      JenisKertas.tempatKosong => _tempatKosong(s, warna),
      JenisKertas.tulis || JenisKertas.huraian => _taip(s, warna),
    };
  }

  /// Bulatkan jawapan yang betul — satu pilihan bagi setiap item.
  Widget _pilihan(SoalanKertas s, Color warna) {
    final jawapan = _jawapan[s.id];
    final dipilih = jawapan is JawapanPilihanKertas
        ? jawapan.pilihan
        : List<int>.filled(s.item.length, -1);
    final huruf = s.jawapanArab
        ? const ['ا', 'ب', 'ج', 'د']
        : const ['A', 'B', 'C', 'D'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < s.item.length; i++) ...[
          if (s.item.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '(${i + 1})',
                      style: Teks.label.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Dwibahasa(
                      jawi: s.item[i].teks,
                      rumi: s.item[i].rumi,
                      gayaJawi: Teks.jawiKecil,
                    ),
                  ),
                  // Ayat kecil ini ialah soalan sebenar bagi soalan berbilang
                  // item — murid perlu mendengarnya sebelum memilih jawapan.
                  if (_latihTubi &&
                      (s.jawapanArab ? s.item[i].teks : s.item[i].rumi)
                          .trim()
                          .isNotEmpty)
                    IconButton(
                      tooltip: 'Dengar soalan ini',
                      onPressed: () => _dengar(
                        s.jawapanArab ? s.item[i].teks : s.item[i].rumi,
                      ),
                      iconSize: 20,
                      visualDensity: VisualDensity.compact,
                      color: warna,
                      icon: const Icon(Icons.volume_up_rounded),
                    ),
                ],
              ),
            ),
          for (var j = 0; j < s.item[i].pilihan.length; j++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ButangPilihan(
                huruf: huruf.length > j ? huruf[j] : '${j + 1}',
                teks: s.item[i].pilihan[j],
                rumi: i < s.item.length &&
                        s.item[i].pilihanRumi.length > j
                    ? s.item[i].pilihanRumi[j]
                    : null,
                warna: warna,
                keadaan: dipilih.length > i && dipilih[i] == j
                    ? KeadaanPilihan.dipilih
                    : KeadaanPilihan.biasa,
                onDengar: _butangDengar(
                  s.jawapanArab
                      ? s.item[i].pilihan[j]
                      : (i < s.item.length &&
                              s.item[i].pilihanRumi.length > j
                          ? s.item[i].pilihanRumi[j]
                          : ''),
                ),
                onPilih: () {
                  final baharu = List<int>.from(dipilih);
                  while (baharu.length < s.item.length) {
                    baharu.add(-1);
                  }
                  baharu[i] = j;
                  _simpan(s, JawapanPilihanKertas(baharu));
                },
              ),
            ),
          if (i < s.item.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }

  /// Tandakan betul (✓) atau salah (✗).
  Widget _betulSalah(SoalanKertas s, Color warna) {
    final jawapan = _jawapan[s.id];
    final dipilih = jawapan is JawapanBetulSalah
        ? jawapan.jawapan
        : List<bool?>.filled(s.item.length, null);
    return PapanBetulSalah(
      pernyataan: [for (final i in s.item) i.teks],
      rumiPernyataan: [for (final i in s.item) i.rumi],
      jawapan: dipilih,
      warna: warna,
      onDengar: _latihTubi
          ? (i) => _dengar(s.jawapanArab ? s.item[i].teks : s.item[i].rumi)
          : null,
      onJawab: (i, nilai) {
        final baharu = List<bool?>.from(dipilih);
        while (baharu.length < s.item.length) {
          baharu.add(null);
        }
        baharu[i] = nilai;
        _simpan(s, JawapanBetulSalah(baharu));
      },
    );
  }

  /// Padankan item kiri dengan item kanan.
  Widget _padan(SoalanKertas s, Color warna) {
    final paparan = _paparanBagi(s);
    final jawapan = _jawapan[s.id];
    final padanan = jawapan is JawapanPadan ? jawapan.padanan : <int, int>{};

    return PapanPadan(
      kiri: [for (final p in s.pasangan) p.kiri],
      kanan: [
        for (final asal in paparan.kanan) s.pasangan[asal].kanan,
      ],
      indeksKanan: paparan.kanan,
      padanan: padanan,
      warna: warna,
      terpilih: _padanTerpilih[s.id],
      rumiKiri: [for (final p in s.pasangan) p.kiriRumi],
      rumiKanan: [
        for (final asal in paparan.kanan) s.pasangan[asal].kananRumi,
      ],
      // Latih tubi sahaja: murid boleh mendengar setiap item kiri dan kanan
      // sebelum memadankannya. Indeks yang dihantar ialah indeks **asal**,
      // supaya teks yang disebut sepadan dengan teks yang dipaparkan.
      onDengarKiri: _latihTubi
          ? (i) => _dengar(s.pasangan[i].kiriRumi)
          : null,
      onDengarKanan: _latihTubi
          ? (asal) => _dengar(s.pasangan[asal].kananRumi)
          : null,
      onPilihKiri: (i) => setState(() => _padanTerpilih[s.id] = i),
      onPilihKanan: (asal) {
        final kiri = _padanTerpilih[s.id];
        if (kiri == null) return;
        final baharu = Map<int, int>.from(padanan);
        // Satu item kanan hanya boleh dipakai sekali — pilih semula jika perlu.
        baharu.removeWhere((_, kanan) => kanan == asal);
        baharu[kiri] = asal;
        _padanTerpilih[s.id] = null;
        _simpan(s, JawapanPadan(baharu));
      },
    );
  }

  /// Susun item menjadi ayat yang sempurna.
  Widget _susun(SoalanKertas s, Color warna) {
    if (s.urutan.length < 2) {
      return _taip(s, warna);
    }
    final paparan = _paparanBagi(s);
    final jawapan = _jawapan[s.id];
    final susunan = jawapan is JawapanSusun && jawapan.susunan.length == s.urutan.length
        ? jawapan.susunan
        : paparan.susun;

    String teksPada(int indeksAsal) => indeksAsal < s.urutan.length
        ? s.urutan[indeksAsal]
        : '';
    String rumiPada(int indeksAsal) =>
        indeksAsal < s.urutanRumi.length ? s.urutanRumi[indeksAsal] : '';

    return PapanSusun(
      item: [for (final asal in susunan) teksPada(asal)],
      rumiItem: [for (final asal in susunan) rumiPada(asal)],
      warna: warna,
      // Indeks paparan ditukar kembali kepada indeks asal: kad boleh disusun
      // semula, dan teks yang disebut mesti ikut kad yang ditekan.
      onDengar: _latihTubi
          ? (i) {
              if (i >= 0 && i < susunan.length) _dengar(rumiPada(susunan[i]));
            }
          : null,
      onSusun: (lama, baru) {
        final baharu = List<int>.from(susunan);
        final dipindah = baharu.removeAt(lama);
        baharu.insert(baru, dipindah);
        _simpan(s, JawapanSusun(baharu));
      },
    );
  }

  /// Isi tempat kosong dengan perkataan daripada bank.
  Widget _tempatKosong(SoalanKertas s, Color warna) {
    final paparan = _paparanBagi(s);
    final jawapan = _jawapan[s.id];
    final isi = jawapan is JawapanTempatKosong
        ? jawapan.isi
        : <int, int>{};

    return PapanTempatKosong(
      ayat: [for (final i in s.item) i.teks],
      rumiAyat: [for (final i in s.item) i.rumi],
      bank: [for (final asal in paparan.bank) s.bank[asal]],
      rumiBank: [
        for (final asal in paparan.bank)
          asal < s.bankRumi.length ? s.bankRumi[asal] : '',
      ],
      indeksBank: paparan.bank,
      isi: isi,
      warna: warna,
      // Latih tubi sahaja: ayat dan setiap perkataan bank boleh didengar.
      onDengarAyat: _latihTubi
          ? (i) => _dengar(
                s.jawapanArab
                    ? s.item[i].teks
                    : (i < s.item.length ? s.item[i].rumi : ''),
              )
          : null,
      onDengarKata: _latihTubi
          ? (asal) => _dengar(
                asal < s.bankRumi.length ? s.bankRumi[asal] : '',
              )
          : null,
      onIsi: (kosong, asal) {
        final baharu = Map<int, int>.from(isi);
        baharu.removeWhere((_, nilai) => nilai == asal);
        baharu[kosong] = asal;
        _simpan(s, JawapanTempatKosong(baharu));
      },
      onKosongkan: (kosong) {
        final baharu = Map<int, int>.from(isi);
        baharu.remove(kosong);
        _simpan(s, JawapanTempatKosong(baharu));
      },
    );
  }

  /// Jawapan bertulis.
  ///
  /// Medan ini **baca sahaja**: papan kekunci telefon tidak boleh ditukar
  /// kepada Jawi, jadi membiarkannya terbuka hanya menutup separuh skrin
  /// dengan papan kekunci Latin yang tidak berguna. Jawapan ditaip melalui
  /// [PapanKekunciTulisan] yang terbuka sendiri di bawah halaman ini.
  ///
  /// **Markah tidak dipaparkan dalam kertas percubaan.** Papan ini hanya
  /// menerima [markah] dalam latih tubi. Dalam peperiksaan rasmi murid tidak
  /// pernah melihat markahnya semasa menjawab — kalau setiap baris jawapan
  /// serta-merta menjawab "3/5, isi ini belum ada", murid akan terus menulis
  /// sehingga nombor itu penuh, dan yang diuji menjadi teka-teki, bukan
  /// pengetahuan. Kertas yang ditandakan hanya selepas dihantar.
  Widget _taip(SoalanKertas s, Color warna) {
    final jawapan = _jawapan[s.id];
    final berbilang = _berbilangBaris(s);
    return PapanTaip(
      // Soalan satu baris menggunakan `kawalan` biasa; bagi soalan berbilang
      // baris widget memakai `baris` dan mengabaikan `kawalan`.
      kawalan: _kawalanBagi(s),
      baris: berbilang ? _barisBagi(s) : null,
      barisAktif: berbilang ? _barisAktifBagi(s) : null,
      warna: warna,
      rubrik: s.rubrik,
      lumpuh: false,
      // Teks diambil daripada semua kotak dan bukan daripada medan yang
      // dihantar, kerana dalam mod berbilang baris tiada satu medan pun yang
      // mewakili jawapan penuh.
      onHantar: (_) => _simpan(s, JawapanTaip(_teksAkhir(s).trim())),
      markah: _latihTubi &&
              jawapan is JawapanTaip &&
              jawapan.teks.trim().isNotEmpty
          ? Pemarkah.semak(s.rubrik, jawapan.teks)
          : null,
      had: _hadTaip(s),
      bacaSahaja: true,
      gayaTaip: Teks.jawiTaip.copyWith(fontSize: 22),
      bayang: s.jawapanArab
          ? 'اُكْتُبْ جَوَابَكَ هُنَا…'
          : 'توليس جوابن مق د سيني…',
      // Menyentuh medan membuka semula papan kekunci yang ditutup tadi —
      // supaya murid tidak terperangkap tanpa jalan untuk menulis.
      onSentuh: () => setState(() => _kekunciDitutup.remove(s.id)),
    );
  }

  // --- Semak sebelum hantar ------------------------------------------------

  Widget _semak() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            const Maskot(saiz: 84, mood: MoodMaskot.biasa),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Semak jawapan', style: Teks.tajuk),
                  const SizedBox(height: 4),
                  Text(
                    '$_bilanganDijawab daripada $_bilangan soalan sudah dijawab.',
                    style: Teks.biasa.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final b in _kertas.bahagian) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _lencanaBahagian(b.nama),
                    const SizedBox(width: 10),
                    Text(
                      'Bahagian ${b.nama}',
                      style: Teks.sederhana,
                    ),
                    const Spacer(),
                    Text(
                      '${b.soalan.where(_sudahJawab).length}/${b.soalan.length}',
                      style: Teks.label.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in b.soalan)
                      _CipSoalan(
                        nombor: s.nombor,
                        dijawab: _sudahJawab(s),
                        warna: Warna.utama,
                        onTap: () {
                          _berhentiBunyiHalaman();
                          setState(() => _halaman = _soalan.indexOf(s));
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _lencanaBahagian(String nama) => Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Warna.utamaLembut,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          nama,
          style: Teks.sederhana.copyWith(color: Warna.utama, fontSize: 16),
        ),
      );
}

/// Peta subjek untuk mendapatkan warna dan kod — dimuatkan oleh `BankKertas`.
/// Disimpan sebagai senarai kosong jika bank belum dimuatkan, supaya skrin
/// tetap boleh dibina semasa ujian.
List<Subjek> _petaSubjek = const [];

/// Tetapkan senarai subjek untuk skrin kertas.
///
/// Dipanggil oleh `main.dart` selepas bank soalan dimuatkan.
void tetapkanSubjekKertas(List<Subjek> subjek) => _petaSubjek = subjek;

/// Cip nombor soalan pada halaman semak.
class _CipSoalan extends StatelessWidget {
  const _CipSoalan({
    required this.nombor,
    required this.dijawab,
    required this.warna,
    required this.onTap,
  });

  final int nombor;
  final bool dijawab;
  final Color warna;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dijawab ? warna.withValues(alpha: 0.12) : const Color(0xFFF3F3F5),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: dijawab ? warna : const Color(0xFFDDDDDD),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$nombor',
                style: Teks.biasa.copyWith(
                  fontWeight: FontWeight.w800,
                  color: dijawab ? warna : Colors.black45,
                ),
              ),
              if (dijawab) ...[
                const SizedBox(width: 2),
                Icon(Icons.check_rounded, size: 13, color: warna),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
