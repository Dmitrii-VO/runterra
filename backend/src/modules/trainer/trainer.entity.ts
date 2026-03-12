/**
 * Trainer profile entity
 */

export interface Certificate {
  name: string;
  date?: string;
  organization?: string;
}

export type TrainerClientStatus = 'pending' | 'active' | 'rejected';

export interface TrainerClient {
  id: string;
  trainerId: string;
  clientId: string;
  status: TrainerClientStatus;
  createdAt: Date;
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
