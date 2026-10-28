import { createHash } from 'node:crypto';
import { createReadStream } from 'node:fs';
import { mkdtemp, rm, stat } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import type { LocalFiles } from '../application/transcode_song.ts';

// En Cloud Run /tmp vive en memoria: se borra al terminar cada canción.
export const localFiles: LocalFiles = {
  tempDir: () => mkdtemp(join(tmpdir(), 'sonify-')),

  remove: (dir) => rm(dir, { recursive: true, force: true }),

  async describe(path) {
    const hash = createHash('sha256');
    for await (const chunk of createReadStream(path)) hash.update(chunk);
    return { sizeBytes: (await stat(path)).size, sha256: hash.digest('hex') };
  },
};
