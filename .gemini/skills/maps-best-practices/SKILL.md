# Maps & Geodata Specialist (Runterra)

Expertise in Yandex MapKit integration and geo-spatial logic for Runterra.

## Yandex MapKit (Mobile)
- **Initialization:** Set `AndroidYandexMap.useAndroidViewSurface = false` for better emulator support.
- **Markers:** Use custom markers for clubs and events.
- **Polygons:** Implement territory visualization using `Polygon` objects. Follow ADR 0006.

## Geodata Logic
- **Coordinates:** Always handle as `{ latitude, longitude }`.
- **Validation:** Validate that coordinates are within the selected city's bounds.
- **Performance:** Limit the number of visible map objects to prevent UI lag. Use clustering if many markers are present.

## Business Rules
- **Territory Capture:** Refer to ADR 0007. Only active members of a club can capture/contribute to a territory.
- **City Context:** Always filter map data by the `currentCityId` from `CurrentCityService`.
