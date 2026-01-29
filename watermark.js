const sharp = require("sharp");
const fs = require("fs");
const path = require("path");

const WATERMARK_TEXT = "  apoorv darshan  ";
const OPACITY = 0.12; // 12% opacity
const FONT_SIZE = 40;
const TILE_WIDTH = 350;
const TILE_HEIGHT = 200;
const ROTATION_ANGLE = -45;

const subjects = ["physics", "chemistry", "mathematics"];

// Create a single diagonal watermark tile as SVG
function createWatermarkTileSVG() {
  // Calculate rotated text dimensions
  const textWidth = WATERMARK_TEXT.length * (FONT_SIZE * 0.55);

  return Buffer.from(`
    <svg width="${TILE_WIDTH}" height="${TILE_HEIGHT}">
      <defs>
        <style>
          .watermark {
            font-family: Arial, sans-serif;
            font-size: ${FONT_SIZE}px;
            font-weight: bold;
            fill: rgba(128, 128, 128, ${OPACITY});
          }
        </style>
      </defs>
      <text
        x="50%"
        y="50%"
        class="watermark"
        text-anchor="middle"
        dominant-baseline="middle"
        transform="rotate(${ROTATION_ANGLE}, ${TILE_WIDTH / 2}, ${TILE_HEIGHT / 2})"
      >${WATERMARK_TEXT}</text>
    </svg>
  `);
}

// Get all JPG files in a directory recursively
function getAllJpgFiles(dir) {
  const files = [];

  function walkDir(currentDir) {
    const items = fs.readdirSync(currentDir);
    for (const item of items) {
      const fullPath = path.join(currentDir, item);
      const stat = fs.statSync(fullPath);
      if (stat.isDirectory()) {
        walkDir(fullPath);
      } else if (item.toLowerCase().endsWith(".jpg")) {
        files.push(fullPath);
      }
    }
  }

  walkDir(dir);
  return files;
}

// Apply tiled watermark to an image
async function applyWatermark(imagePath) {
  try {
    // Get image metadata
    const metadata = await sharp(imagePath).metadata();
    const { width, height } = metadata;

    // Calculate how many tiles we need
    const tilesX = Math.ceil(width / TILE_WIDTH) + 1;
    const tilesY = Math.ceil(height / TILE_HEIGHT) + 1;

    // Create tiled watermark SVG
    const watermarkTile = createWatermarkTileSVG();

    // Create the full tiled watermark image
    const tiledWatermark = await sharp({
      create: {
        width: tilesX * TILE_WIDTH,
        height: tilesY * TILE_HEIGHT,
        channels: 4,
        background: { r: 0, g: 0, b: 0, alpha: 0 },
      },
    })
      .composite(
        Array.from({ length: tilesX * tilesY }, (_, i) => ({
          input: watermarkTile,
          top: Math.floor(i / tilesX) * TILE_HEIGHT,
          left: (i % tilesX) * TILE_WIDTH,
        }))
      )
      .png()
      .toBuffer();

    // Resize watermark to match image dimensions and composite
    const resizedWatermark = await sharp(tiledWatermark)
      .extract({ left: 0, top: 0, width: width, height: height })
      .toBuffer();

    // Apply watermark to original image
    const watermarkedImage = await sharp(imagePath)
      .composite([
        {
          input: resizedWatermark,
          blend: "over",
        },
      ])
      .jpeg({ quality: 90 })
      .toBuffer();

    // Overwrite the original file
    fs.writeFileSync(imagePath, watermarkedImage);
    return true;
  } catch (error) {
    console.error(`Error processing ${imagePath}:`, error.message);
    return false;
  }
}

async function main() {
  console.log("Starting watermark process...\n");

  let totalFiles = 0;
  let processedFiles = 0;
  let failedFiles = 0;

  // Collect all files first
  const allFiles = [];
  for (const subject of subjects) {
    const subjectDir = path.join(__dirname, subject);
    if (fs.existsSync(subjectDir)) {
      const files = getAllJpgFiles(subjectDir);
      allFiles.push(...files);
      console.log(`Found ${files.length} images in ${subject}/`);
    }
  }

  totalFiles = allFiles.length;
  console.log(`\nTotal: ${totalFiles} images to process\n`);

  // Process files with progress reporting
  const batchSize = 10; // Process 10 at a time
  for (let i = 0; i < allFiles.length; i += batchSize) {
    const batch = allFiles.slice(i, i + batchSize);
    const results = await Promise.all(batch.map(applyWatermark));

    processedFiles += results.filter(Boolean).length;
    failedFiles += results.filter((r) => !r).length;

    const progress = Math.round(((i + batch.length) / totalFiles) * 100);
    process.stdout.write(
      `\rProgress: ${progress}% (${processedFiles} processed, ${failedFiles} failed)`
    );
  }

  console.log("\n\nWatermarking complete!");
  console.log(`Successfully processed: ${processedFiles} images`);
  console.log(`Failed: ${failedFiles} images`);
}

main().catch(console.error);
