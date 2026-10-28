/// Licencias libres que puede elegir el artista (enum `song_license` en BD).
enum SongLicense {
  cc0('cc0'),
  ccBy('cc_by'),
  ccBySa('cc_by_sa'),
  ccByNc('cc_by_nc'),
  ccByNcSa('cc_by_nc_sa');

  const SongLicense(this.code);

  final String code;
}
