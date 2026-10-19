/// Tarikh dalam Bahasa Melayu.
///
/// Dipakai kertas percubaan, laporan dan mana-mana kad yang memaparkan tarikh,
/// supaya formatnya sama di seluruh app.
library;

/// Nama bulan daripada Januari hingga Disember.
const List<String> namaBulan = [
  'Januari',
  'Februari',
  'Mac',
  'April',
  'Mei',
  'Jun',
  'Julai',
  'Ogos',
  'September',
  'Oktober',
  'November',
  'Disember',
];

/// Tarikh dalam bentuk "18 Oktober 2026".
String tarikhMelayu(DateTime masa) =>
    '${masa.day} ${namaBulan[masa.month - 1]} ${masa.year}';

/// Masa menjawab dalam bentuk "5:28", atau "1:02:30" jika lebih sejam.
///
/// Minit tidak diberi sifar di hadapan ("5:28", bukan "05:28") supaya kad
/// keputusan kekal ringkas, tetapi saat sentiasa dua digit — "5:7" kelihatan
/// seperti salah taip.
String masaTeks(int saat) {
  final jam = saat ~/ 3600;
  final minit = (saat % 3600) ~/ 60;
  final baki = (saat % 60).toString().padLeft(2, '0');
  return jam > 0
      ? '$jam:${minit.toString().padLeft(2, '0')}:$baki'
      : '$minit:$baki';
}
