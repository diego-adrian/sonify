// URLs firmadas: `/{key}?exp={unix}&sig={hex(HMAC-SHA256(secret, "{key}:{exp}"))}`.
// Las firma Postgres (`private.media_path`) solo para canciones que el usuario
// puede leer según RLS; aquí solo se comprueba la firma, sin llamar a Supabase.

/** Defensa extra: ninguna URL legítima dura más que esto. */
export const MAX_URL_LIFETIME_SECONDS = 7 * 86400;

const encoder = new TextEncoder();

export function importSigningKey(secret: string): Promise<CryptoKey> {
  return crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign', 'verify'],
  );
}

export async function signMediaKey(
  signingKey: CryptoKey,
  key: string,
  exp: number,
): Promise<string> {
  const mac = await crypto.subtle.sign(
    'HMAC',
    signingKey,
    encoder.encode(`${key}:${exp}`),
  );
  return [...new Uint8Array(mac)]
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

export async function verifyMediaSignature(
  signingKey: CryptoKey,
  key: string,
  exp: string | null,
  sig: string | null,
  nowSeconds: number,
): Promise<boolean> {
  if (!exp || !sig || !/^\d{1,12}$/.test(exp) || !/^[0-9a-f]{64}$/.test(sig)) {
    return false;
  }
  const expires = Number(exp);
  if (expires < nowSeconds || expires - nowSeconds > MAX_URL_LIFETIME_SECONDS) {
    return false;
  }
  const mac = new Uint8Array(32);
  for (let i = 0; i < 32; i++) {
    mac[i] = parseInt(sig.slice(i * 2, i * 2 + 2), 16);
  }
  // `verify` compara en tiempo constante.
  return crypto.subtle.verify(
    'HMAC',
    signingKey,
    mac,
    encoder.encode(`${key}:${exp}`),
  );
}
