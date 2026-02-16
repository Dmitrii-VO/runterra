/**
 * Workout entity
 */

export interface Workout {
  id: string;
  authorId: string;
  clubId?: string;
  name: string;
  description?: string;
  type: string;
  difficulty: string;
  targetMetric: string;
  createdAt: Date;
}
