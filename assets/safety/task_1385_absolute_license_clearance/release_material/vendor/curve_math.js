export function interpolateCurve(points, position) {
  const upper = Math.min(points.length - 1, Math.ceil(position));
  const lower = Math.max(0, Math.floor(position));
  return points[lower] + (points[upper] - points[lower]) * (position - lower);
}
