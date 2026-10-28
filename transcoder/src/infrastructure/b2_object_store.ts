import { createWriteStream } from 'node:fs';
import { readFile } from 'node:fs/promises';
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';
import type { ReadableStream } from 'node:stream/web';

import { AwsClient } from 'aws4fetch';

import type { ObjectStore } from '../application/transcode_song.ts';

export type B2Config = {
  keyId: string;
  applicationKey: string;
  bucket: string;
  /** p. ej. "s3.us-east-005.backblazeb2.com". */
  endpoint: string;
};

// Lo generado es inmutable: si cambia, cambia la key.
const IMMUTABLE = 'public, max-age=31536000, immutable';

/** B2 por su API compatible con S3. */
export function b2ObjectStore(config: B2Config): ObjectStore {
  const client = new AwsClient({
    accessKeyId: config.keyId,
    secretAccessKey: config.applicationKey,
    service: 's3',
    region: config.endpoint.split('.')[1],
    retries: 3,
  });
  const url = (key: string) =>
    `https://${config.bucket}.${config.endpoint}/${key.split('/').map(encodeURIComponent).join('/')}`;

  return {
    async download(key, path) {
      const res = await client.fetch(url(key));
      if (!res.ok || !res.body) {
        throw new Error(`B2 GET ${res.status} ${key}`);
      }
      // Por streaming: el original puede pesar hasta 200 MB.
      await pipeline(
        Readable.fromWeb(res.body as ReadableStream<Uint8Array>),
        createWriteStream(path),
      );
    },

    async upload(key, path, contentType) {
      const res = await client.fetch(url(key), {
        method: 'PUT',
        body: await readFile(path),
        headers: { 'Content-Type': contentType, 'Cache-Control': IMMUTABLE },
      });
      if (!res.ok) {
        throw new Error(`B2 PUT ${res.status} ${key}: ${await res.text()}`);
      }
    },
  };
}
