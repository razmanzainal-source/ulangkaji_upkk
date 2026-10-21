import 'suara.dart';
import 'tetapan.dart';

/// Mengawal sapaan pembuka app.
///
/// Sapaan ("Assalamualaikum, jom ulangkaji KAFA bersama Raz.") menandakan bahawa
/// app ini mengenali murid itu. Tetapi sapaan yang sama dimainkan **setiap
/// kali** murid menekan butang, atau setiap kali dia berpindah tab, cepat
/// menjadi bunyi latar yang tidak lagi didengar.
///
/// Jadi sapaan dimainkan sekali bagi setiap kali app dibuka — sama ada murid
/// sudah menetapkan namanya, menukarnya, atau melangkaunya terus. Nama itu
/// sendiri tidak disebut (lihat [Suara.sapaan]), jadi tiada sebab untuk
/// memainkan sapaan sekali lagi selepas dialog nama.
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
    await Suara.instance.sebutSalam();
  }
}
