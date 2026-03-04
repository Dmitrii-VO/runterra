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

import { Router, Request, Response, NextFunction } from 'express';
import { authMiddleware } from '../auth';
import usersRouter from './users.routes';
import citiesRouter from './cities.routes';
import clubsRouter from './clubs.routes';
import territoriesRouter from './territories.routes';
import activitiesRouter from './activities.routes';
import eventsRouter from './events.routes';
import runsRouter from './runs.routes';
import mapRouter from './map.routes';
import messagesRouter from './messages.routes';
import trainerRouter from './trainer.routes';
import workoutsRouter from './workouts.routes';

const apiRouter = Router();

// Public endpoint — no auth required
apiRouter.get('/version', (_req: Request, res: Response) => {
  const latestVersion = process.env.APP_VERSION ?? null;
  res.json({ latestVersion });
});

// Глобальное middleware авторизации для всех API роутов (modules/auth AuthProvider)
apiRouter.use(authMiddleware);

// Алиас: GET /api/me/profile → обработчик GET /api/users/me/profile
// Прямой forward вместо 302-редиректа, чтобы не терять заголовок Authorization
apiRouter.get('/me/profile', (req: Request, res: Response, next: NextFunction) => {
  req.url = '/me/profile';
  usersRouter(req, res, next);
});

// Подключаем роутеры для каждого домена
apiRouter.use('/users', usersRouter);
apiRouter.use('/cities', citiesRouter);
apiRouter.use('/clubs', clubsRouter);
apiRouter.use('/territories', territoriesRouter);
apiRouter.use('/activities', activitiesRouter);
apiRouter.use('/events', eventsRouter);
apiRouter.use('/runs', runsRouter);
apiRouter.use('/map', mapRouter);
apiRouter.use('/messages', messagesRouter);
apiRouter.use('/trainer', trainerRouter);
apiRouter.use('/workouts', workoutsRouter);

export default apiRouter;
