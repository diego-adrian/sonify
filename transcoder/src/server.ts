// Composition root del transcodificador (Cloud Run). Supabase lo llama con
// `POST /transcode {"song_id": "…"}` cuando una canción pasa a `processing`.
import { timingSafeEqual } from 'node:crypto';
import { createServer, type IncomingMessage } from 'node:http';

import { transcodeSong, type TranscodeDeps } from './application/transcode_song.ts';
import { b2ObjectStore } from './infrastructure/b2_object_store.ts';
import { ffmpegMediaTool } from './infrastructure/ffmpeg_media_tool.ts';
import { localFiles } from './infrastructure/local_files.ts';
import { supabaseSongStore } from './infrastructure/supabase_song_store.ts';

function env(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Falta la variable de entorno ${name}`);
  return value;
}

const secret = Buffer.from(env('TRANSCODER_SECRET'));
const deps: TranscodeDeps = {
  songs: supabaseSongStore(env('SUPABASE_URL'), env('SUPABASE_SECRET_KEY')),
  store: b2ObjectStore({
    keyId: env('B2_KEY_ID'),
    applicationKey: env('B2_APPLICATION_KEY'),
    bucket: env('B2_BUCKET'),
    endpoint: env('B2_ENDPOINT'),
  }),
  media: ffmpegMediaTool(),
  files: localFiles,
  log: (message, error) => console.error(message, error ?? ''),
};

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

function authorized(req: IncomingMessage): boolean {
  const given = Buffer.from(String(req.headers['x-transcoder-secret'] ?? ''));
  return given.length === secret.length && timingSafeEqual(given, secret);
}

async function readJson(req: IncomingMessage): Promise<unknown> {
  let body = '';
  for await (const chunk of req) {
    body += chunk;
    if (body.length > 4096) throw new Error('body too large');
  }
  return JSON.parse(body);
}

const server = createServer(async (req, res) => {
  const reply = (status: number, body: object) => {
    res.writeHead(status, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(body));
  };

  if (req.method === 'GET' && req.url === '/healthz') return reply(200, { ok: true });
  if (req.method !== 'POST' || req.url !== '/transcode') return reply(404, { error: 'not_found' });
  if (!authorized(req)) return reply(401, { error: 'unauthorized' });

  let songId: unknown;
  try {
    songId = ((await readJson(req)) as { song_id?: unknown }).song_id;
  } catch {
    return reply(400, { error: 'bad_json' });
  }
  if (typeof songId !== 'string' || !UUID.test(songId)) {
    return reply(400, { error: 'bad_song_id' });
  }

  // Se responde al terminar: en Cloud Run la CPU solo está asignada mientras
  // hay una petición abierta.
  const started = Date.now();
  try {
    const outcome = await transcodeSong(songId, deps);
    console.log(JSON.stringify({ songId, outcome, ms: Date.now() - started }));
    reply(200, { outcome });
  } catch (error) {
    console.error('transcode crashed', songId, error);
    reply(500, { error: 'internal' });
  }
});

server.listen(Number(process.env.PORT ?? 8080));
