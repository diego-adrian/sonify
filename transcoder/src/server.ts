// Composition root del transcodificador (Render). Supabase lo llama con
// `POST /transcode {"song_id": "…"}` cuando una canción pasa a `processing`.
import { timingSafeEqual } from 'node:crypto';
import { createServer, type IncomingMessage } from 'node:http';

import { SerialQueue } from './application/serial_queue.ts';
import {
  transcodeSong,
  type TranscodeDeps,
  type TranscodeOutcome,
} from './application/transcode_song.ts';
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

// De a una canción: si llegan varias juntas, esperan su turno con la
// petición abierta (eso además evita que Render duerma la instancia).
const queue = new SerialQueue<TranscodeOutcome>();

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

  // Se responde al terminar (o al terminar la cola de delante).
  const started = Date.now();
  const id = songId;
  try {
    const outcome = await queue.run(id, () => transcodeSong(id, deps));
    console.log(
      JSON.stringify({ songId, outcome, ms: Date.now() - started, queued: queue.size }),
    );
    reply(200, { outcome });
  } catch (error) {
    console.error('transcode crashed', songId, error);
    reply(500, { error: 'internal' });
  }
});

server.listen(Number(process.env.PORT ?? 8080));
