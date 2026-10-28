import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@2.118.0';

import { requireEnv } from './http.ts';

const url = requireEnv('SUPABASE_URL');

/** Clave con privilegios de servidor (nueva `sb_secret_...` o la legacy). */
function secretKey(): string {
  const keys = Deno.env.get('SUPABASE_SECRET_KEYS');
  if (keys) {
    const parsed = JSON.parse(keys) as Record<string, string>;
    if (parsed['default']) return parsed['default'];
  }
  return requireEnv('SUPABASE_SERVICE_ROLE_KEY');
}

/** Cliente que ignora RLS. Solo para lo que el backend hace en nombre del usuario. */
export const admin: SupabaseClient = createClient(url, secretKey(), {
  auth: { persistSession: false, autoRefreshToken: false },
});

/**
 * Devuelve el id del usuario si el `Authorization: Bearer <jwt>` es válido.
 * Con llaves de firma asimétricas (proyectos nuevos) `getClaims` verifica el
 * token localmente contra el JWKS, sin llamar al servidor de Auth.
 */
export async function authenticate(req: Request): Promise<string | null> {
  const header = req.headers.get('Authorization') ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (!token) return null;
  const { data, error } = await admin.auth.getClaims(token);
  if (error || !data?.claims?.sub || data.claims.role !== 'authenticated') {
    return null;
  }
  return data.claims.sub as string;
}
