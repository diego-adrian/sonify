import { AwsClient } from 'aws4fetch';

import type { ObjectStore } from '../application/serve_media.ts';

export type B2Config = {
  keyId: string;
  applicationKey: string;
  bucket: string;
  /** p. ej. "s3.us-east-005.backblazeb2.com". */
  endpoint: string;
};

/** B2 por su API compatible con S3, con una Application Key de solo lectura. */
export function b2ObjectStore(config: B2Config): ObjectStore {
  const client = new AwsClient({
    accessKeyId: config.keyId,
    secretAccessKey: config.applicationKey,
    service: 's3',
    region: config.endpoint.split('.')[1],
    // Por defecto reintenta 10 veces; para un CDN es demasiado.
    retries: 2,
  });
  const base = `https://${config.bucket}.${config.endpoint}`;

  return {
    fetch(key, { method, range }) {
      return client.fetch(`${base}/${key}`, {
        method,
        headers: range ? { Range: range } : undefined,
      });
    },
  };
}
