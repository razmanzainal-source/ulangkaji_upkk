import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';

import 'tetapan.dart';

/// Suara Bahasa Melayu untuk murid Tahun 5.
///
/// **Rakaman Yasmin ialah suara utama app.** Setiap soalan ada klipnya sendiri
/// (dijana lebih awal melalui `tools/jana_suara.py`), dan klip itulah yang
/// dimainkan pada semua telefon — termasuk telefon yang mempunyai suara Bahasa
/// Melayu. Ini penting kerana:
///
/// - sebutan dalam rakaman sudah betul dan konsisten (suara perempuan Bahasa
///   Melayu neural, `ms-MY-YasminNeural`);
/// - anak mendengar **satu suara yang sama** pada setiap peranti, jadi sebutan
///   tidak berubah-ubah antara telefon ibu bapa dan tablet anak.
///
/// Rakaman dibuat dengan **suara perempuan** atas permintaan ibu bapa: suara
/// perempuan lebih menyerupai guru kelas KAFA, dan lebih menenangkan murid yang
/// menjawab kertas percubaan bersendirian.
///
/// Enjin suara peranti (TTS) hanya menjadi **sandaran** apabila sesuatu ayat
/// tiada rakaman — contohnya jika fail manifest audio tidak dapat dibaca — dan
/// hanya digunakan apabila peranti benar-benar mempunyai suara Bahasa Melayu.
/// Teks Melayu yang dibaca dengan suara Inggeris lebih memesongkan kanak-kanak
/// daripada senyap.
///
/// Keputusan ini dibuat sekali sahaja semasa app dibuka; lihat [adaSuaraMelayu].
class Suara {
  Suara._();

  static final Suara instance = Suara._();

  static const String _laluanManifest = 'assets/bunyi/suara/manifest.json';

  static const String kunciCubaLagi = 'f-salah';

  /// Gesaan menjawab apabila murid menekan "Seterusnya" sebelum menjawab.
  ///
  /// Hanya untuk **latih tubi**, yang mewajibkan satu jawapan bagi setiap
  /// soalan (lihat `_bolehTerus` dalam `kertas_screen.dart`). Tanpa ayat ini
  /// butang kelihatan rosak kepada kanak-kanak.
  ///
  /// Ia sengaja **bukan** teguran: ayatnya menyuruh murid mencuba, bukan
  /// memberitahu dia telah gagal.
  static const String kunciJawabDulu = 'f-jawab-dulu';
  static const String teksJawabDulu = 'Jawab dulu sebelum teruskan.';

  /// Ambang jawapan betul berturut-turut untuk mendengar pujian bersuara.
  ///
  /// Pujian **tidak** diberikan pada setiap jawapan betul: ayat yang sama
  /// selepas setiap soalan menjadi bunyi latar selepas sepuluh soalan dan
  /// tidak lagi didengar. Dengan rentetan, pujian bermakna — ia tiba apabila
  /// murid benar-benar konsisten.
  ///
  /// Tiga dipilih kerana ia mudah dicapai tetapi tidak murah: murid yang
  /// menjawab sesuka hati hampir tidak akan pernah mendengarnya.
  static const int ambangRentetan = 3;

  /// Pujian rentetan — tiga ayat yang bergilir mengikut [kunciRentetan].
  static const String kunciRentetan1 = 'f-rentetan1';
  static const String kunciRentetan2 = 'f-rentetan2';
  static const String kunciRentetan3 = 'f-rentetan3';

  /// Pujian bagi rentetan [nombor] jawapan betul berturut-turut.
  ///
  /// [nombor] di sini ialah **nombor giliran pujian** (1, 2, 3…), bukan
  /// bilangan rentetan itu sendiri — lihat `_puji`. Bergilir antara tiga ayat
  /// supaya bunyi tidak berulang dalam satu sesi.
  static String kunciRentetan(int nombor) => switch (nombor % 3) {
        1 => kunciRentetan1,
        2 => kunciRentetan2,
        _ => kunciRentetan3,
      };

  // Nota tanda baca: tiada lagi ", ya." di hujung ayat app. Ayat yang
  // berakhir dengan "ya" berbunyi seperti orang dewasa yang memujuk, bukan
  // seperti guru yang yakin — dan selepas ayat kesalahan yang ke sepuluh dalam
  // satu sesi, "ya" itu kedengaran janggal (runutan murid sendiri).

  /// **Tiada** pujian bersuara selepas setiap jawapan betul.
  ///
  /// Ayat "Betul! Syabas!" selepas setiap jawapan betul kelihatan mesra di
  /// atas kertas, tetapi dalam tangan ia menjadi dua masalah: ia melewatkan
  /// murid yang sedang laju menjawab, dan selepas sepuluh soalan ia menjadi
  /// bunyi latar yang tidak lagi didengar. Jawapan betul disambut dengan
  /// **nada ceria** sahaja — lebih pantas difahami daripada ayat.
  ///
  /// Suara disimpan untuk perkara yang murid perlu dengar: sapaan pembuka,
  /// maklum balas keputusan, dan ayat menenangkan apabila jawapan salah.

  /// Teks sandaran daripada [kunciCubaLagi].
  static const String teksCubaLagi = 'Cuba lagi.';

  /// Ayat maklum balas keputusan: (kunci rakaman, teks sandaran).
  ///
  /// Dipisahkan daripada skrin supaya ambang gred hanya ditulis **sekali** —
  /// di sini — dan tidak tersebar antara bunyi dan paparan.
  ///
  /// Setiap ayat bermula dengan perkataan yang sama seperti kepala kad
  /// keputusan (`_pujian` dalam `keputusan_screen.dart` dan `kad_keputusan.dart`).
  /// Murid membaca "Jangan putus asa" sambil mendengar ayat yang sama bermula;
  /// ayat yang berbeza daripada paparan kedengaran seperti rakaman terpotong.
  static (String, String) keputusan(int peratus, {bool sempurna = false}) {
    if (sempurna) return (kunciSempurna, 'Cemerlang! Semua jawapan betul.');
    if (peratus >= 80) return (kunciHebat, 'Cemerlang! Markah kamu cemerlang.');
    if (peratus >= 60) return (kunciBagus, 'Bagus! Sedikit lagi usaha.');
    if (peratus >= 40) return (kunciBoleh, 'Boleh lagi! Cuba sekali lagi.');
    return (kunciUlang, 'Jangan putus asa. Mari kita ulang kaji sekali lagi.');
  }

  /// Pujian khas apabila semua soalan betul.
  static const String kunciSempurna = 'f-sempurna';

  // Maklum balas kertas percubaan (mod peperiksaan).
  static const String kunciHebat = 'f-hebat';
  static const String kunciBagus = 'f-bagus';
  static const String kunciBoleh = 'f-boleh';
  static const String kunciUlang = 'f-ulang';

  // Nama anak: soalan yang dibaca kuat semasa dialog nama kali pertama.
  static const String kunciNama = 'f-nama';
  static const String kunciSelamat = 'f-selamat';

  /// Ayat penutup **latih tubi** mengikut keputusan murid.
  ///
  /// Latih tubi bukan kertas, jadi **ketiga-tiga** ayat ini tidak menyebut
  /// markah, peratus mahupun gred — hanya mengesahkan latihan sudah selesai
  /// dan mengajak murid mencuba lagi.
  ///
  /// "Syabas" hanya untuk [ambangSyabasPeratus] peratus ke atas. Memuji
  /// sepuluh soalan yang tujuh salah membuatkan pujian itu tidak bermakna —
  /// murid tahu dia banyak salah, dan pujian yang tidak jujur lebih mudah
  /// dikesan oleh kanak-kanak daripada pujian yang tulus.
  static const String kunciLatihanSelesai = 'f-latihan';
  static const String teksLatihanSelesai =
      'Syabas! Latihan selesai. Jom cuba lagi.';

  /// Ayat penutup latih tubi — keputusan sederhana (bawah ambang syabas).
  static const String kunciLatihanSederhana = 'f-latihan-sederhana';
  static const String teksLatihanSederhana =
      'Latihan selesai. Teruskan usaha, jom cuba lagi.';

  /// Ayat penutup latih tubi — keputusan lemah (banyak soalan salah).
  static const String kunciLatihanUlang = 'f-latihan-ulang';
  static const String teksLatihanUlang =
      'Latihan selesai. Jangan putus asa, mari ulang kaji sekali lagi.';

  /// Peratus minimum soalan betul untuk mendengar "Syabas".
  ///
  /// Ambang ini dikunci oleh permintaan ibu bapa: pujian mesti **logik**.
  /// Tujuh soalan betul daripada sepuluh (70%) masih layak dipuji; tiga
  /// daripada sepuluh tidak.
  static const int ambangSyabasPeratus = 70;

  /// Ayat penutup latih tubi bagi satu peratus jawapan betul.
  ///
  /// Dipisahkan daripada skrin penutup supaya ambang ditulis sekali sahaja di
  /// sini — dan supaya paparan sentiasa bermula dengan perkataan yang sama
  /// seperti bunyi (lihat [keputusan]).
  static (String, String) latihanSelesai(int peratus) {
    if (peratus >= ambangSyabasPeratus) {
      return (kunciLatihanSelesai, teksLatihanSelesai);
    }
    if (peratus >= 40) {
      return (kunciLatihanSederhana, teksLatihanSederhana);
    }
    return (kunciLatihanUlang, teksLatihanUlang);
  }

  /// Teks rakaman [kunciNama] — soalan nama dibaca kuat.
  ///
  /// Dialog nama berdiri sendiri tanpa sebarang teks lain di skrin, dan murid
  /// Tahun 5 yang belum lancar membaca tidak sepatutnya terpaksa meneka apa
  /// yang app mahu. Suara menjadikan soalan itu jelas.
  static const String soalanNama = 'Assalamualaikum! Siapa nama kamu?';

  /// Nama maskot yang disebut dalam sapaan pembuka.
  ///
  /// Raz ialah kanak-kanak perempuan kecil yang menemani murid di dalam app
  /// ini. Nama itu ialah nama anak pencipta app — app ini dibina untuknya —
  /// jadi sapaan mengajak murid belajar **bersama Raz**, bukan bersama orang
  /// dewasa yang tidak kelihatan.
  static const String namaMaskot = 'Raz';

  /// Ayat sapaan pembuka — teks rakaman Yasmin bagi [kunciSelamat].
  ///
  /// Ayat ini mesti pendek dan wajar didengari: ia dimainkan setiap kali app
  /// dibuka. Sebutan "mengulang kaji KAFA" didengari sebagai "mengulangkaji"
  /// yang tergantung; "belajar KAFA" ialah ayat yang murid Tahun 5 benar-benar
  /// gunakan.
  ///
  /// Nama murid **sengaja tidak** disebut di sini. Menyebut nama setiap murid
  /// memerlukan enjin suara peranti, dan jantina suara itu tidak dapat
  /// dipastikan — semua suara lain dalam app ini suara perempuan, jadi satu
  /// suara yang berbeza jantina lebih memesongkan murid daripada nama yang
  /// tidak disebut langsung. Nama murid masih dipaparkan di skrin (kepala
  /// skrin dan kad keputusan), cuma tidak dibaca kuat.
  static const String sapaan =
      'Assalamualaikum, jom belajar KAFA bersama $namaMaskot.';

  // --- Bunyi kesan (nada, bukan suara) di `assets/bunyi/kesan/` -------------

  /// Nada menaik apabila jawapan betul.
  static const String kesanBetul = 'betul';

  /// Nada lembut apabila jawapan salah.
  static const String kesanSalah = 'salah';

  /// Fanfar untuk keputusan cemerlang.
  static const String kesanHebat = 'hebat';

  /// Kunci rakaman satu soalan (teks soalan, bukan pilihannya).
  static String kunciSoalan(String id) => 'q-$id';

  /// Kunci rakaman bagi satu teks pilihan jawapan.
  ///
  /// Klip pilihan dikongsi mengikut **teks**, bukan mengikut nombor soalan:
  /// "Bersyukur" yang muncul dalam enam soalan hanya perlu satu rakaman. Itulah
  /// sebabnya bantuan suara latih tubi menambah kira-kira 16 MB walaupun bank
  /// mengandungi lebih 2,000 pilihan jawapan, pernyataan dan ayat.
  ///
  /// Kunci ini juga dipakai oleh `tools/jana_suara.py`; menukar bentuknya di
  /// sini tanpa menukar penjana bermakna butang speaker menjadi senyap.
  static String kunciPilihan(String teks) => 'o-${teks.trim()}';

  /// Pembetulan sebutan untuk **laluan sandaran sahaja** (TTS peranti).
  ///
  /// Enjin suara sesetengah telefon membaca huruf "c" Bahasa Melayu sebagai
  /// /k/ ("cuba" → "kuba"). Rakaman Yasmin tidak memerlukan pembetulan ini
  /// (sudah disemak melalui `tools/periksa_sebutan.py`), jadi senarai
  /// `SEBUTAN` dalam `tools/jana_suara.py` kosong.
  static final List<(RegExp, String)> _sebutan = [
    (RegExp(r'\bcuba\b', caseSensitive: false), 'chuba'),
  ];

  final AudioPlayer _pemain = AudioPlayer();

  /// Pemain berasingan untuk bunyi kesan.
  ///
  /// Kalau nada dan suara berkongsi satu pemain, `play` kedua akan menghentikan
  /// yang pertama — niatnya ialah nada berbunyi **sambil** pujian disebut.
  final AudioPlayer _pemainKesan = AudioPlayer();

  final FlutterTts _tts = FlutterTts();

  Map<String, String> _peta = const {};

  /// Operasi penyediaan yang sedang berjalan, jika ada.
  ///
  /// Disimpan sebagai `Future` (bukan `bool`) supaya panggilan yang datang
  /// semasa penyediaan masih berjalan **menunggu** operasi yang sama, bukan
  /// pulang serta-merta. Sapaan pembuka memerlukan manifest sudah dimuatkan;
  /// tanpa ini ia boleh berlumba dengan `main.dart` dan menyebut teks sandaran
  /// yang salah.
  Future<void>? _penyediaan;

  Completer<void>? _tungguSelesai;

  /// Berapa banyak ayat yang mempunyai rakaman Bahasa Melayu.
  int get bilanganRakaman => _peta.length;

  /// Sediakan pemain dan muatkan senarai klip rakaman.
  ///
  /// Selamat dipanggil dari mana-mana sahaja, berapa kali pun.
  Future<void> sedia() => _penyediaan ??= _sediakan();

  Future<void> _sediakan() async {
    _pemain.onPlayerComplete.listen((_) => _selesaikanTunggu());

    await _muatManifest();

    // Enjin TTS disediakan di belakang tabir. Sesetengah telefon lambat (atau
    // tidak pernah) menyahut panggilan TTS — app tidak boleh menunggunya.
    unawaited(_sediaTtsSekali());
  }

  Future<void>? _ttsSedia;

  /// Menyediakan enjin TTS sekali sahaja, walau berapa kali diminta.
  Future<void> _sediaTtsSekali() => _ttsSedia ??= _sediaTts();

  Future<void> _muatManifest() async {
    try {
      final teks = await rootBundle.loadString(_laluanManifest);
      final json = jsonDecode(teks) as Map<String, dynamic>;
      _peta = (json['fail'] as Map).cast<String, String>();
    } catch (e) {
      _peta = const {};
      if (kDebugMode) debugPrint('Suara: manifest rakaman tidak dijumpai ($e)');
    }
  }

  /// Had masa untuk setiap panggilan penyediaan enjin TTS.
  static const Duration _hadSedia = Duration(seconds: 2);

  Future<void> _sediaTts() async {
    try {
      // Setiap panggilan ada had masa: sesetengah peranti (atau enjin TTS yang
      // tidak dipasang) tidak pernah menyahut panggilan ini, dan app tidak
      // boleh menunggunya.
      await _had(_tts.setSpeechRate(0.45), _hadSedia);
      await _had(_tts.setPitch(1.05), _hadSedia);
      await _had(_tts.setVolume(1.0), _hadSedia);
      await _had(_tts.awaitSpeakCompletion(true), _hadSedia);
      final ada = await _tts
          .isLanguageAvailable('ms-MY')
          .timeout(_hadSedia, onTimeout: () => null);
      _adaMelayu = ada == true;
      if (_adaMelayu!) {
        await _had(_tts.setLanguage('ms-MY'), _hadSedia);
      }
    } catch (e) {
      _adaMelayu = false;
      if (kDebugMode) debugPrint('Suara: enjin TTS tidak tersedia ($e)');
    }
  }

  bool? _adaMelayu;

  /// Benar apabila ayat [kunci] mempunyai klip rakaman Yasmin.
  ///
  /// Dipakai oleh ujian untuk memastikan setiap ayat tetap app ada rakaman —
  /// jadi enjin suara peranti tidak pernah menggantikannya.
  @visibleForTesting
  bool adaRakaman(String kunci) => _peta.containsKey(kunci);

  /// Benar apabila peranti mempunyai enjin suara Bahasa Melayu.
  ///
  /// Ini **bukan** lagi pilihan suara: rakaman Yasmin sentiasa diutamakan (lihat
  /// dokumen kelas). Keputusan ini hanya menentukan sama ada enjin suara peranti
  /// boleh dipakai sebagai sandaran apabila sesuatu ayat tiada rakaman.
  Future<bool> adaSuaraMelayu() async {
    if (_adaMelayu == null) await _sediaTtsSekali();
    return _adaMelayu ?? false;
  }

  /// Lupakan keputusan pengesanan enjin suara — untuk ujian sahaja.
  ///
  /// Pengesanan sebenar berlaku sekali sahaja seumur hidup app; ujian perlu
  /// menetapkannya semula supaya kedua-dua kes (ada/tidak ada suara Melayu)
  /// boleh diuji.
  @visibleForTesting
  void lupakanEnjinSuara() {
    _adaMelayu = null;
    _ttsSedia = null;
  }

  void _selesaikanTunggu() {
    final c = _tungguSelesai;
    if (c != null && !c.isCompleted) c.complete();
    _tungguSelesai = null;
  }

  /// Sebut ayat yang mempunyai kunci rakaman.
  ///
  /// Rakaman Yasmin dimainkan **selalu** apabila klipnya ada — pada semua
  /// peranti, termasuk telefon yang mempunyai suara Bahasa Melayu. Enjin suara
  /// peranti hanya dipakai sebagai sandaran apabila rakaman itu tiada (contohnya
  /// fail manifest tidak dapat dibaca) supaya app tidak pernah menjadi senyap.
  ///
  /// [sandaran] ialah teks yang disebut oleh enjin TTS dalam kes sandaran itu;
  /// ia tidak pernah menggantikan rakaman.
  Future<void> sebutKunci(String kunci, {String? sandaran}) async {
    ayatTerakhir = kunci;
    if (!Tetapan.instance.bunyiHidup) return;

    // Manifest mesti siap sebelum kita tahu sama ada klip ini ada. Selepas
    // panggilan pertama ini tidak lagi berkos.
    await sedia();

    _selesaikanTunggu();

    final fail = _peta[kunci];
    if (fail != null) {
      try {
        await _had(_pemain.stop(), const Duration(seconds: 2));
        _tungguSelesai = Completer<void>();
        await _had(
          _pemain.play(AssetSource('bunyi/suara/$fail')),
          const Duration(seconds: 4),
        );
        return;
      } catch (e) {
        _tungguSelesai = null;
        if (kDebugMode) debugPrint('Suara: gagal memainkan $kunci ($e)');
      }
    }

    if (sandaran != null) await sebut(sandaran);
  }

  /// Kesan terakhir yang **diminta**, termasuk apabila bunyi dimatikan.
  ///
  /// Ujian automatik tidak boleh mendengar audio. Dengan merakam niat di sini,
  /// ujian boleh memastikan bunyi diminta pada masa yang betul sahaja —
  /// contohnya **tidak** semasa murid menjawab kertas percubaan.
  @visibleForTesting
  String? kesanTerakhir;

  /// Mainkan bunyi kesan (nada pendek) daripada `assets/bunyi/kesan/`.
  ///
  /// Nada mengesahkan jawapan dengan serta-merta — lebih pantas daripada ayat
  /// yang perlu didengar sampai habis. Ia dimainkan pada pemain berasingan
  /// supaya ia tidak menghentikan ayat yang disebut pada masa yang sama.
  ///
  /// Nada ini **tidak** melalui enjin suara peranti: ia fail yang dibundelkan,
  /// jadi ia berbunyi pada setiap telefon walaupun tiada suara Bahasa Melayu.
  Future<void> mainkanKesan(String nama) async {
    kesanTerakhir = nama;

    if (!Tetapan.instance.bunyiHidup) return;

    try {
      await _had(_pemainKesan.stop(), const Duration(seconds: 2));
      await _had(
        _pemainKesan.play(AssetSource('bunyi/kesan/$nama.m4a')),
        const Duration(seconds: 3),
      );
    } catch (e) {
      // Bunyi kesan tidak pernah boleh menggagalkan jawapan murid.
      if (kDebugMode) debugPrint('Suara: gagal memainkan kesan $nama ($e)');
    }
  }

  /// Ayat terakhir yang **diminta**, sama seperti [kesanTerakhir].
  ///
  /// Ujian automatik tidak boleh mendengar audio, jadi niat app dirakam di
  /// sini: ujian boleh memastikan ayat keputusan tidak bermula semasa nada
  /// sambutan masih berbunyi.
  @visibleForTesting
  String? ayatTerakhir;

  /// Mainkan nada kesan, dan tunggu sehingga ia benar-benar tamat.
  ///
  /// Nada sambutan dan ayat pujian **tidak boleh** dimainkan serentak: dua bunyi
  /// yang bertindih menjadikan ayat itu kabur dan kedengaran terpotong — murid
  /// mendengar "Jangan putus asa" separuh tenggelam di bawah fanfar. Jadi nada
  /// dimainkan dahulu, dan ayat hanya bermula selepas nada selesai.
  ///
  /// [had] ialah jaring keselamatan. Platform audio tidak selamanya melaporkan
  /// peristiwa tamat (dan platform palsu dalam ujian automatik memang tidak
  /// pernah melaporkannya), jadi ayat tetap diminta selepas [had] supaya app
  /// tidak pernah menjadi senyap.
  Future<void> mainkanKesanSelesai(
    String nama, {
    Duration had = const Duration(seconds: 3),
  }) async {
    // Bunyi dimatikan: niat tetap dirakam (lihat `kesanTerakhir`), tetapi tiada
    // nada yang perlu ditunggu — jadi tiada pemasa yang perlu dibiarkan hidup.
    if (!Tetapan.instance.bunyiHidup) {
      await mainkanKesan(nama);
      return;
    }

    final selesai = Completer<void>();
    final langganan = _pemainKesan.onPlayerComplete.listen((_) {
      if (!selesai.isCompleted) selesai.complete();
    });
    try {
      // Nada dimulakan tanpa ditunggu: `stop`/`play` pada sesetengah peranti
      // mengambil masa, dan ayat tidak sepatutnya lambat kerana itu. Pendengar
      // sudah bersedia sebelum nada bermula, jadi peristiwa tamat tidak terlepas.
      unawaited(mainkanKesan(nama));
      await _had(selesai.future, had);
    } finally {
      // Pembatalan pendengar tidak ditunggu: ada platform yang tidak menamatkan
      // operasi batal, dan nada/ayat tidak boleh tersekat kerananya.
      unawaited(langganan.cancel());
    }
  }

  /// Sapaan pembuka: "Assalamualaikum, jom belajar KAFA bersama Raz."
  ///
  /// Satu rakaman sahaja ([kunciSelamat]); tiada bahagian yang dibina daripada
  /// enjin suara peranti, jadi sapaan ini sentiasa berbunyi dengan suara
  /// perempuan yang sama seperti seluruh app.
  Future<void> sebutSalam() => sebutKunci(kunciSelamat, sandaran: sapaan);

  /// Sebut satu pilihan jawapan — **latih tubi sahaja**.
  ///
  /// Kertas percubaan tidak memanggil fungsi ini: kertas sebenar tidak
  /// membacakan pilihan jawapan kepada murid, dan bantuan suara di situ akan
  /// mengubah markah, bukan menguji pemahaman.
  ///
  /// [teks] ialah teks yang **didengar**, bukan teks yang dipaparkan: Rumi bagi
  /// subjek Jawi (enjin suara Melayu tidak boleh membaca tulisan Jawi) dan teks
  /// Arab bagi subjek Bahasa Arab. Pemanggil yang memilih teks itu.
  Future<void> sebutPilihan(String teks) =>
      sebutKunci(kunciPilihan(teks), sandaran: teks);

  /// Sebut teks terus melalui enjin TTS peranti.
  ///
  /// Ini **bukan** laluan utama: rakaman Yasmin diutamakan (lihat dokumen kelas).
  /// Ia hanya dipakai sebagai sandaran apabila ayat tiada rakaman, supaya app
  /// tidak menjadi senyap. Sebutan hanya dibuat apabila peranti benar-benar
  /// mempunyai suara Bahasa Melayu — teks Melayu yang dibaca dengan suara
  /// Inggeris lebih memesongkan anak daripada tiada bunyi langsung.
  Future<void> sebut(String teks) async {
    ayatTerakhir = teks;
    if (!Tetapan.instance.bunyiHidup || teks.trim().isEmpty) return;

    if (!await adaSuaraMelayu()) {
      if (kDebugMode) {
        debugPrint('Suara: tiada suara Melayu — sebutan dilangkau ($teks)');
      }
      return;
    }

    _selesaikanTunggu();

    // Hentikan rakaman yang mungkin masih berbunyi supaya dua suara tidak
    // bertindih — contohnya sapaan bernama selepas dialog nama ditutup.
    try {
      await _had(_pemain.stop(), const Duration(seconds: 2));
    } catch (_) {
      // Diabaikan.
    }

    _tungguSelesai = Completer<void>();

    final ayat = sebutanBetul(teks);

    // Had masa mengikut panjang ayat. Sesetengah enjin TTS (terutamanya pada
    // pelayar web atau peranti tanpa suara Bahasa Melayu) melaporkan ralat
    // tanpa pernah menamatkan sebutan — tanpa had ini, app akan tergantung.
    final had = Duration(
      milliseconds: (1200 + ayat.length * 90).clamp(3000, 12000),
    );
    try {
      await _had(_tts.stop(), const Duration(seconds: 2));
      await _had(_tts.speak(ayat), had);
    } catch (e) {
      if (kDebugMode) debugPrint('Suara: gagal menyebut ($e)');
    } finally {
      _selesaikanTunggu();
    }
  }

  /// Betulkan perkataan yang disebut berbeza daripada ejaan paparan.
  ///
  /// Ini cerminan `SEBUTAN` dalam `tools/jana_suara.py` — rakaman Yasmin dan
  /// enjin suara peranti mesti menyebut perkataan yang sama. Perkataan yang
  /// disebut gaya Inggeris dibetulkan (contoh "cuba" → "chuba", nama maskot
  /// "Raz" → "Razz"); paparan dalam app kekal ejaan asal.
  ///
  /// Tanda kosong soalan (`____`) dibaca "garis bawah" oleh enjin TTS. Soalan
  /// isi tempat kosong pula boleh ada beberapa tanda, jadi "tempat kosong"
  /// disebut sekali sahaja — tanda berikutnya dibuang supaya ayat tidak
  /// berulang-ulang.
  static String sebutanBetul(String teks) {
    var ayat = teks;
    for (final (pola, ganti) in _sebutan) {
      ayat = ayat.replaceAllMapped(pola, (padan) {
        final asal = padan.group(0)!;
        // Kekalkan huruf besar jika perkataan asal bermula dengan huruf besar.
        return asal[0] == asal[0].toUpperCase()
            ? ganti[0].toUpperCase() + ganti.substring(1)
            : ganti;
      });
    }
    var pertama = true;
    ayat = ayat.replaceAllMapped(RegExp(r'_{2,}'), (padan) {
      if (pertama) {
        pertama = false;
        return 'tempat kosong';
      }
      return ' ';
    });
    // Buang ruang berlebihan dan ruang sebelum tanda baca.
    return ayat
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAllMapped(RegExp(r'\s+([.,?!:;])'), (padan) => padan.group(1)!)
        .trim();
  }

  /// Benar apabila [berhenti] dipanggil sejak kali terakhir ditetapkan semula.
  ///
  /// Sengaja disegerakkan. [berhenti] menunggu platform audio dan pemasa had,
  /// dan ujian tidak boleh menunggu platform yang memang tidak wujud di
  /// dalamnya — dengan menandakan niat pada baris pertama, ujian boleh
  /// memeriksa sama ada satu tindakan menghentikan bunyi tanpa bergantung
  /// pada masa.
  bool berhentiDipanggil = false;

  Future<void> berhenti() async {
    berhentiDipanggil = true;
    _selesaikanTunggu();
    try {
      await _had(_pemain.stop(), const Duration(seconds: 2));
    } catch (_) {
      // Diabaikan: berhenti tidak boleh menggagalkan app.
    }
    try {
      await _had(_pemainKesan.stop(), const Duration(seconds: 2));
    } catch (_) {
      // Diabaikan.
    }
    try {
      await _had(_tts.stop(), const Duration(seconds: 2));
    } catch (_) {
      // Diabaikan.
    }
  }

  /// Menjalankan kerja audio dengan had masa.
  ///
  /// Enjin audio peranti (atau pelayar) boleh tersekat tanpa melaporkan apa-apa
  /// — had masa memastikan app sentiasa dapat meneruskan perjalanan.
  static Future<void> _had(Future<dynamic> kerja, Duration had) async {
    await kerja.timeout(had, onTimeout: () {});
  }
}
