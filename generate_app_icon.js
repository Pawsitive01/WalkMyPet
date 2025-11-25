#!/usr/bin/env node
/**
 * Generate WalkMyPet app icon with paw logo
 * Uses node-canvas to create a gradient background with paw print
 */

const fs = require('fs');
const path = require('path');

// Try to load canvas, install if needed
let Canvas;
try {
  Canvas = require('canvas');
} catch (e) {
  console.log('Installing canvas package...');
  require('child_process').execSync('npm install canvas', { stdio: 'inherit' });
  Canvas = require('canvas');
}

const { createCanvas } = Canvas;

function createGradient(ctx, width, height, color1, color2) {
  const gradient = ctx.createLinearGradient(0, 0, width, height);
  gradient.addColorStop(0, color1);
  gradient.addColorStop(1, color2);
  return gradient;
}

function drawPaw(ctx, cx, cy, size, color) {
  ctx.fillStyle = color;

  // Main pad (larger, bottom)
  const padWidth = size * 0.6;
  const padHeight = size * 0.5;

  ctx.beginPath();
  ctx.ellipse(
    cx,
    cy + size * 0.4,
    padWidth / 2,
    padHeight / 2,
    0,
    0,
    Math.PI * 2
  );
  ctx.fill();

  // Toe pads (4 smaller circles above main pad)
  const toeSize = size * 0.22;
  const toePositions = [
    { x: cx - size * 0.35, y: cy - size * 0.15 },  // Left toe
    { x: cx - size * 0.12, y: cy - size * 0.35 },  // Left-center toe
    { x: cx + size * 0.12, y: cy - size * 0.35 },  // Right-center toe
    { x: cx + size * 0.35, y: cy - size * 0.15 },  // Right toe
  ];

  toePositions.forEach(pos => {
    ctx.beginPath();
    ctx.arc(pos.x, pos.y, toeSize / 2, 0, Math.PI * 2);
    ctx.fill();
  });
}

function createIcon(size, foregroundOnly = false) {
  const canvas = createCanvas(size, size);
  const ctx = canvas.getContext('2d');

  if (!foregroundOnly) {
    // Gradient background: #6366F1 (indigo) to #8B5CF6 (purple)
    const gradient = createGradient(
      ctx,
      size,
      size,
      'rgb(99, 102, 241)',
      'rgb(139, 92, 246)'
    );
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, size, size);
  }

  // Draw white paw in center
  const centerX = size / 2;
  const centerY = size / 2;
  const pawSize = size * 0.45;

  drawPaw(ctx, centerX, centerY, pawSize, 'white');

  return canvas;
}

async function main() {
  console.log('🐾 Generating WalkMyPet app icons...');

  // Ensure assets/icon directory exists
  const iconDir = path.join(__dirname, 'assets', 'icon');
  if (!fs.existsSync(iconDir)) {
    fs.mkdirSync(iconDir, { recursive: true });
  }

  // Create main icon (1024x1024 for iOS, will be resized by flutter_launcher_icons)
  console.log('Creating main icon (1024x1024)...');
  const icon1024 = createIcon(1024);
  const iconPath = path.join(iconDir, 'app_icon.png');
  const buffer = icon1024.toBuffer('image/png');
  fs.writeFileSync(iconPath, buffer);

  // Create adaptive icon foreground (transparent background)
  console.log('Creating adaptive icon foreground (1024x1024)...');
  const foreground = createIcon(1024, true);
  const foregroundPath = path.join(iconDir, 'app_icon_foreground.png');
  const foregroundBuffer = foreground.toBuffer('image/png');
  fs.writeFileSync(foregroundPath, foregroundBuffer);

  console.log('✅ Icons generated successfully!');
  console.log('📁 Saved to:');
  console.log(`   - ${iconPath}`);
  console.log(`   - ${foregroundPath}`);
  console.log('\nNext step: Run "dart run flutter_launcher_icons"');
}

main().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
