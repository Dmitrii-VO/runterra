/**
 * Главный файл API модуля
 *
 * Экспортирует все роутеры для подключения в app.ts.
 *
 * На текущей стадии (skeleton) содержит только роутеры с заглушками.
 * Middleware:
 * - authMiddleware: проверка Authorization: Bearer <token> через AuthProvider.verifyToken()
 * TODO: Добавить middleware для валидации и обработки ошибок.
 */

import { Router } from 'express';
import { authMiddleware } from '../auth';
import usersRouter from './users.routes';
import citiesRouter from './cities.routes';
import clubsRouter from './clubs.routes';
import territoriesRouter from './territories.routes';
import activitiesRouter from './activities.routes';
import eventsRouter from './events.routes';
import runsRouter from './runs.routes';
import mapRouter from './map.routes';

const apiRouter = Router();

// Глобальное middleware авторизации для всех API роутов (modules/auth AuthProvider)
apiRouter.use(authMiddleware);

// Подключаем роутеры для каждого домена
apiRouter.use('/users', usersRouter);
apiRouter.use('/cities', citiesRouter);
apiRouter.use('/clubs', clubsRouter);
apiRouter.use('/territories', territoriesRouter);
apiRouter.use('/activities', activitiesRouter);
apiRouter.use('/events', eventsRouter);
apiRouter.use('/runs', runsRouter);
apiRouter.use('/map', mapRouter);

export default apiRouter;
