import { extname, join } from 'node:path';

import {
  AUDIO_QUALITIES,
  COVER_SIZES,
  audioKey,
  coverKey,
  coverPrefix,
  type AudioQuality,
  type CoverSize,
} from '../domain/media_plan.ts';

export type SongToTranscode = {
  id: string;
  status: string;
  originalKey: string | null;
  coverOriginalKey: string | null;
};

export type AudioFile = {
  quality: AudioQuality;
  key: string;
  sizeBytes: number;
  sha256: string;
};

/** Filas de la canción en Postgres (con la llave secreta: salta RLS). */
export interface SongStore {
  get(songId: string): Promise<SongToTranscode | null>;
  markReady(
    songId: string,
    result: { durationMs: number; coverKey: string | null; files: AudioFile[] },
  ): Promise<void>;
  markFailed(songId: string): Promise<void>;
}

/** Bucket (B2). */
export interface ObjectStore {
  download(key: string, path: string): Promise<void>;
  upload(key: string, path: string, contentType: string): Promise<void>;
}

/** ffmpeg / ffprobe. */
export interface MediaTool {
  /** Normaliza a −14 LUFS y codifica todas las calidades. */
  transcodeAudio(input: string, outputs: Record<AudioQuality, string>): Promise<void>;
  durationMs(path: string): Promise<number>;
  transcodeCover(input: string, outputs: Record<CoverSize, string>): Promise<void>;
}

export interface LocalFiles {
  tempDir(): Promise<string>;
  remove(dir: string): Promise<void>;
  describe(path: string): Promise<{ sizeBytes: number; sha256: string }>;
}

export type TranscodeDeps = {
  songs: SongStore;
  store: ObjectStore;
  media: MediaTool;
  files: LocalFiles;
  log: (message: string, error?: unknown) => void;
};

export type TranscodeOutcome = 'ready' | 'skipped' | 'failed';

/**
 * originals/ → audio/{id}/{96|128|256}.m4a + covers/{id}/{200|640}.webp →
 * `song_files` y `status = 'ready'`. Idempotente: las keys son fijas por
 * canción, así que reintentar sobrescribe lo mismo.
 */
export async function transcodeSong(
  songId: string,
  deps: TranscodeDeps,
): Promise<TranscodeOutcome> {
  const song = await deps.songs.get(songId);
  if (!song || song.status !== 'processing' || !song.originalKey) {
    return 'skipped';
  }

  const dir = await deps.files.tempDir();
  try {
    const original = join(dir, `original${extname(song.originalKey)}`);
    await deps.store.download(song.originalKey, original);

    const outputs = record(AUDIO_QUALITIES, (q) => join(dir, `${q}.m4a`));
    await deps.media.transcodeAudio(original, outputs);
    const durationMs = await deps.media.durationMs(outputs[128]);

    const files: AudioFile[] = [];
    for (const quality of AUDIO_QUALITIES) {
      const key = audioKey(song.id, quality);
      const info = await deps.files.describe(outputs[quality]);
      await deps.store.upload(key, outputs[quality], 'audio/mp4');
      files.push({ quality, key, ...info });
    }

    const cover = song.coverOriginalKey
      ? await transcodeCover(song.id, song.coverOriginalKey, dir, deps)
      : null;

    await deps.songs.markReady(song.id, { durationMs, coverKey: cover, files });
    return 'ready';
  } catch (error) {
    deps.log(`transcode ${song.id} failed`, error);
    await deps.songs.markFailed(song.id);
    return 'failed';
  } finally {
    await deps.files.remove(dir);
  }
}

/** La portada es opcional: si falla, la canción igual queda lista sin ella. */
async function transcodeCover(
  songId: string,
  originalKey: string,
  dir: string,
  deps: TranscodeDeps,
): Promise<string | null> {
  try {
    const original = join(dir, `cover${extname(originalKey)}`);
    await deps.store.download(originalKey, original);
    const outputs = record(COVER_SIZES, (s) => join(dir, `${s}.webp`));
    await deps.media.transcodeCover(original, outputs);
    for (const size of COVER_SIZES) {
      await deps.store.upload(coverKey(songId, size), outputs[size], 'image/webp');
    }
    return coverPrefix(songId);
  } catch (error) {
    deps.log(`cover ${songId} failed`, error);
    return null;
  }
}

function record<K extends number, V>(keys: readonly K[], value: (key: K) => V) {
  return Object.fromEntries(keys.map((k) => [k, value(k)])) as Record<K, V>;
}
