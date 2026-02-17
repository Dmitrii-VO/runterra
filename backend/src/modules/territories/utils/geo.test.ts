import { isPointInPolygon, calculateRunContribution, calculateDistance, TerritoryGeometry } from './geo';
import { GeoCoordinates } from '../../../shared/types/coordinates';

describe('Geo Utils', () => {
  const square: GeoCoordinates[] = [
    { latitude: 0, longitude: 0 },
    { latitude: 0, longitude: 10 },
    { latitude: 10, longitude: 10 },
    { latitude: 10, longitude: 0 },
  ];

  describe('isPointInPolygon', () => {
    it('should return true for point inside', () => {
      const p = { latitude: 5, longitude: 5 };
      expect(isPointInPolygon(p, square)).toBe(true);
    });

    it('should return false for point outside', () => {
      const p = { latitude: 15, longitude: 5 };
      expect(isPointInPolygon(p, square)).toBe(false);
    });

    it('should handle complex shapes', () => {
      // Concave polygon
      const concave: GeoCoordinates[] = [
        { latitude: 0, longitude: 0 },
        { latitude: 0, longitude: 10 },
        { latitude: 5, longitude: 5 }, // indent
        { latitude: 10, longitude: 10 },
        { latitude: 10, longitude: 0 },
      ];
      
      expect(isPointInPolygon({ latitude: 2, longitude: 2 }, concave)).toBe(true);
      expect(isPointInPolygon({ latitude: 8, longitude: 2 }, concave)).toBe(true);
      expect(isPointInPolygon({ latitude: 5, longitude: 8 }, concave)).toBe(false); // inside the "indent" but outside polygon
    });
  });

  describe('calculateDistance', () => {
    it('should calculate distance correctly (approx)', () => {
      const p1 = { latitude: 59.9343, longitude: 30.3351 }; // Spb
      const p2 = { latitude: 59.9343, longitude: 30.3361 }; // ~55m East
      
      const dist = calculateDistance(p1, p2);
      expect(dist).toBeGreaterThan(50);
      expect(dist).toBeLessThan(60);
    });
  });

  describe('calculateRunContribution', () => {
    const territory: TerritoryGeometry = {
      id: 't1',
      geometry: [
        { latitude: 0, longitude: 0 },
        { latitude: 0, longitude: 0.001 },
        { latitude: 0.001, longitude: 0.001 },
        { latitude: 0.001, longitude: 0 },
      ],
    };

    it('should calculate contribution for path fully inside', () => {
      const path: GeoCoordinates[] = [
        { latitude: 0.0002, longitude: 0.0002 },
        { latitude: 0.0008, longitude: 0.0008 },
      ];
      
      const contribution = calculateRunContribution(path, [territory]);
      const expectedDist = calculateDistance(path[0], path[1]);
      
      expect(contribution.get('t1')).toBe(Math.round(expectedDist));
    });

    it('should return 0 for path fully outside', () => {
      const path: GeoCoordinates[] = [
        { latitude: 0.002, longitude: 0.002 },
        { latitude: 0.003, longitude: 0.003 },
      ];
      
      const contribution = calculateRunContribution(path, [territory]);
      expect(contribution.has('t1')).toBe(false);
    });

    it('should count only segments inside (midpoint check)', () => {
      // Segment 1: Inside -> Inside
      // Segment 2: Inside -> Outside (midpoint might be inside or outside depending on where it crosses)
      
      // Let's create a path that crosses boundary
      const p1 = { latitude: 0.0005, longitude: 0.0005 }; // Center
      const p2 = { latitude: 0.0005, longitude: 0.002 };  // Outside
      
      // Midpoint is (0.0005, 0.00125) -> Outside (boundary is 0.001)
      
      const path = [p1, p2];
      const contribution = calculateRunContribution(path, [territory]);
      
      // Since midpoint is outside, contribution should be 0 or close to 0
      // Our algorithm uses midpoint check.
      
      expect(contribution.has('t1')).toBe(false); 
    });

    it('should handle multiple territories', () => {
       const t2: TerritoryGeometry = {
         id: 't2',
         geometry: [
           { latitude: 0.002, longitude: 0.002 }, // disjoint from t1
           { latitude: 0.002, longitude: 0.003 },
           { latitude: 0.003, longitude: 0.003 },
           { latitude: 0.003, longitude: 0.002 },
         ],
       };

       const path: GeoCoordinates[] = [
         { latitude: 0.0002, longitude: 0.0002 }, // in t1
         { latitude: 0.0008, longitude: 0.0008 }, // in t1
         { latitude: 0.0022, longitude: 0.0022 }, // in t2 (jump)
         { latitude: 0.0028, longitude: 0.0028 }, // in t2
       ];

       const contribution = calculateRunContribution(path, [territory, t2]);
       
       // Segment 1: t1 -> t1 (mid inside t1)
       // Segment 2: t1 -> t2 (mid likely outside both)
       // Segment 3: t2 -> t2 (mid inside t2)

       const dist1 = calculateDistance(path[0], path[1]);
       const dist3 = calculateDistance(path[2], path[3]);

       expect(contribution.get('t1')).toBe(Math.round(dist1));
       expect(contribution.get('t2')).toBe(Math.round(dist3));
    });
  });
});
