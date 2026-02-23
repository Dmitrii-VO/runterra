/**
 * Trainer profile entity
 */

export interface Certificate {
  name: string;
  date?: string;
  organization?: string;
}

export interface TrainerProfile {
  userId: string;
  bio?: string;
  specialization: string[];
  experienceYears: number;
  certificates: Certificate[];
  acceptsPrivateClients: boolean;
  createdAt: Date;
}
