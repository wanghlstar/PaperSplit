import { loadImage, createCanvas } from '@napi-rs/canvas';
import { writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const S = 1024;

const canvas = createCanvas(S, S);
const ctx = canvas.getContext('2d');

function roundRect(x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}

const bg = ctx.createLinearGradient(0, 0, S, S);
bg.addColorStop(0, '#6366f1');
bg.addColorStop(0.55, '#4f46e5');
bg.addColorStop(1, '#312e81');
ctx.fillStyle = bg;
roundRect(0, 0, S, S, 200);
ctx.fill();

const glow = ctx.createRadialGradient(300, 220, 0, 300, 220, 900);
glow.addColorStop(0, 'rgba(255,255,255,0.22)');
glow.addColorStop(1, 'rgba(255,255,255,0)');
ctx.fillStyle = glow;
ctx.fillRect(0, 0, S, S);

const pageSize = 680;
const pageX = (S - pageSize) / 2;
const pageY = (S - pageSize) / 2;

ctx.save();
ctx.shadowColor = 'rgba(0,0,0,0.32)';
ctx.shadowBlur = 48;
ctx.shadowOffsetY = 16;
ctx.fillStyle = '#ffffff';
roundRect(pageX, pageY, pageSize, pageSize, 64);
ctx.fill();
ctx.restore();

const logo = await loadImage(join(ROOT, 'public', 'favicon.png'));
ctx.save();
roundRect(pageX, pageY, pageSize, pageSize, 64);
ctx.clip();
ctx.drawImage(logo, pageX, pageY, pageSize, pageSize);
ctx.restore();

writeFileSync(join(ROOT, 'packaging', 'macos', 'AppIcon-1024.png'), canvas.toBuffer('image/png'));
