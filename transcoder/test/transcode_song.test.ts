import assert from 'node:assert/strict';
import { beforeEach, describe, it } from 'node:test';

import {
  transcodeSong,
  type AudioFile,
  type SongToTranscode,
  type TranscodeDeps,
} from '../src/application/transcode_song.ts';

const SONG = 'e4a31669-62e6-4fe1-aa5f-dc45232fb22d';

describe('transcodeSong', () => {
  let song: SongToTranscode | null;
  let ready: { durationMs: number; coverKey: string | null; files: AudioFile[] } | null;
  let failed: boolean;
  let uploads: string[];
  let removed: string[];
  let coverFails: boolean;
  let audioFails: boolean;

  beforeEach(() => {
    song = {
      id: SONG,
      status: 'processing',
      originalKey: `originals/u/${SONG}.m4a`,
      coverOriginalKey: `originals/u/${SONG}-cover.jpg`,
    };
    ready = null;
    failed = false;
    uploads = [];
    removed = [];
    coverFails = false;
    audioFails = false;
  });

  const deps = (): TranscodeDeps => ({
    songs: {
      get: async () => song,
      markReady: async (_, result) => void (ready = result),
      markFailed: async () => void (failed = true),
    },
    store: {
      download: async () => {},
      upload: async (key) => void uploads.push(key),
    },
    media: {
      transcodeAudio: async () => {
        if (audioFails) throw new Error('ffmpeg');
      },
      durationMs: async () => 192_000,
      transcodeCover: async () => {
        if (coverFails) throw new Error('bad image');
      },
    },
    files: {
      tempDir: async () => '/tmp/x',
      remove: async (dir) => void removed.push(dir),
      describe: async (path) => ({ sizeBytes: path.length, sha256: `sha-${path}` }),
    },
    log: () => {},
  });

  it('sube audio y portadas y marca la canción lista', async () => {
    assert.equal(await transcodeSong(SONG, deps()), 'ready');
    assert.deepEqual(uploads, [
      `audio/${SONG}/96.m4a`,
      `audio/${SONG}/128.m4a`,
      `audio/${SONG}/256.m4a`,
      `covers/${SONG}/200.webp`,
      `covers/${SONG}/640.webp`,
    ]);
    assert.equal(ready?.durationMs, 192_000);
    assert.equal(ready?.coverKey, `covers/${SONG}`);
    assert.deepEqual(ready?.files.map((f) => f.quality), [96, 128, 256]);
    assert.equal(ready?.files[1]!.sha256, 'sha-/tmp/x/128.m4a');
    assert.deepEqual(removed, ['/tmp/x'], 'borra los temporales');
  });

  it('si la portada falla, la canción queda lista sin portada', async () => {
    coverFails = true;
    assert.equal(await transcodeSong(SONG, deps()), 'ready');
    assert.equal(ready?.coverKey, null);
  });

  it('si el audio falla, marca failed y limpia', async () => {
    audioFails = true;
    assert.equal(await transcodeSong(SONG, deps()), 'failed');
    assert.equal(failed, true);
    assert.equal(ready, null);
    assert.deepEqual(removed, ['/tmp/x']);
  });

  it('ignora canciones que no están en processing', async () => {
    song!.status = 'ready';
    assert.equal(await transcodeSong(SONG, deps()), 'skipped');
    song = null;
    assert.equal(await transcodeSong(SONG, deps()), 'skipped');
    assert.deepEqual(uploads, []);
  });
});
