import 'package:shared_preferences/shared_preferences.dart';

/// Tetapan mudah yang dikongsi seluruh app.
///
/// Ibu bapa perlu boleh mematikan bunyi dengan pantas (contohnya di dalam
/// bas atau di klinik), jadi keadaan ini disimpan supaya kekal selepas app
/// ditutup.
class Tetapan {
  Tetapan._();

  static final Tetapan instance = Tetapan._();

  static const String _kunciBunyi = 'bunyi_hidup';
  static const String _kunciNama = 'nama_anak';

  SharedPreferences? _p;

  bool _bunyiHidup = true;

  bool get bunyiHidup => _bunyiHidup;

  String _namaAnak = '';

  /// Nama anak — dipaparkan pada skrin hadiah, keputusan dan laporan.
  String get namaAnak => _namaAnak;

  bool get adaNama => _namaAnak.trim().isNotEmpty;

  Future<void> muat() async {
    _p = await SharedPreferences.getInstance();
    _bunyiHidup = _p?.getBool(_kunciBunyi) ?? true;
    _namaAnak = _p?.getString(_kunciNama) ?? '';
  }

  /// Simpan nama anak. Nama kosong bermakna belum ditetapkan.
  Future<void> tetapkanNama(String nama) async {
    _namaAnak = nama.trim();
    await _p?.setString(_kunciNama, _namaAnak);
  }

  Future<void> tetapkanBunyi(bool hidup) async {
    _bunyiHidup = hidup;
    await _p?.setBool(_kunciBunyi, hidup);
  }

  Future<bool> tukarBunyi() async {
    await tetapkanBunyi(!_bunyiHidup);
    return _bunyiHidup;
  }
}
