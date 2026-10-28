import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import {
  audioKey,
  coverKey,
  encodeAudioArgs,
  parseLoudness,
} from '../src/domain/media_plan.ts';

const SONG = 'e4a31669-62e6-4fe1-aa5f-dc45232fb22d';

describe('media_plan', () => {
  it('keys que entiende el CDN', () => {
    assert.equal(audioKey(SONG, 128), `audio/${SONG}/128.m4a`);
    assert.equal(coverKey(SONG, 200), `covers/${SONG}/200.webp`);
  });

  it('lee la medición de loudnorm del final de stderr', () => {
    const stderr = `size=N/A time=00:03:12\n[Parsed_loudnorm_0 @ 0x1] \n{\n\t"input_i" : "-9.81",\n\t"input_tp" : "0.42",\n\t"input_lra" : "5.10",\n\t"input_thresh" : "-19.94",\n\t"output_i" : "-14.01",\n\t"target_offset" : "0.02"\n}\n`;
    assert.deepEqual(parseLoudness(stderr), {
      inputI: '-9.81',
      inputTp: '0.42',
      inputLra: '5.10',
      inputThresh: '-19.94',
      targetOffset: '0.02',
    });
  });

  it('silencio (-inf) o sin JSON → normalización dinámica', () => {
    assert.equal(parseLoudness('{"input_i" : "-inf", "input_tp" : "-inf", "input_lra" : "0.00", "input_thresh" : "-inf", "target_offset" : "inf"}'), null);
    assert.equal(parseLoudness('error'), null);
    const args = encodeAudioArgs('in.wav', { 96: 'a', 128: 'b', 256: 'c' }, null).join(' ');
    assert.match(args, /loudnorm=I=-14:TP=-1.5:LRA=11,aresample/);
  });

  it('codifica las tres calidades con faststart y sin metadatos', () => {
    const args = encodeAudioArgs('in.wav', { 96: 'o96', 128: 'o128', 256: 'o256' }, {
      inputI: '-9', inputTp: '0', inputLra: '5', inputThresh: '-19', targetOffset: '0',
    });
    for (const q of [96, 128, 256]) {
      const at = args.indexOf(`o${q}`);
      assert.deepEqual(args.slice(at - 12, at), [
        '-map', `[a${q}]`, '-map_metadata', '-1', '-ac', '2', '-c:a', 'aac',
        '-b:a', `${q}k`, '-movflags', '+faststart',
      ]);
    }
    assert.match(args.join(' '), /linear=true/);
  });
});
