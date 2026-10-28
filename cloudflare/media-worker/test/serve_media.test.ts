import assert from 'node:assert/strict';
import { beforeEach, describe, it } from 'node:test';

import {
  serveMedia,
  type MediaCache,
  type MediaRequest,
  type ObjectStore,
} from '../src/application/serve_media.ts';
import { parseMediaKey } from '../src/domain/media_key.ts';
import {
  importSigningKey,
  signMediaKey,
  verifyMediaSignature,
} from '../src/domain/signed_url.ts';

const SONG = '6c1a7434-8320-4ed6-b003-da0c3f40ba51';
const AUDIO = `audio/${SONG}/128.m4a`;
const NOW = 1_800_000_000;
const EXP = NOW + 86400;

describe('parseMediaKey', () => {
  it('acepta audio y portadas transcodificados', () => {
    assert.equal(parseMediaKey(`/${AUDIO}`)?.contentType, 'audio/mp4');
    assert.equal(parseMediaKey(`/covers/${SONG}/200.webp`)?.contentType, 'image/webp');
  });

  it('nunca sirve originales ni rutas raras', () => {
    for (const path of [
      `/originals/${SONG}/${SONG}.wav`,
      `/audio/${SONG}/320.m4a`,
      `/audio/${SONG}/../128.m4a`,
      `/audio/${SONG.toUpperCase()}/128.m4a`,
      '/',
    ]) {
      assert.equal(parseMediaKey(path), null, path);
    }
  });
});

describe('verifyMediaSignature', () => {
  it('acepta su firma y rechaza alteraciones', async () => {
    const key = await importSigningKey('secret');
    const sig = await signMediaKey(key, AUDIO, EXP);
    assert.equal(await verifyMediaSignature(key, AUDIO, `${EXP}`, sig, NOW), true);
    assert.equal(await verifyMediaSignature(key, `audio/${SONG}/256.m4a`, `${EXP}`, sig, NOW), false);
    assert.equal(await verifyMediaSignature(key, AUDIO, `${EXP + 1}`, sig, NOW), false);
    const other = await importSigningKey('other');
    assert.equal(await verifyMediaSignature(other, AUDIO, `${EXP}`, sig, NOW), false);
  });

  it('rechaza vencidas, demasiado largas o mal formadas', async () => {
    const key = await importSigningKey('secret');
    const expired = await signMediaKey(key, AUDIO, NOW - 1);
    assert.equal(await verifyMediaSignature(key, AUDIO, `${NOW - 1}`, expired, NOW), false);
    const far = NOW + 30 * 86400;
    const long = await signMediaKey(key, AUDIO, far);
    assert.equal(await verifyMediaSignature(key, AUDIO, `${far}`, long, NOW), false);
    assert.equal(await verifyMediaSignature(key, AUDIO, null, null, NOW), false);
    assert.equal(await verifyMediaSignature(key, AUDIO, `${EXP}`, 'zz', NOW), false);
  });

  it('coincide con la firma de Postgres (pgcrypto hmac)', async () => {
    // select encode(extensions.hmac('audio/x/128.m4a:1800000000', 'test-secret', 'sha256'), 'hex')
    const key = await importSigningKey('test-secret');
    assert.equal(
      await signMediaKey(key, 'audio/x/128.m4a', 1_800_000_000),
      POSTGRES_TEST_SIGNATURE,
    );
  });
});

const POSTGRES_TEST_SIGNATURE = 'd8a9faa85c9f634736f9b612d31985d755e817c53f3543a2d0f234237c91f593';

class FakeStore implements ObjectStore {
  calls: { key: string; method: string; range: string | null }[] = [];
  status = 200;

  async fetch(key: string, init: { method: 'GET' | 'HEAD'; range: string | null }) {
    this.calls.push({ key, ...init });
    if (this.status !== 200) return new Response(null, { status: this.status });
    if (init.range) {
      return new Response('ab', {
        status: 206,
        headers: { 'Content-Range': 'bytes 0-1/6', 'Content-Length': '2', 'x-amz-id-2': 'x' },
      });
    }
    return new Response(init.method === 'HEAD' ? null : 'abcdef', {
      headers: { 'Content-Length': '6', ETag: '"e"', 'x-bz-file-id': 'x' },
    });
  }
}

class FakeCache implements MediaCache {
  stored = new Map<string, string>();

  async match(key: string, range: string | null) {
    const body = this.stored.get(key);
    if (body === undefined) return undefined;
    return range
      ? new Response(body.slice(0, 2), { status: 206, headers: { 'Content-Range': `bytes 0-1/${body.length}` } })
      : new Response(body);
  }

  async put(key: string, response: Response) {
    assert.equal(response.status, 200);
    assert.match(response.headers.get('Cache-Control') ?? '', /immutable/);
    this.stored.set(key, await response.text());
  }
}

describe('serveMedia', () => {
  let store: FakeStore;
  let cache: FakeCache;
  let deferred: Promise<unknown>[];
  let signingKey: CryptoKey;
  let sig: string;

  beforeEach(async () => {
    store = new FakeStore();
    cache = new FakeCache();
    deferred = [];
    signingKey = await importSigningKey('secret');
    sig = await signMediaKey(signingKey, AUDIO, EXP);
  });

  const serve = (overrides: Partial<MediaRequest> = {}) =>
    serveMedia(
      { method: 'GET', pathname: `/${AUDIO}`, exp: `${EXP}`, sig, range: null, ...overrides },
      {
        store,
        cache,
        signingKey,
        nowSeconds: () => NOW,
        defer: (work) => deferred.push(work),
      },
    );

  it('sin firma válida no toca el bucket', async () => {
    assert.equal((await serve({ sig: '0'.repeat(64) })).status, 403);
    assert.equal((await serve({ pathname: `/originals/${SONG}.wav` })).status, 404);
    assert.equal((await serve({ method: 'PUT' })).status, 405);
    assert.equal(store.calls.length, 0);
  });

  it('en un fallo completo responde y llena la caché; luego no va al origen', async () => {
    const first = await serve();
    assert.equal(first.status, 200);
    assert.equal(await first.text(), 'abcdef');
    assert.equal(first.headers.get('Content-Type'), 'audio/mp4');
    assert.equal(first.headers.get('x-bz-file-id'), null);
    await Promise.all(deferred);
    assert.equal(cache.stored.get(AUDIO), 'abcdef');

    const second = await serve({ range: 'bytes=0-1' });
    assert.equal(second.status, 206);
    assert.equal(await second.text(), 'ab');
    assert.equal(store.calls.length, 1);
  });

  it('un rango sin caché responde el 206 del origen y cachea el archivo entero aparte', async () => {
    const res = await serve({ range: 'bytes=0-1' });
    assert.equal(res.status, 206);
    assert.equal(res.headers.get('Content-Range'), 'bytes 0-1/6');
    assert.equal(await res.text(), 'ab');
    await Promise.all(deferred);
    assert.deepEqual(store.calls.map((c) => c.range), ['bytes=0-1', null]);
    assert.equal(cache.stored.get(AUDIO), 'abcdef');
  });

  it('HEAD no descarga ni cachea', async () => {
    const res = await serve({ method: 'HEAD' });
    assert.equal(res.status, 200);
    assert.equal(res.headers.get('Content-Length'), '6');
    assert.equal(res.body, null);
    assert.equal(deferred.length, 0);
  });

  it('404 del origen pasa como 404 y otros errores como 502, sin cachear', async () => {
    store.status = 404;
    assert.equal((await serve()).status, 404);
    store.status = 500;
    assert.equal((await serve()).status, 502);
    assert.equal(cache.stored.size, 0);
  });
});
