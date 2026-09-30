import { test, describe } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";

describe("QML Components Integrity", () => {
  const srcDir = path.resolve(process.cwd(), "src");
  const qmlFiles = fs.readdirSync(srcDir).filter((f) => f.endsWith(".qml"));

  test("source directory contains required QML components", () => {
    assert.ok(qmlFiles.includes("BarWidget.qml"));
    assert.ok(qmlFiles.includes("MediaPopup.qml"));
    assert.ok(qmlFiles.includes("TimeSlider.qml"));
    assert.ok(qmlFiles.includes("VolumeSlider.qml"));
    assert.ok(qmlFiles.includes("AlbumArt.qml"));
  });

  for (const file of qmlFiles) {
    test(`verifies ${file} has balanced braces and valid structure`, () => {
      const filePath = path.join(srcDir, file);
      const content = fs.readFileSync(filePath, "utf8");

      let openBraces = 0;
      let closeBraces = 0;
      for (const char of content) {
        if (char === "{") openBraces++;
        if (char === "}") closeBraces++;
      }
      assert.equal(openBraces, closeBraces, `Unbalanced braces in ${file}: { ${openBraces} vs } ${closeBraces}`);
      assert.ok(content.includes("import QtQuick"), `${file} should import QtQuick`);
    });
  }
});
