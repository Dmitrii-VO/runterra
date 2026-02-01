/**
 * Unit tests for validateBody middleware.
 * No HTTP server; only req/res/next mocks.
 */

import { Request, Response, NextFunction } from 'express';
import { validateBody } from './validateBody';
import { z } from 'zod';

const schema = z.object({
  name: z.string(),
  count: z.number().int().optional(),
});

describe('validateBody', () => {
  let req: Partial<Request>;
  let res: Partial<Response>;
  let next: NextFunction;

  beforeEach(() => {
    req = { body: {} };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    next = jest.fn();
  });

  it('should call next and replace body with parsed data when payload is valid', () => {
    req.body = { name: 'Test', count: 5 };
    const middleware = validateBody(schema);
    middleware(req as Request, res as Response, next);

    expect(next).toHaveBeenCalledTimes(1);
    expect(res.status).not.toHaveBeenCalled();
    expect(req.body).toEqual({ name: 'Test', count: 5 });
  });

  it('should return 400 with validation_error when required field is missing', () => {
    req.body = { count: 5 };
    const middleware = validateBody(schema);
    middleware(req as Request, res as Response, next);

    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        code: 'validation_error',
        message: 'Request body validation failed',
        details: expect.objectContaining({
          fields: expect.any(Array),
        }),
      })
    );
    const fields = (res.json as jest.Mock).mock.calls[0][0].details.fields;
    expect(fields.length).toBeGreaterThan(0);
    expect(fields.some((f: { field: string }) => f.field === 'name')).toBe(true);
  });

  it('should return 400 when type is wrong', () => {
    req.body = { name: 'Test', count: 'not-a-number' };
    const middleware = validateBody(schema);
    middleware(req as Request, res as Response, next);

    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(400);
    expect((res.json as jest.Mock).mock.calls[0][0].code).toBe('validation_error');
  });
});
