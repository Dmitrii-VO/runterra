/**
 * Shared geo coordinates type.
 *
 * Single source of truth for { latitude, longitude } used across
 * city, territory, event, run, and map modules to avoid duplication.
 */

import { z } from 'zod';

export interface GeoCoordinates {
  /** Longitude */
  longitude: number;
  /** Latitude */
  latitude: number;
}

/** Zod schema for GeoCoordinates (use in DTOs). */
export const GeoCoordinatesSchema = z.object({
  longitude: z.number(),
  latitude: z.number(),
});
