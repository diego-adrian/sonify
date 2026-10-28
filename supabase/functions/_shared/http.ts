export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

export function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Falta la variable de entorno ${name}`);
  return value;
}

/** Envuelve el handler: cualquier excepción se registra y responde 500 JSON. */
export function serve(handler: (req: Request) => Promise<Response>): void {
  Deno.serve(async (req) => {
    try {
      return await handler(req);
    } catch (error) {
      console.error(error);
      return json({ error: 'internal' }, 500);
    }
  });
}
