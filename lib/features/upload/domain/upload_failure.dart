enum UploadFailure {
  noFile,
  invalidTitle,
  descriptionTooLong,
  rightsNotAccepted,
  unsupportedType,
  tooLarge,
  coverUnsupported,
  coverTooLarge,
  dailyLimit,

  /// Solo los admins suben canciones.
  notAdmin,
  network,
  unknown,
}
