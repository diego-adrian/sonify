// Prueba real con ffmpeg (se salta si no está instalado).
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, rmSync, statSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { after, describe, it } from 'node:test';

import { ffmpegMediaTool } from '../src/infrastructure/ffmpeg_media_tool.ts';

const hasFfmpeg = (() => {
  try {
    execFileSync('ffmpeg', ['-version']);
    return true;
  } catch {
    return false;
  }
})();

const probe = (path: string, entries: string) =>
  execFileSync('ffprobe', ['-v', 'error', '-show_entries', entries, '-of', 'csv=p=0', path])
    .toString()
    .trim();

describe('ffmpegMediaTool', { skip: !hasFfmpeg && 'ffmpeg no instalado' }, () => {
  const dir = mkdtempSync(join(tmpdir(), 'sonify-test-'));
  after(() => rmSync(dir, { recursive: true, force: true }));
  const tool = ffmpegMediaTool();

  it('normaliza y codifica AAC 96/128/256 de un WAV', async () => {
    const input = join(dir, 'in.wav');
    execFileSync('ffmpeg', ['-v', 'error', '-f', 'lavfi', '-i', 'sine=frequency=440:duration=3', '-ac', '1', '-ar', '48000', input]);
    const outputs = { 96: join(dir, '96.m4a'), 128: join(dir, '128.m4a'), 256: join(dir, '256.m4a') };

    await tool.transcodeAudio(input, outputs);

    for (const path of Object.values(outputs)) {
      assert.equal(probe(path, 'stream=codec_name,channels,sample_rate'), 'aac,44100,2');
    }
    const duration = await tool.durationMs(outputs[128]);
    assert.ok(Math.abs(duration - 3000) < 100, `${duration}`);
    assert.ok(statSync(outputs[256]).size > statSync(outputs[96]).size);
  });

  const hasWebp = execFileSync('ffmpeg', ['-hide_banner', '-encoders']).toString().includes('libwebp');

  // La imagen de Cloud Run (Debian) trae libwebp; el ffmpeg de Homebrew no.
  it('recorta al centro y genera WebP cuadrados', { skip: !hasWebp && 'ffmpeg sin libwebp' }, async () => {
    const input = join(dir, 'cover.jpg');
    execFileSync('ffmpeg', ['-v', 'error', '-f', 'lavfi', '-i', 'testsrc=size=1280x720', '-frames:v', '1', input]);
    const outputs = { 200: join(dir, '200.webp'), 640: join(dir, '640.webp') };

    await tool.transcodeCover(input, outputs);

    assert.equal(probe(outputs[200], 'stream=codec_name,width,height'), 'webp,200,200');
    assert.equal(probe(outputs[640], 'stream=codec_name,width,height'), 'webp,640,640');
  });
});
