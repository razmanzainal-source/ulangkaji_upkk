import 'suara.dart';
import 'tetapan.dart';

/// Mengawal sapaan pembuka app.
///
/// Sapaan ("Assalamualaikum, [nama], jom ulangkaji KAFA bersama Raz.")
/// menandakan bahawa
/// app ini mengenali murid itu. Tetapi sapaan yang sama dimainkan **setiap
/// kali** murid menekan butang, atau setiap kali dia berpindah tab, cepat
/// menjadi bunyi latar yang tidak lagi didengar.
///
/// Jadi sapaan dimainkan sekali bagi setiap kali app dibuka — sama ada murid
/// sudah menetapkan namanya, menukarnya, atau melangkaunya terus. Nama yang
/// disebut dalam sapaan diambil semasa [Suara.sebutSalam], jadi tiada sebab
/// untuk memainkan sapaan sekali lagi selepas dialog nama.
class Sapaan {
  Sapaan._();

  static final Sapaan instance = Sapaan._();

  bool _sudah = false;

  /// Mainkan sapaan pembuka.
  ///
  /// Tidak melakukan apa-apa jika sapaan sesi ini sudah dimainkan.
  Future<void> mainkan() async {
    if (_sudah) return;
    _sudah = true;
    if (!Tetapan.instance.bunyiHidup) return;
    // Sapaan menyebut nama murid — "Assalamualaikum, Aisyah, jom ulangkaji
    // KAFA bersama Raz." Nama diambil daripada tetapan supaya sapaan yang
    // dimainkan sentiasa mengikut nama yang sedang digunakan.
    await Suara.instance.sebutSalam(nama: Tetapan.instance.namaAnak);
  }
}
