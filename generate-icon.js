const { createCanvas } = require('canvas');
const fs = require('fs');
const path = require('path');

const SIZE = 1024;
const canvas = createCanvas(SIZE, SIZE);
const ctx = canvas.getContext('2d');

// 圆角矩形背景
const radius = 224;
ctx.beginPath();
ctx.moveTo(radius, 0);
ctx.lineTo(SIZE - radius, 0);
ctx.quadraticCurveTo(SIZE, 0, SIZE, radius);
ctx.lineTo(SIZE, SIZE - radius);
ctx.quadraticCurveTo(SIZE, SIZE, SIZE - radius, SIZE);
ctx.lineTo(radius, SIZE);
ctx.quadraticCurveTo(0, SIZE, 0, SIZE - radius);
ctx.lineTo(0, radius);
ctx.quadraticCurveTo(0, 0, radius, 0);
ctx.closePath();

// 渐变背景：魔法紫 → 温暖橙
const bgGradient = ctx.createLinearGradient(0, 0, SIZE, SIZE);
bgGradient.addColorStop(0, '#6366F1');
bgGradient.addColorStop(0.5, '#8B5CF6');
bgGradient.addColorStop(1, '#F59E0B');
ctx.fillStyle = bgGradient;
ctx.fill();

// 闪电阴影
ctx.shadowColor = 'rgba(99, 102, 241, 0.4)';
ctx.shadowBlur = 40;
ctx.shadowOffsetY = 16;

// 闪电路径
ctx.beginPath();
ctx.moveTo(580, 180);
ctx.lineTo(380, 480);
ctx.lineTo(480, 480);
ctx.lineTo(420, 844);
ctx.lineTo(680, 460);
ctx.lineTo(560, 460);
ctx.lineTo(580, 180);
ctx.closePath();

// 闪电渐变填充
const boltGradient = ctx.createLinearGradient(420, 180, 420, 844);
boltGradient.addColorStop(0, '#FFFFFF');
boltGradient.addColorStop(1, '#FEF3C7');
ctx.fillStyle = boltGradient;
ctx.fill();

// 保存 PNG
const outPath = path.join(__dirname, 'Assets', 'AppIcon.png');
const buffer = canvas.toBuffer('image/png');
fs.writeFileSync(outPath, buffer);
console.log('✅ 图标已生成:', outPath);
