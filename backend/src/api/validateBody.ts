import { Request, Response, NextFunction } from 'express';
import { AnyZodObject, ZodError, ZodIssue } from 'zod';

/**
 * Generic middleware for validating request body against a Zod schema.
 *
 * NOTE: This middleware is intentionally technical-only:
 * - It validates shape and basic types of req.body at runtime.
 * - It does NOT implement any domain or business rules.
 *
 * Error format (API envelope):
 * - HTTP 400
 * - {
 *     code: "validation_error",
 *     message: "Request body validation failed",
 *     details: {
 *       fields: { field: string; message: string; code: string }[]
 *     }
 *   }
 */

interface ValidationFieldError {
  field: string;
  message: string;
  code: string;
}

function mapZodIssueToFieldError(issue: ZodIssue): ValidationFieldError {
  const fieldPath = issue.path.join('.');

  return {
    field: fieldPath,
    message: issue.message,
    // Use zod issue code as a normalized technical error code
    code: issue.code,
  };
}
export function validateBody(schema: AnyZodObject) {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      const result = schema.safeParse(req.body);

      if (!result.success) {
        const error: ZodError = result.error;

        res.status(400).json({
          code: 'validation_error',
          message: 'Request body validation failed',
          details: {
            fields: error.issues.map(mapZodIssueToFieldError),
          },
        });
        return;
      }

      // Replace body with parsed result to ensure correct types at runtime
      req.body = result.data;

      next();
    } catch (_error) {
      // Fallback in case of unexpected runtime errors inside schema
      res.status(400).json({
        code: 'validation_error',
        message: 'Request body validation failed',
        details: {
          fields: [],
        },
      });
    }
  };
}

