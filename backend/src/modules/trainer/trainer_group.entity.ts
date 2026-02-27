/**
 * Trainer group entity
 */

export interface TrainerGroup {
  id: string;
  clubId: string;
  trainerId: string;
  name: string;
  createdAt: Date;
}

export interface TrainerGroupMember {
  groupId: string;
  userId: string;
  joinedAt: Date;
}
