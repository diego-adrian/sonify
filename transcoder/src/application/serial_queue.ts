/**
 * Ejecuta los trabajos de a uno, en orden de llegada. Si llega otra vez una
 * clave que ya está en cola o en curso (p. ej. el reintento del cron mientras
 * se procesa), devuelve la misma promesa en lugar de repetir el trabajo.
 *
 * La instancia gratis tiene 512 MB: varios ffmpeg a la vez la dejarían sin
 * memoria.
 */
export class SerialQueue<T> {
  #tail: Promise<unknown> = Promise.resolve();
  readonly #pending = new Map<string, Promise<T>>();

  /** Trabajos en cola o en curso. */
  get size(): number {
    return this.#pending.size;
  }

  run(key: string, job: () => Promise<T>): Promise<T> {
    const existing = this.#pending.get(key);
    if (existing) return existing;

    const result = this.#tail.then(job);
    this.#pending.set(key, result);
    this.#tail = result.catch(() => {}).finally(() => this.#pending.delete(key));
    return result;
  }
}
