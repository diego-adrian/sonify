# Transcodificador de Sonify para Cloud Run: Node 24 (ejecuta TypeScript
# directo) + ffmpeg de Debian (con AAC y libwebp).
FROM node:24-slim AS base
RUN apt-get update \
  && apt-get install -y --no-install-recommends ffmpeg \
  && rm -rf /var/lib/apt/lists/*
RUN corepack enable
WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml* ./

# `docker build --target test .` corre las pruebas con este mismo ffmpeg.
FROM base AS test
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm check && pnpm test

FROM base
RUN pnpm install --prod --frozen-lockfile
COPY src ./src
USER node
ENV NODE_ENV=production
CMD ["node", "src/server.ts"]
