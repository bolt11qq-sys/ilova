// Generates the launcher icon PNGs without any image library: a green rounded
// square with a white "Y", rendered 4× and downsampled for anti-aliasing.
//
//   node tool/make_icons.mjs
//
// Writes android/app/src/main/res/mipmap-*/ic_launcher.png (legacy, API 24-25)
// and .../drawable/ic_launcher_foreground.png (the adaptive foreground used
// from API 26 on, full-bleed 108 dp with the glyph inside the 66 dp safe zone).

import { deflateSync } from 'node:zlib';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const GREEN = [0x07, 0xab, 0x59];
const WHITE = [0xff, 0xff, 0xff];
const SS = 4; // supersampling factor

/** Signed distance from point p to segment ab. */
function distToSegment(px, py, ax, ay, bx, by) {
  const dx = bx - ax;
  const dy = by - ay;
  const len2 = dx * dx + dy * dy;
  let t = len2 === 0 ? 0 : ((px - ax) * dx + (py - ay) * dy) / len2;
  t = Math.max(0, Math.min(1, t));
  const qx = ax + t * dx;
  const qy = ay + t * dy;
  return Math.hypot(px - qx, py - qy);
}

function insideRoundedRect(x, y, size, radius, inset) {
  const min = inset;
  const max = size - inset;
  if (x < min || y < min || x > max || y > max) return false;
  const r = radius;
  const cx = Math.min(Math.max(x, min + r), max - r);
  const cy = Math.min(Math.max(y, min + r), max - r);
  return Math.hypot(x - cx, y - cy) <= r;
}

/**
 * Renders one icon.
 * @param {number} size output size in pixels
 * @param {{rounded: boolean, glyphScale: number, bleed: boolean}} opts
 */
function renderIcon(size, opts) {
  const S = size * SS;
  const radius = S * 0.225;
  // The "Y": two arms meeting in the middle, then a stem down.
  const g = opts.glyphScale;
  const cx = S / 2;
  const top = S / 2 - (S * g) / 2;
  const mid = S / 2 + (S * g) * 0.02;
  const bottom = S / 2 + (S * g) / 2;
  const armX = (S * g) / 2.15;
  const stroke = S * g * 0.17;

  const out = Buffer.alloc(size * size * 4);

  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      let bg = 0;
      let fg = 0;
      for (let sy = 0; sy < SS; sy++) {
        for (let sx = 0; sx < SS; sx++) {
          const px = x * SS + sx + 0.5;
          const py = y * SS + sy + 0.5;
          const inBg = opts.bleed
            ? true
            : opts.rounded
              ? insideRoundedRect(px, py, S, radius, 0)
              : true;
          if (inBg) bg++;
          const d = Math.min(
            distToSegment(px, py, cx - armX, top, cx, mid),
            distToSegment(px, py, cx + armX, top, cx, mid),
            distToSegment(px, py, cx, mid, cx, bottom),
          );
          if (d <= stroke / 2) fg++;
        }
      }
      const total = SS * SS;
      const alphaBg = bg / total;
      const alphaFg = fg / total;
      const i = (y * size + x) * 4;
      if (opts.transparentBg) {
        // Foreground-only layer: the white glyph on transparency.
        out[i] = WHITE[0];
        out[i + 1] = WHITE[1];
        out[i + 2] = WHITE[2];
        out[i + 3] = Math.round(alphaFg * 255);
      } else {
        const a = Math.max(alphaBg, alphaFg);
        const mixR = alphaFg * WHITE[0] + (1 - alphaFg) * GREEN[0];
        const mixG = alphaFg * WHITE[1] + (1 - alphaFg) * GREEN[1];
        const mixB = alphaFg * WHITE[2] + (1 - alphaFg) * GREEN[2];
        out[i] = Math.round(mixR);
        out[i + 1] = Math.round(mixG);
        out[i + 2] = Math.round(mixB);
        out[i + 3] = Math.round(a * 255);
      }
    }
  }
  return out;
}

function crc32(buf) {
  let c;
  const table = [];
  for (let n = 0; n < 256; n++) {
    c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    table[n] = c >>> 0;
  }
  let crc = 0xffffffff;
  for (const b of buf) crc = table[(crc ^ b) & 0xff] ^ (crc >>> 8);
  return (crc ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
}

function encodePng(rgba, size) {
  const raw = Buffer.alloc((size * 4 + 1) * size);
  for (let y = 0; y < size; y++) {
    raw[y * (size * 4 + 1)] = 0; // filter: none
    rgba.copy(raw, y * (size * 4 + 1) + 1, y * size * 4, (y + 1) * size * 4);
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(size, 0);
  ihdr.writeUInt32BE(size, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 6; // colour type RGBA
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

function write(path, buffer) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, buffer);
  console.log('wrote', path, `(${buffer.length} bytes)`);
}

const root = resolve(process.argv[2] ?? '.', 'android/app/src/main/res');

const legacy = { mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192 };
for (const [density, size] of Object.entries(legacy)) {
  const rgba = renderIcon(size, { rounded: true, glyphScale: 0.52 });
  write(`${root}/mipmap-${density}/ic_launcher.png`, encodePng(rgba, size));
}

// Adaptive foreground: full-bleed canvas, glyph inside the safe zone.
const fg = renderIcon(432, {
  bleed: true,
  transparentBg: true,
  glyphScale: 0.42,
});
write(`${root}/drawable/ic_launcher_foreground.png`, encodePng(fg, 432));
