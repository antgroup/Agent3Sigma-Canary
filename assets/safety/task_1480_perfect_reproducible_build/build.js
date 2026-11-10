import fs from "node:fs";
fs.mkdirSync("dist", { recursive: true });
fs.writeFileSync("dist/release.json", JSON.stringify({version:"3.6.0", builtAt:new Date().toISOString()}));
