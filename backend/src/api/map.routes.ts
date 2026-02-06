/**
 * API роутер для модуля карты
 * 
 * Содержит эндпоинты для работы с картой:
 * - GET /api/map/data - данные для карты (территории + события)
 */

import { Router, Request, Response } from 'express';
import { MapDataDto } from '../modules/map';
import { TerritoryStatus, TerritoryViewDto } from '../modules/territories';
import { EventType, EventStatus, EventListItemDto } from '../modules/events';
import { getEventsRepository } from '../db/repositories';
import { getTerritoriesForCity } from '../modules/territories/territories.config';
import { findCityById } from '../modules/cities/cities.config';
import { logger } from '../shared/logger';

const router = Router();

/**
 * GET /api/map/data
 * 
 * Возвращает данные для отображения на карте: территории и события.
 * 
 * Query параметры:
 * - cityId: string (обязателен) — идентификатор города
 * - bounds?: string (формат: "minLng,minLat,maxLng,maxLat") - TODO
 * - dateFilter?: 'today' | 'week'
 * - clubId?: string (фильтр "Мой клуб")
 * - onlyActive?: boolean (только активные территории)
 */
router.get('/data', async (req: Request, res: Response) => {
  const query = req.query as Record<string, string | undefined>;
  const { cityId, dateFilter, clubId, onlyActive } = query;
  
  if (!cityId) {
    return res.status(400).json({
      code: 'validation_error',
      message: 'Query validation failed',
      details: {
        fields: [
          {
            field: 'cityId',
            message: 'cityId is required',
            code: 'city_required',
          },
        ],
      },
    });
  }

  const city = findCityById(cityId);
  if (!city) {
    return res.status(400).json({
      code: 'validation_error',
      message: 'Query validation failed',
      details: {
        fields: [
          {
            field: 'cityId',
            message: 'Unknown cityId',
            code: 'city_not_found',
          },
        ],
      },
    });
  }
  
  try {
    // Territories: static config (SPB popular running parks) until DB is introduced
    let territories: TerritoryViewDto[] = getTerritoriesForCity(cityId, clubId);
    
    // Фильтр территорий: только активные
    if (onlyActive === 'true') {
      territories = territories.filter(
        (t) => t.status === TerritoryStatus.CAPTURED || t.status === TerritoryStatus.CONTESTED,
      );
    }
    // Получаем события из БД с фильтрами
    const repo = getEventsRepository();
    const events = await repo.findAll({
      cityId,
      dateFilter: dateFilter === 'today' ? 'today' : dateFilter === 'week' ? 'next7days' : undefined,
      clubId,
      limit: 100,
    });
    
    // Map to DTO
    const eventsDto: EventListItemDto[] = events.map(event => ({
      id: event.id,
      name: event.name,
      type: event.type,
      status: event.status,
      startDateTime: event.startDateTime,
      startLocation: event.startLocation,
      locationName: event.locationName,
      organizerId: event.organizerId,
      organizerType: event.organizerType,
      difficultyLevel: event.difficultyLevel,
      participantCount: event.participantCount,
      territoryId: event.territoryId,
      cityId: event.cityId,
    }));
    
    // Viewport — центр выбранного города
    const viewport = {
      center: {
        longitude: city.center.longitude,
        latitude: city.center.latitude,
      },
      zoom: 12.0,
    };
    
    const mapData: MapDataDto = {
      viewport,
      territories,
      events: eventsDto,
      meta: {
        version: '1.0.0',
        timestamp: new Date(),
      },
    };
    
    res.status(200).json(mapData);
  } catch (error) {
    logger.error('Error fetching map data', { error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
    });
  }
});

export default router;
