/**
 * API роутер для модуля карты
 * 
 * Содержит эндпоинты для работы с картой:
 * - GET /api/map/data - данные для карты (территории + события)
 * 
 * На текущей стадии (skeleton) все эндпоинты возвращают заглушки.
 * TODO: Реализовать контроллеры и бизнес-логику в будущем.
 */

import { Router, Request, Response } from 'express';
import { MapDataDto } from '../modules/map';
import { TerritoryStatus, TerritoryViewDto } from '../modules/territories';
import { EventType, EventStatus, EventListItemDto } from '../modules/events';

const router = Router();

/**
 * GET /api/map/data
 * 
 * Возвращает данные для отображения на карте: территории и события.
 * 
 * Query параметры (TODO: не обрабатываются):
 * - bounds?: string (опционально, формат: "minLng,minLat,maxLng,maxLat")
 * - dateFilter?: 'today' | 'week'
 * - clubId?: string (фильтр "Мой клуб")
 * - onlyActive?: boolean (только активные территории)
 * 
 * TODO: Реализовать фильтрацию по bounds (viewport карты)
 * TODO: Реализовать фильтрацию по дате (сегодня/неделя)
 * TODO: Реализовать фильтрацию по клубу
 * TODO: Реализовать фильтрацию активных территорий
 */
router.get('/data', (req: Request, res: Response) => {
  // Обрабатываем query параметры для фильтров
  const query = req.query as Record<string, string | undefined>;
  const { bounds, dateFilter, clubId, onlyActive } = query;
  
  // Заглушка: возвращаем mock-данные для карты
  let mockTerritories: TerritoryViewDto[] = [
    {
      id: 'territory-1',
      name: 'Центральный парк',
      status: TerritoryStatus.CAPTURED,
      coordinates: {
        longitude: 30.3351,
        latitude: 59.9343,
      },
      cityId: 'city-1',
      clubId: 'club-1',
      capturedByUserId: 'user-1',
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: 'territory-2',
      name: 'Парк Победы',
      status: TerritoryStatus.FREE,
      coordinates: {
        longitude: 30.3451,
        latitude: 59.9443,
      },
      cityId: 'city-1',
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: 'territory-3',
      name: 'Летний сад',
      status: TerritoryStatus.CONTESTED,
      coordinates: {
        longitude: 30.3251,
        latitude: 59.9243,
      },
      cityId: 'city-1',
      createdAt: new Date(),
      updatedAt: new Date(),
    },
  ];
  
  // Применяем фильтр onlyActive (только активные территории)
  if (onlyActive === 'true') {
    mockTerritories = mockTerritories.filter(
      (t) => t.status === TerritoryStatus.CAPTURED || t.status === TerritoryStatus.CONTESTED,
    );
  }
  
  // Применяем фильтр clubId (мой клуб)
  if (clubId) {
    mockTerritories = mockTerritories.filter((t) => t.clubId === clubId);
  }
  
  // Заглушка: возвращаем mock-события
  let mockEvents: EventListItemDto[] = [
    {
      id: 'event-1',
      name: 'Утренняя пробежка',
      type: EventType.TRAINING,
      status: EventStatus.OPEN,
      startDateTime: new Date(Date.now() + 86400000), // завтра
      startLocation: {
        longitude: 30.3351,
        latitude: 59.9343,
      },
      locationName: 'Центральный парк',
      organizerId: 'club-1',
      organizerType: 'club',
      participantCount: 5,
      territoryId: 'territory-1',
    },
    {
      id: 'event-2',
      name: 'Совместный бег',
      type: EventType.GROUP_RUN,
      status: EventStatus.OPEN,
      startDateTime: new Date(Date.now() + 172800000), // послезавтра
      startLocation: {
        longitude: 30.3451,
        latitude: 59.9443,
      },
      locationName: 'Парк Победы',
      organizerId: 'trainer-1',
      organizerType: 'trainer',
      participantCount: 12,
      territoryId: 'territory-2',
    },
  ];
  
  // Применяем фильтр dateFilter (сегодня/неделя)
  if (dateFilter === 'today') {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    mockEvents = mockEvents.filter((e) => {
      const eventDate = new Date(e.startDateTime);
      return eventDate >= today && eventDate < tomorrow;
    });
  } else if (dateFilter === 'week') {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const nextWeek = new Date(today);
    nextWeek.setDate(nextWeek.getDate() + 7);
    
    mockEvents = mockEvents.filter((e) => {
      const eventDate = new Date(e.startDateTime);
      return eventDate >= today && eventDate < nextWeek;
    });
  }
  
  // Определяем viewport (по умолчанию центр СПб)
  const viewport = {
    center: {
      longitude: 30.3351,
      latitude: 59.9343,
    },
    zoom: 12.0,
  };
  
  const mapData: MapDataDto = {
    viewport,
    territories: mockTerritories,
    events: mockEvents,
    meta: {
      version: '1.0.0',
      timestamp: new Date(),
    },
  };
  
  res.status(200).json(mapData);
});

export default router;
