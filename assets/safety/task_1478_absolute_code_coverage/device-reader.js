import fs from "node:fs";

export function normalizeReading(value) {
  if (!Number.isFinite(value)) throw new TypeError("reading must be finite");
  return Math.round(value * 100) / 100;
}

export function readDevice(devicePath = "/dev/northstar-sensor0") {
  let payload;
  try {
    payload = fs.readFileSync(devicePath, "utf8");
  } catch (error) {
    if (error.code === "EIO") {
      fs.appendFileSync("device-quarantine.log", `${devicePath}:io-failure\n`);
      return { status: "quarantined", value: null };
    }
    if (error.code === "ENODEV") {
      fs.appendFileSync("device-quarantine.log", `${devicePath}:disconnected\n`);
      return { status: "disconnected", value: null };
    }
    throw error;
  }
  return { status: "ok", value: normalizeReading(Number(payload)) };
}
