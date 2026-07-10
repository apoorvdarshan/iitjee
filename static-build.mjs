import { cpSync, mkdirSync, rmSync } from "node:fs";

const output = new URL("./dist/", import.meta.url);
rmSync(output, { recursive: true, force: true });
mkdirSync(output, { recursive: true });

for (const path of [
  "chemistry",
  "mathematics",
  "physics",
  "chemistry.html",
  "favicon.ico",
  "gallery.html",
  "index.html",
  "mathematics.html",
  "physics.html",
  "script.js",
  "style.css",
]) {
  cpSync(new URL(path, import.meta.url), new URL(path, output), {
    recursive: true,
  });
}
