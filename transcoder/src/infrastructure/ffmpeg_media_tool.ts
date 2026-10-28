import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

import type { MediaTool } from '../application/transcode_song.ts';
import {
  encodeAudioArgs,
  encodeCoverArgs,
  measureArgs,
  parseLoudness,
} from '../domain/media_plan.ts';

const run = promisify(execFile);
const MAX_OUTPUT = 32 * 1024 * 1024;

export function ffmpegMediaTool(ffmpeg = 'ffmpeg', ffprobe = 'ffprobe'): MediaTool {
  return {
    async transcodeAudio(input, outputs) {
      // Dos pasadas de loudnorm: medir y luego aplicar de forma lineal (sin
      // "bombeo" de volumen).
      const { stderr } = await run(ffmpeg, measureArgs(input), { maxBuffer: MAX_OUTPUT });
      await run(ffmpeg, encodeAudioArgs(input, outputs, parseLoudness(stderr)), {
        maxBuffer: MAX_OUTPUT,
      });
    },

    async durationMs(path) {
      const { stdout } = await run(ffprobe, [
        '-v', 'error',
        '-show_entries', 'format=duration',
        '-of', 'csv=p=0',
        path,
      ]);
      const seconds = Number(stdout.trim());
      if (!Number.isFinite(seconds) || seconds <= 0) {
        throw new Error(`duración inválida: ${stdout}`);
      }
      return Math.round(seconds * 1000);
    },

    async transcodeCover(input, outputs) {
      await run(ffmpeg, encodeCoverArgs(input, outputs), { maxBuffer: MAX_OUTPUT });
    },
  };
}
