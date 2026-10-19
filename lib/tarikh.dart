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
