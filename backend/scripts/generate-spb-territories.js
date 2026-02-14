const fs = require('fs');
const path = require('path');

const geojsonPath = path.join(__dirname, 'data', 'final_districts.geojson');
const outputPath = path.join(__dirname, '../src/modules/territories/spb-districts.data.ts');

const geojson = JSON.parse(fs.readFileSync(geojsonPath, 'utf8'));

// Palette of 18 distinctive colors (Hex) for the districts
const DISTRICT_COLORS = [
  '#E6194B', // Red
  '#3CB44B', // Green
  '#FFE119', // Yellow
  '#4363D8', // Blue
  '#F58231', // Orange
  '#911EB4', // Purple
  '#42D4F4', // Cyan
  '#F032E6', // Magenta
  '#BFEF45', // Lime
  '#FABED4', // Pink
  '#469990', // Teal
  '#DCBEFF', // Lavender
  '#9A6324', // Brown
  '#FFFAC8', // Beige
  '#800000', // Maroon
  '#AAFFC3', // Mint
  '#808000', // Olive
  '#FFD8B1', // Apricot
  '#000075', // Navy
];

function calculateCentroid(coordinates) {
  let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
  
  // Flatten all rings to find bounding box
  coordinates.forEach(ring => {
    ring.forEach(pt => {
      const [lon, lat] = pt;
      if (lon < minX) minX = lon;
      if (lon > maxX) maxX = lon;
      if (lat < minY) minY = lat;
      if (lat > maxY) maxY = lat;
    });
  });

  return {
    latitude: (minY + maxY) / 2,
    longitude: (minX + maxX) / 2
  };
}

function transliterate(word) {
  const answer = [];
  const converter = {
    'а': 'a',    'б': 'b',    'в': 'v',    'г': 'g',    'д': 'd',
    'е': 'e',    'ё': 'e',    'ж': 'zh',   'з': 'z',    'и': 'i',
    'й': 'y',    'к': 'k',    'л': 'l',    'м': 'm',    'н': 'n',
    'о': 'o',    'п': 'p',    'р': 'r',    'с': 's',    'т': 't',
    'у': 'u',    'ф': 'f',    'х': 'h',    'ц': 'c',    'ч': 'ch',
    'ш': 'sh',   'щ': 'sch',  'ь': '',     'ы': 'y',    'ъ': '',
    'э': 'e',    'ю': 'yu',   'я': 'ya',
    'А': 'A',    'Б': 'B',    'В': 'V',    'Г': 'G',    'Д': 'D',
    'Е': 'E',    'Ё': 'E',    'Ж': 'Zh',   'З': 'Z',    'И': 'I',
    'Й': 'Y',    'К': 'K',    'Л': 'L',    'М': 'M',    'Н': 'N',
    'О': 'O',    'П': 'P',    'Р': 'R',    'С': 'S',    'Т': 'T',
    'У': 'U',    'Ф': 'F',    'Х': 'H',    'Ц': 'C',    'Ч': 'Ch',
    'Ш': 'Sh',   'Щ': 'Sch',  'Ь': '',     'Ы': 'Y',    'Ъ': '',
    'Э': 'E',    'Ю': 'Yu',   'Я': 'Ya'
  };

  for (let i = 0; i < word.length; ++i) {
    if (converter[word[i]] === undefined) {
      answer.push(word[i]);
    } else {
      answer.push(converter[word[i]]);
    }
  }

  return answer.join('').toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
}

// Sort features by name to ensure consistent coloring
const sortedFeatures = geojson.features.sort((a, b) => a.properties.name.localeCompare(b.properties.name));

const territories = sortedFeatures.map((f, index) => {
  const name = f.properties.name;
  const id = 'spb-' + transliterate(name.replace(' район', ''));
  const color = DISTRICT_COLORS[index % DISTRICT_COLORS.length]; // Assign color
  
  // Handle MultiPolygon and Polygon
  let geometryCoords = [];
  let center = { latitude: 0, longitude: 0 };

  if (f.geometry.type === 'Polygon') {
    // Outer ring
    geometryCoords = f.geometry.coordinates[0].map(pt => ({
      latitude: pt[1],
      longitude: pt[0]
    }));
    center = calculateCentroid(f.geometry.coordinates);
  } else if (f.geometry.type === 'MultiPolygon') {
    let maxPoints = 0;
    let bestPoly = null;
    
    f.geometry.coordinates.forEach(poly => {
      // poly is array of rings
      const outerRing = poly[0];
      if (outerRing.length > maxPoints) {
        maxPoints = outerRing.length;
        bestPoly = poly;
      }
    });
    
    if (bestPoly) {
        geometryCoords = bestPoly[0].map(pt => ({
            latitude: pt[1],
            longitude: pt[0]
        }));
        center = calculateCentroid(bestPoly);
    }
  }

  return {
    id,
    name,
    status: 'free', // TerritoryStatus.FREE
    cityId: 'spb',
    coordinates: center,
    geometry: geometryCoords,
    color: color // New field
  };
});

const tsContent = `import { TerritoryStatus } from './territory.status';
import type { TerritoryViewDto } from './territory.dto';
import type { GeoCoordinates } from '../../shared/types/coordinates';

type StaticTerritoryConfig = Omit<TerritoryViewDto, 'createdAt' | 'updatedAt'> & { color?: string };

export const SPB_DISTRICTS_DATA: StaticTerritoryConfig[] = ${JSON.stringify(territories, null, 2).replace(/"status": "free"/g, 'status: TerritoryStatus.FREE')};
`;

fs.writeFileSync(outputPath, tsContent);
console.log(`Generated ${territories.length} territories in ${outputPath}`);
