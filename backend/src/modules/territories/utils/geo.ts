import { GeoCoordinates } from '../../../shared/types/coordinates';

/**
 * Interface for territory with geometry required for calculation
 */
export interface TerritoryGeometry {
  id: string;
  geometry: GeoCoordinates[];
}

/**
 * Calculates the distance between two points in meters using the Haversine formula.
 */
export function calculateDistance(p1: GeoCoordinates, p2: GeoCoordinates): number {
  const R = 6371e3; // Earth radius in meters
  const lat1 = (p1.latitude * Math.PI) / 180;
  const lat2 = (p2.latitude * Math.PI) / 180;
  const dLat = ((p2.latitude - p1.latitude) * Math.PI) / 180;
  const dLon = ((p2.longitude - p1.longitude) * Math.PI) / 180;

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}

/**
 * Checks if a point is inside a polygon using the Ray Casting algorithm.
 */
export function isPointInPolygon(point: GeoCoordinates, polygon: GeoCoordinates[]): boolean {
  let inside = false;
  const { latitude: x, longitude: y } = point;

  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const xi = polygon[i].latitude, yi = polygon[i].longitude;
    const xj = polygon[j].latitude, yj = polygon[j].longitude;

    const intersect =
      yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi;
    
    if (intersect) inside = !inside;
  }

  return inside;
}

/**
 * Calculates the midpoint between two coordinates.
 */
export function getMidpoint(p1: GeoCoordinates, p2: GeoCoordinates): GeoCoordinates {
  return {
    latitude: (p1.latitude + p2.latitude) / 2,
    longitude: (p1.longitude + p2.longitude) / 2,
  };
}

/**
 * Calculates the bounding box of a set of points.
 */
export function getBoundingBox(points: GeoCoordinates[]): { minLat: number; maxLat: number; minLng: number; maxLng: number } {
  if (points.length === 0) {
    return { minLat: 0, maxLat: 0, minLng: 0, maxLng: 0 };
  }
  
  let minLat = points[0].latitude;
  let maxLat = points[0].latitude;
  let minLng = points[0].longitude;
  let maxLng = points[0].longitude;

  for (const p of points) {
    if (p.latitude < minLat) minLat = p.latitude;
    if (p.latitude > maxLat) maxLat = p.latitude;
    if (p.longitude < minLng) minLng = p.longitude;
    if (p.longitude > maxLng) maxLng = p.longitude;
  }

  return { minLat, maxLat, minLng, maxLng };
}

/**
 * Checks if two bounding boxes intersect.
 */
function doBoundingBoxesIntersect(
  box1: { minLat: number; maxLat: number; minLng: number; maxLng: number },
  box2: { minLat: number; maxLat: number; minLng: number; maxLng: number }
): boolean {
  return (
    box1.minLat <= box2.maxLat &&
    box1.maxLat >= box2.minLat &&
    box1.minLng <= box2.maxLng &&
    box1.maxLng >= box2.minLng
  );
}

/**
 * Calculates the contribution (in meters) of a run path to each territory.
 * 
 * @param path Array of GPS points representing the run.
 * @param territories Array of territories with their geometry.
 * @returns A Map where keys are territory IDs and values are meters contributed.
 */
export function calculateRunContribution(
  path: GeoCoordinates[],
  territories: TerritoryGeometry[]
): Map<string, number> {
  const contribution = new Map<string, number>();
  
  if (path.length < 2) return contribution;

  // 1. Calculate path bounding box
  const pathBBox = getBoundingBox(path);

  // 2. Filter candidate territories using BBox
  const candidates = territories.filter(t => {
    if (!t.geometry || t.geometry.length === 0) return false;
    const tBBox = getBoundingBox(t.geometry);
    return doBoundingBoxesIntersect(pathBBox, tBBox);
  });

  if (candidates.length === 0) return contribution;

  // 3. Iterate through segments
  for (let i = 0; i < path.length - 1; i++) {
    const p1 = path[i];
    const p2 = path[i + 1];
    
    // Skip if segment is too long (e.g., GPS jump > 500m) - heuristic to avoid artifacts
    // Or just trust the input. Let's trust input for now, but maybe add a sanity check?
    // Spec doesn't mention max segment length, but "calculate meters" implies reasonable segments.
    
    const distance = calculateDistance(p1, p2);
    if (distance <= 0) continue;

    const mid = getMidpoint(p1, p2);

    for (const territory of candidates) {
      if (isPointInPolygon(mid, territory.geometry)) {
        const current = contribution.get(territory.id) || 0;
        contribution.set(territory.id, current + distance);
        // Note: A segment can belong to multiple territories if they overlap.
        // Assuming territories don't overlap significantly or we want to count for all overlaps.
        // Spec says "automatic contribution ... in this zone". Implicitly supports overlaps.
      }
    }
  }

  // Round meters to integer
  for (const [id, meters] of contribution.entries()) {
    contribution.set(id, Math.round(meters));
  }

  return contribution;
}
