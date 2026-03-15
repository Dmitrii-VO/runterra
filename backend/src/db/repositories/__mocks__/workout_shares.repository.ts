/**
 * Mock for WorkoutSharesRepository
 */

export const mockWorkoutSharesRepository = {
  share: jest.fn().mockResolvedValue({
    id: 'share-1',
    workoutId: 'workout-1',
    senderId: 'user-1',
    recipientId: 'user-2',
    sharedAt: new Date(),
    accepted: false,
  }),
  findReceivedByUser: jest.fn().mockResolvedValue([]),
  accept: jest.fn().mockResolvedValue({
    id: 'workout-copy-1',
    authorId: 'user-2',
    name: 'Copied Workout',
    type: 'EASY_RUN',
    difficulty: 'BEGINNER',
    isTemplate: false,
    isFavorite: false,
    createdAt: new Date(),
  }),
};

export const getWorkoutSharesRepository = jest.fn(() => mockWorkoutSharesRepository);
export class WorkoutSharesRepository {}
