import { test, describe } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";

describe("manifest.json validation", () => {
  const manifestPath = path.resolve(process.cwd(), "manifest.json");

  test("manifest.json exists and is valid JSON", () => {
    assert.equal(fs.existsSync(manifestPath), true);
    const content = fs.readFileSync(manifestPath, "utf8");
    const json = JSON.parse(content);
    assert.equal(typeof json, "object");
  });

  test("contains required plugin schema fields", () => {
    const json = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
    assert.equal(json.schemaVersion, 1);
    assert.equal(json.id, "krosci.omamp");
    assert.equal(json.name, "MediaPlayer");
    assert.ok(Array.isArray(json.kinds));
    assert.ok(json.kinds.includes("bar-widget"));
    assert.ok(json.entryPoints && json.entryPoints.barWidget);
  });

  test("entry point file exists", () => {
    const json = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
    const entryPath = path.resolve(process.cwd(), json.entryPoints.barWidget);
    assert.equal(fs.existsSync(entryPath), true, `Entry point ${json.entryPoints.barWidget} does not exist`);
  });
});
