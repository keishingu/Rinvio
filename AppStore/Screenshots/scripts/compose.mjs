import { createRequire } from "node:module";
import { mkdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const sharp = require("sharp");

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const screenshotsDirectory = path.resolve(scriptDirectory, "..");
const repositoryRoot = path.resolve(screenshotsDirectory, "..", "..");
const appIconPath = path.join(repositoryRoot, "AppResources", "QuickDrawIcon-1024.png");

const canvas = { width: 2560, height: 1600 };
const appFrame = { left: 280, top: 350, width: 2000, height: 1241, radius: 50 };

const copy = {
  ja: [
    {
      file: "01-meeting.jpeg",
      headline: "会議アプリごとの違いを、ひとつの操作へ",
      subhead: "Teams・Zoom・Google Meetの公式ショートカットへ変換",
    },
    {
      file: "02-development.jpeg",
      headline: "開発ツールの操作も、共通の手触りに",
      subhead: "Codex・Claudeなど、アプリごとのマッピングを一覧",
    },
    {
      file: "03-applications.jpeg",
      headline: "使うアプリだけを、明示的にON",
      subhead: "対象アプリと配送先を確認し、アプリごとに有効化",
    },
    {
      file: "04-browser.jpeg",
      headline: "ブラウザ操作も、覚え直さない",
      subhead: "SafariとChromeへ、同じActionを正しく配送",
    },
    {
      file: "05-macos.jpeg",
      headline: "macOSは参照して、純正設定で編集",
      subhead: "OS操作は横取りせず、現在値と推奨値を表示",
    },
    {
      file: "06-information.jpeg",
      headline: "権限とプライバシーを、いつでも確認",
      subhead: "キー入力・完全なURL・テレメトリは記録／送信しません",
    },
  ],
  en: [
    {
      file: "01-meeting.jpeg",
      headline: "One shortcut language for every meeting",
      subhead: "Map each Action to official shortcuts in Teams, Zoom, and Google Meet",
    },
    {
      file: "02-development.jpeg",
      headline: "Keep your flow across development tools",
      subhead: "See mappings for Codex, Claude, and more in one place",
    },
    {
      file: "03-applications.jpeg",
      headline: "Enable only the apps you choose",
      subhead: "Review each target and turn QuickDraw on app by app",
    },
    {
      file: "04-browser.jpeg",
      headline: "Stop relearning browser shortcuts",
      subhead: "Send the same Action to Safari and Chrome",
    },
    {
      file: "05-macos.jpeg",
      headline: "Reference macOS. Edit in System Settings.",
      subhead: "See current and recommended shortcuts without intercepting OS actions",
    },
    {
      file: "06-information.jpeg",
      headline: "Permissions and privacy, always visible",
      subhead: "No key logging, full-URL storage, or telemetry",
    },
  ],
};

function escapeXml(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function headerSvg(headline, subhead) {
  return Buffer.from(`
    <svg width="${canvas.width}" height="${canvas.height}" xmlns="http://www.w3.org/2000/svg">
      <style>
        .brand { font: 600 34px -apple-system, BlinkMacSystemFont, "Hiragino Sans", sans-serif; fill: #F4F7FB; }
        .headline { font: 700 62px -apple-system, BlinkMacSystemFont, "Hiragino Sans", sans-serif; fill: #F7F9FC; letter-spacing: -1.2px; }
        .subhead { font: 500 28px -apple-system, BlinkMacSystemFont, "Hiragino Sans", sans-serif; fill: #AEB8C6; }
      </style>
      <text x="252" y="106" class="brand">QuickDraw Shortcuts</text>
      <circle cx="612" cy="95" r="6" fill="#0A84FF" />
      <text x="160" y="213" class="headline">${escapeXml(headline)}</text>
      <text x="160" y="282" class="subhead">${escapeXml(subhead)}</text>
      <rect x="${appFrame.left - 1}" y="${appFrame.top - 1}" width="${appFrame.width + 2}" height="${appFrame.height + 2}" rx="${appFrame.radius + 1}" fill="none" stroke="#405064" stroke-width="2" />
    </svg>
  `);
}

async function roundedImage(inputPath, width, height, radius) {
  const mask = Buffer.from(`
    <svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg">
      <rect width="${width}" height="${height}" rx="${radius}" fill="#fff" />
    </svg>
  `);

  return sharp(inputPath)
    .resize(width, height, { fit: "fill" })
    .png()
    .composite([{ input: mask, blend: "dest-in" }])
    .toBuffer();
}

async function composeScreenshot(locale, item) {
  const rawPath = path.join(screenshotsDirectory, "raw", locale, item.file);
  const outputDirectory = path.join(screenshotsDirectory, "final", locale);
  const outputPath = path.join(outputDirectory, item.file.replace(/\.jpe?g$/i, ".png"));
  await mkdir(outputDirectory, { recursive: true });

  const [appScreenshot, appIcon] = await Promise.all([
    roundedImage(rawPath, appFrame.width, appFrame.height, appFrame.radius),
    roundedImage(appIconPath, 72, 72, 16),
  ]);

  await sharp({
    create: {
      width: canvas.width,
      height: canvas.height,
      channels: 4,
      background: "#0D1219",
    },
  })
    .composite([
      { input: appIcon, left: 160, top: 59 },
      { input: appScreenshot, left: appFrame.left, top: appFrame.top },
      { input: headerSvg(item.headline, item.subhead), left: 0, top: 0 },
    ])
    .removeAlpha()
    .png({ compressionLevel: 9, adaptiveFiltering: true })
    .toFile(outputPath);

  console.log(outputPath);
}

for (const [locale, items] of Object.entries(copy)) {
  for (const item of items) {
    await composeScreenshot(locale, item);
  }
}
