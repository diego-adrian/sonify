// Genera ícono de la app, pantalla de arranque y logo del Login a partir de
// sonify_simbolo.svg. Cada tamaño se rasteriza desde el vector (nada se
// escala desde un PNG). Uso: pnpm install && pnpm generate
import { Resvg } from '@resvg/resvg-js';
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';

const root = path.resolve(import.meta.dirname, '..');
const source = fs.readFileSync(path.join(import.meta.dirname, 'sonify_simbolo.svg'), 'utf8');

// Fondo del modo oscuro (`#100F18`): el logo está pensado sobre oscuro.
const background = '#100F18';
// Centro y ancho del símbolo (sin el resplandor) en las unidades del SVG.
const centerX = 296;
const centerY = 186;
const symbolWidth = 532;

/** El SVG con otro viewBox, un fondo opcional y, si se pide, en un solo color. */
function symbolSvg({ x, y, width, height, fill, monochrome = false }) {
  let svg = source.replace(/width="\d+" height="\d+" viewBox="[^"]+"/, `width="${width}" height="${height}" viewBox="${x} ${y} ${width} ${height}"`);
  if (fill) {
    svg = svg.replace('</defs>', `</defs><rect x="${x}" y="${y}" width="${width}" height="${height}" fill="${fill}"/>`);
  }
  if (monochrome) {
    svg = svg.replaceAll(/fill="url\(#warm2?\)"/g, 'fill="#FFFFFF"').replace(' filter="url(#glow)"', '');
  }
  return svg;
}

/** Cuadrado centrado en el símbolo, que ocupa `fraction` del ancho. */
function square(fraction, options = {}) {
  const side = symbolWidth / fraction;
  return symbolSvg({ x: centerX - side / 2, y: centerY - side / 2, width: side, height: side, ...options });
}

// Recorte justo con el resplandor (para el Login y la pantalla de arranque).
const tight = symbolSvg({ x: 8, y: -10, width: 576, height: 392 });

function render(svg, width) {
  return new Resvg(svg, { fitTo: { mode: 'width', value: width } }).render();
}

function write(file, png) {
  const target = path.join(root, file);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, png);
  console.log(file);
}

/** PNG sin canal alfa: App Store rechaza el ícono de 1024 con transparencia. */
function opaquePng(image) {
  const { width, height, pixels } = image;
  const raw = Buffer.alloc((width * 3 + 1) * height);
  for (let y = 0; y < height; y++) {
    const row = y * (width * 3 + 1);
    for (let x = 0; x < width; x++) {
      const from = (y * width + x) * 4;
      pixels.copy(raw, row + 1 + x * 3, from, from + 3);
    }
  }
  const chunk = (type, data) => {
    const length = Buffer.alloc(4);
    length.writeUInt32BE(data.length);
    const body = Buffer.concat([Buffer.from(type), data]);
    const crc = Buffer.alloc(4);
    crc.writeUInt32BE(zlib.crc32(body));
    return Buffer.concat([length, body, crc]);
  };
  const header = Buffer.alloc(13);
  header.writeUInt32BE(width, 0);
  header.writeUInt32BE(height, 4);
  header.set([8, 2, 0, 0, 0], 8); // 8 bits, RGB
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', header),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

// iOS: ícono a sangre (iOS redondea las esquinas). Tamaños según el nombre.
const iosIcon = square(0.7, { fill: background });
const iconSet = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
for (const name of fs.readdirSync(path.join(root, iconSet))) {
  const match = name.match(/^Icon-App-([\d.]+)x[\d.]+@(\d)x\.png$/);
  if (match) write(`${iconSet}/${name}`, opaquePng(render(iosIcon, Number(match[1]) * Number(match[2]))));
}

// iOS: pantalla de arranque (fondo en LaunchScreen.storyboard), 120 pt de ancho.
for (const [suffix, scale] of [['', 1], ['@2x', 2], ['@3x', 3]]) {
  write(`ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage${suffix}.png`, render(tight, 120 * scale).asPng());
}

// Android: densidades.
const densities = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };
const res = 'android/app/src/main/res';
// Ícono adaptativo (API 26+): capa de 108 dp; el símbolo entra en el círculo
// seguro de 66 dp (su diagonal mide ~1,2 veces su ancho).
const foreground = square(0.5);
const monochrome = square(0.5, { monochrome: true });
const legacy = square(0.7, { fill: background });
for (const [density, scale] of Object.entries(densities)) {
  write(`${res}/mipmap-${density}/ic_launcher.png`, render(legacy, 48 * scale).asPng());
  write(`${res}/mipmap-${density}/ic_launcher_foreground.png`, render(foreground, 108 * scale).asPng());
  write(`${res}/mipmap-${density}/ic_launcher_monochrome.png`, render(monochrome, 108 * scale).asPng());
  write(`${res}/drawable-${density}/launch_logo.png`, render(tight, 120 * scale).asPng());
  // Notificación del reproductor (barra de estado): silueta blanca de 24 dp
  // con 1 dp de margen. Android solo usa su transparencia.
  write(`${res}/drawable-${density}/ic_stat_sonify.png`, render(square(22 / 24, { monochrome: true }), 24 * scale).asPng());
}

// Logo del Login: 120 px lógicos de ancho (variantes 2.0x y 3.0x de Flutter).
for (const [dir, scale] of [['', 1], ['2.0x/', 2], ['3.0x/', 3]]) {
  write(`assets/images/${dir}sonify_symbol.png`, render(tight, 120 * scale).asPng());
}
