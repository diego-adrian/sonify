import { AwsClient } from 'npm:aws4fetch@1.0.20';

import { requireEnv } from './http.ts';

// Backblaze B2 por su API compatible con S3.
// B2_ENDPOINT: p. ej. "s3.us-east-005.backblazeb2.com".
// Se configura al primer uso: si falta un secreto, la petición falla con un
// error claro en los logs en lugar de tumbar la función al arrancar.
type B2 = { client: AwsClient; endpoint: string; bucket: string };
let b2: B2 | undefined;

function getB2(): B2 {
  if (b2) return b2;
  const endpoint = requireEnv('B2_ENDPOINT');
  b2 = {
    endpoint,
    bucket: requireEnv('B2_BUCKET'),
    client: new AwsClient({
      accessKeyId: requireEnv('B2_KEY_ID'),
      secretAccessKey: requireEnv('B2_APPLICATION_KEY'),
      service: 's3',
      region: endpoint.split('.')[1],
    }),
  };
  return b2;
}

function objectUrl(key: string): URL {
  const { bucket, endpoint } = getB2();
  const path = key.split('/').map(encodeURIComponent).join('/');
  return new URL(`https://${bucket}.${endpoint}/${path}`);
}

/** URL prefirmada para subir exactamente esa key, con ese Content-Type. */
export async function presignPut(
  key: string,
  contentType: string,
  expiresSeconds: number,
): Promise<string> {
  const url = objectUrl(key);
  url.searchParams.set('X-Amz-Expires', String(expiresSeconds));
  const signed = await getB2().client.sign(url, {
    method: 'PUT',
    headers: { 'Content-Type': contentType },
    aws: { signQuery: true },
  });
  return signed.url;
}

/** Tamaño del objeto o `null` si no existe. */
export async function headSize(key: string): Promise<number | null> {
  const res = await getB2().client.fetch(objectUrl(key), { method: 'HEAD' });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`B2 HEAD ${res.status}`);
  return Number(res.headers.get('Content-Length') ?? '0');
}

export async function deleteObject(key: string): Promise<void> {
  const res = await getB2().client.fetch(objectUrl(key), { method: 'DELETE' });
  if (!res.ok && res.status !== 404) throw new Error(`B2 DELETE ${res.status}`);
}
