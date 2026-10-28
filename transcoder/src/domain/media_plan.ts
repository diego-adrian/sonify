// Qué se genera por canción y dónde va en el bucket. Debe coincidir con lo
// que sirve el Worker del CDN (`cloudflare/media-worker/src/domain/media_key.ts`).

export const AUDIO_QUALITIES = [96, 128, 256] as const;
export type AudioQuality = (typeof AUDIO_QUALITIES)[number];

export const COVER_SIZES = [200, 640] as const;
export type CoverSize = (typeof COVER_SIZES)[number];

/** Objetivo de sonoridad (como Spotify / YouTube). */
export const TARGET_LUFS = -14;
export const TRUE_PEAK_DB = -1.5;
export const LOUDNESS_RANGE = 11;

export const audioKey = (songId: string, quality: AudioQuality) =>
  `audio/${songId}/${quality}.m4a`;

/** Prefijo guardado en `songs.cover_key`; los tamaños son `{prefijo}/{200|640}.webp`. */
export const coverPrefix = (songId: string) => `covers/${songId}`;

export const coverKey = (songId: string, size: CoverSize) =>
  `${coverPrefix(songId)}/${size}.webp`;

/** Medición de la primera pasada de `loudnorm`. */
export type LoudnessMeasurement = {
  inputI: string;
  inputTp: string;
  inputLra: string;
  inputThresh: string;
  targetOffset: string;
};

/**
 * Extrae el JSON que `loudnorm` imprime al final de stderr. Devuelve `null`
 * si no se pudo medir (p. ej. audio en silencio, que da `-inf`).
 */
export function parseLoudness(stderr: string): LoudnessMeasurement | null {
  const start = stderr.lastIndexOf('{');
  const end = stderr.lastIndexOf('}');
  if (start < 0 || end < start) return null;
  let json: Record<string, string>;
  try {
    json = JSON.parse(stderr.slice(start, end + 1));
  } catch {
    return null;
  }
  const values = [
    json.input_i,
    json.input_tp,
    json.input_lra,
    json.input_thresh,
    json.target_offset,
  ];
  if (values.some((v) => v === undefined || !Number.isFinite(Number(v)))) {
    return null;
  }
  const [inputI, inputTp, inputLra, inputThresh, targetOffset] =
    values as string[];
  return { inputI, inputTp, inputLra, inputThresh, targetOffset };
}

const loudnormTarget = `I=${TARGET_LUFS}:TP=${TRUE_PEAK_DB}:LRA=${LOUDNESS_RANGE}`;

/** Primera pasada: solo mide. */
export function measureArgs(input: string): string[] {
  return [
    '-hide_banner', '-nostdin', '-i', input, '-vn',
    '-af', `loudnorm=${loudnormTarget}:print_format=json`,
    '-f', 'null', '-',
  ];
}

/**
 * Segunda pasada: normaliza una vez y codifica las tres calidades AAC a la
 * vez. `+faststart` pone el índice al inicio para que el reproductor empiece
 * a sonar sin bajar el archivo entero. Sin metadatos del original.
 */
export function encodeAudioArgs(
  input: string,
  outputs: Record<AudioQuality, string>,
  measured: LoudnessMeasurement | null,
): string[] {
  const loudnorm = measured
    ? `loudnorm=${loudnormTarget}:measured_I=${measured.inputI}` +
      `:measured_TP=${measured.inputTp}:measured_LRA=${measured.inputLra}` +
      `:measured_thresh=${measured.inputThresh}` +
      `:offset=${measured.targetOffset}:linear=true`
    : `loudnorm=${loudnormTarget}`;
  const labels = AUDIO_QUALITIES.map((q) => `[a${q}]`).join('');
  const args = [
    '-hide_banner', '-nostdin', '-y', '-i', input,
    '-filter_complex',
    // loudnorm trabaja a 192 kHz: se vuelve a 44.1 kHz.
    `[0:a:0]${loudnorm},aresample=44100,asplit=${AUDIO_QUALITIES.length}${labels}`,
  ];
  for (const quality of AUDIO_QUALITIES) {
    args.push(
      '-map', `[a${quality}]`,
      '-map_metadata', '-1',
      '-ac', '2',
      '-c:a', 'aac',
      '-b:a', `${quality}k`,
      '-movflags', '+faststart',
      outputs[quality],
    );
  }
  return args;
}

/** Recorte cuadrado al centro y WebP en cada tamaño. */
export function encodeCoverArgs(
  input: string,
  outputs: Record<CoverSize, string>,
): string[] {
  const scales = COVER_SIZES.map(
    (s) => `[s${s}]scale=${s}:${s}:flags=lanczos[c${s}]`,
  ).join(';');
  const splits = COVER_SIZES.map((s) => `[s${s}]`).join('');
  const args = [
    '-hide_banner', '-nostdin', '-y', '-i', input,
    '-filter_complex',
    `[0:v:0]crop='min(iw,ih)':'min(iw,ih)',split=${COVER_SIZES.length}${splits};${scales}`,
  ];
  for (const size of COVER_SIZES) {
    args.push(
      '-map', `[c${size}]`,
      '-map_metadata', '-1',
      '-frames:v', '1',
      '-c:v', 'libwebp',
      '-quality', '80',
      outputs[size],
    );
  }
  return args;
}
