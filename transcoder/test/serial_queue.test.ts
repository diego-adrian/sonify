import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { SerialQueue } from '../src/application/serial_queue.ts';

const tick = () => new Promise((resolve) => setTimeout(resolve, 5));

describe('SerialQueue', () => {
  it('5 canciones a la vez se procesan de a una, en orden', async () => {
    const queue = new SerialQueue<string>();
    let running = 0;
    let maxRunning = 0;
    const order: string[] = [];

    const results = await Promise.all(
      ['a', 'b', 'c', 'd', 'e'].map((id) =>
        queue.run(id, async () => {
          running++;
          maxRunning = Math.max(maxRunning, running);
          await tick();
          order.push(id);
          running--;
          return `ready:${id}`;
        }),
      ),
    );

    assert.equal(maxRunning, 1);
    assert.deepEqual(order, ['a', 'b', 'c', 'd', 'e']);
    assert.deepEqual(results, ['ready:a', 'ready:b', 'ready:c', 'ready:d', 'ready:e']);
    await tick();
    assert.equal(queue.size, 0);
  });

  it('la misma canción repetida (reintento del cron) no se procesa dos veces', async () => {
    const queue = new SerialQueue<number>();
    let calls = 0;
    const job = async () => {
      calls++;
      await tick();
      return calls;
    };

    const [first, second] = await Promise.all([queue.run('x', job), queue.run('x', job)]);

    assert.equal(calls, 1);
    assert.equal(first, second);
  });

  it('un trabajo que falla no frena a los siguientes', async () => {
    const queue = new SerialQueue<string>();
    const failing = queue.run('bad', async () => {
      throw new Error('ffmpeg');
    });
    const next = queue.run('good', async () => 'ok');

    await assert.rejects(failing);
    assert.equal(await next, 'ok');
  });
});
