import { getTerritoriesForCity } from '../src/modules/territories/territories.config';
import type { GeoCoordinates } from '../src/shared/types/coordinates';

type XY = { x: number; y: number };

const METERS_PER_DEGREE_LAT = 111_132;
const METERS_PER_DEGREE_LON_EQUATOR = 111_320;

function toXY(p: GeoCoordinates, lat0Rad: number): XY {
  // Equirectangular projection around lat0 (good enough for city-scale auditing).
  return {
    x: p.longitude * METERS_PER_DEGREE_LON_EQUATOR * Math.cos(lat0Rad),
    y: p.latitude * METERS_PER_DEGREE_LAT,
  };
}

function bbox(poly: XY[]) {
  let minX = Infinity,
    minY = Infinity,
    maxX = -Infinity,
    maxY = -Infinity;
  for (const p of poly) {
    minX = Math.min(minX, p.x);
    minY = Math.min(minY, p.y);
    maxX = Math.max(maxX, p.x);
    maxY = Math.max(maxY, p.y);
  }
  return { minX, minY, maxX, maxY };
}

function bboxesOverlap(a: ReturnType<typeof bbox>, b: ReturnType<typeof bbox>) {
  return !(a.maxX < b.minX || b.maxX < a.minX || a.maxY < b.minY || b.maxY < a.minY);
}

function cross(a: XY, b: XY, c: XY): number {
  // Cross product of AB x AC
  return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

function onSegment(a: XY, b: XY, p: XY, eps = 1e-9): boolean {
  return (
    Math.min(a.x, b.x) - eps <= p.x &&
    p.x <= Math.max(a.x, b.x) + eps &&
    Math.min(a.y, b.y) - eps <= p.y &&
    p.y <= Math.max(a.y, b.y) + eps &&
    Math.abs(cross(a, b, p)) <= eps
  );
}

type SegHit = 'none' | 'touch' | 'collinear_overlap' | 'proper';

function segmentIntersectionType(a1: XY, a2: XY, b1: XY, b2: XY, eps = 1e-9): SegHit {
  const d1 = cross(a1, a2, b1);
  const d2 = cross(a1, a2, b2);
  const d3 = cross(b1, b2, a1);
  const d4 = cross(b1, b2, a2);

  const d1z = Math.abs(d1) <= eps;
  const d2z = Math.abs(d2) <= eps;
  const d3z = Math.abs(d3) <= eps;
  const d4z = Math.abs(d4) <= eps;

  // Collinear case
  if (d1z && d2z && d3z && d4z) {
    const ax1 = Math.min(a1.x, a2.x),
      ax2 = Math.max(a1.x, a2.x);
    const ay1 = Math.min(a1.y, a2.y),
      ay2 = Math.max(a1.y, a2.y);
    const bx1 = Math.min(b1.x, b2.x),
      bx2 = Math.max(b1.x, b2.x);
    const by1 = Math.min(b1.y, b2.y),
      by2 = Math.max(b1.y, b2.y);
    const overlapX = Math.min(ax2, bx2) >= Math.max(ax1, bx1) - eps;
    const overlapY = Math.min(ay2, by2) >= Math.max(ay1, by1) - eps;
    return overlapX && overlapY ? 'collinear_overlap' : 'none';
  }

  // Proper intersection (strict)
  if ((d1 > eps && d2 < -eps) || (d1 < -eps && d2 > eps)) {
    if ((d3 > eps && d4 < -eps) || (d3 < -eps && d4 > eps)) return 'proper';
  }

  // Touching at endpoints / boundary
  if (d1z && onSegment(a1, a2, b1, eps)) return 'touch';
  if (d2z && onSegment(a1, a2, b2, eps)) return 'touch';
  if (d3z && onSegment(b1, b2, a1, eps)) return 'touch';
  if (d4z && onSegment(b1, b2, a2, eps)) return 'touch';

  return 'none';
}

function pointInPolygonStrict(pt: XY, poly: XY[], eps = 1e-9): boolean {
  // Ray casting; strict interior only (boundary => false).
  let inside = false;
  for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    const a = poly[j];
    const b = poly[i];

    if (onSegment(a, b, pt, eps)) return false;

    const intersect =
      (a.y > pt.y) !== (b.y > pt.y) &&
      pt.x < ((b.x - a.x) * (pt.y - a.y)) / (b.y - a.y + 0.0) + a.x;
    if (intersect) inside = !inside;
  }
  return inside;
}

function polygonInteriorOverlaps(a: XY[], b: XY[]): boolean {
  if (a.length < 3 || b.length < 3) return false;
  if (!bboxesOverlap(bbox(a), bbox(b))) return false;

  // Proper edge crossings imply interior overlap.
  for (let i = 0; i < a.length; i++) {
    const a1 = a[i];
    const a2 = a[(i + 1) % a.length];
    for (let j = 0; j < b.length; j++) {
      const b1 = b[j];
      const b2 = b[(j + 1) % b.length];
      if (segmentIntersectionType(a1, a2, b1, b2) === 'proper') return true;
    }
  }

  // Strict containment.
  for (const p of a) if (pointInPolygonStrict(p, b)) return true;
  for (const p of b) if (pointInPolygonStrict(p, a)) return true;

  return false;
}

function polygonSelfIntersects(poly: XY[]): boolean {
  // Any non-adjacent edges intersect => self-intersection.
  for (let i = 0; i < poly.length; i++) {
    const a1 = poly[i];
    const a2 = poly[(i + 1) % poly.length];
    for (let j = i + 1; j < poly.length; j++) {
      if (Math.abs(i - j) <= 1) continue;
      if (i === 0 && j === poly.length - 1) continue;
      const b1 = poly[j];
      const b2 = poly[(j + 1) % poly.length];
      const hit = segmentIntersectionType(a1, a2, b1, b2);
      if (hit === 'proper' || hit === 'collinear_overlap') return true;
    }
  }
  return false;
}

function signedArea(poly: XY[]): number {
  let s = 0;
  for (let i = 0; i < poly.length; i++) {
    const a = poly[i];
    const b = poly[(i + 1) % poly.length];
    s += a.x * b.y - b.x * a.y;
  }
  return s / 2;
}

function main() {
  const territories = getTerritoriesForCity('spb');

  const allPoints = territories.flatMap((t) => t.geometry ?? []);
  const lat0 = allPoints.length
    ? allPoints.reduce((sum, p) => sum + p.latitude, 0) / allPoints.length
    : 59.9343;
  const lat0Rad = (lat0 * Math.PI) / 180;

  const polys = territories.map((t) => ({
    id: t.id,
    name: t.name,
    poly: (t.geometry ?? []).map((p) => toXY(p, lat0Rad)),
  }));

  const issues: string[] = [];
  for (const p of polys) {
    if (p.poly.length < 3) {
      issues.push(`BAD_POLY ${p.id}: geometry has < 3 points`);
      continue;
    }
    const area = signedArea(p.poly);
    if (Math.abs(area) < 10) issues.push(`DEGENERATE ${p.id}: area ~0`);
    if (polygonSelfIntersects(p.poly)) issues.push(`SELF_INTERSECT ${p.id}`);
  }

  const overlaps: string[] = [];
  for (let i = 0; i < polys.length; i++) {
    for (let j = i + 1; j < polys.length; j++) {
      if (polygonInteriorOverlaps(polys[i].poly, polys[j].poly)) {
        overlaps.push(`${polys[i].id}  <->  ${polys[j].id}`);
      }
    }
  }

  console.log(`territories: ${territories.length}`);
  console.log(`lat0 (audit): ${lat0.toFixed(6)}`);

  console.log('\nGeometry issues:');
  if (issues.length === 0) console.log('- none');
  for (const i of issues) console.log(`- ${i}`);

  console.log('\nInterior overlaps:');
  if (overlaps.length === 0) console.log('- none');
  for (const o of overlaps) console.log(`- ${o}`);
}

main();

