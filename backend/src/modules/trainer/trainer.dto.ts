/**
 * Trainer profile DTOs and Zod schemas
 */

import { z } from 'zod';

const specializations = ['MARATHON', 'SPRINT', 'TRAIL', 'RECOVERY', 'GENERAL'] as const;

const CertificateSchema = z.object({
  name: z.string().min(1).max(200),
  date: z.string().optional(),
  organization: z.string().optional(),
});

export const CreateTrainerProfileSchema = z.object({
  bio: z.string().max(2000).optional(),
  specialization: z.array(z.enum(specializations)).min(1),
  experienceYears: z.number().int().min(0).max(50),
  certificates: z.array(CertificateSchema).max(20).optional(),
  acceptsPrivateClients: z.boolean().optional(),
});

export const UpdateTrainerProfileSchema = CreateTrainerProfileSchema.partial();

export type CreateTrainerProfileDto = z.infer<typeof CreateTrainerProfileSchema>;
export type UpdateTrainerProfileDto = z.infer<typeof UpdateTrainerProfileSchema>;
