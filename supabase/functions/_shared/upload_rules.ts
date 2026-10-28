// Reglas de subida compartidas por create-upload y complete-upload.

/** Tamaño máximo del archivo original (WAV de ~10 min). */
export const MAX_ORIGINAL_BYTES = 200 * 1024 * 1024;

/** Subidas por usuario cada 24 h (abuso y costos). */
export const DAILY_UPLOAD_LIMIT = 20;

export const UPLOAD_URL_TTL_SECONDS = 15 * 60;

export const CONTENT_TYPES: Record<string, string> = {
  'audio/wav': 'wav',
  'audio/x-wav': 'wav',
  'audio/wave': 'wav',
  'audio/flac': 'flac',
  'audio/x-flac': 'flac',
  'audio/mpeg': 'mp3',
  'audio/mp4': 'm4a',
  'audio/x-m4a': 'm4a',
  'audio/aac': 'aac',
};

export const LICENSES = ['cc0', 'cc_by', 'cc_by_sa', 'cc_by_nc', 'cc_by_nc_sa'];

/** Portada original; el transcodificador genera las miniaturas WebP. */
export const MAX_COVER_BYTES = 10 * 1024 * 1024;

export const COVER_TYPES: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
};

export const MAX_DESCRIPTION_LENGTH = 500;
