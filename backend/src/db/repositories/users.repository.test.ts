import { UsersRepository, getUsersRepository } from './users.repository';

const mockQuery = jest.fn();
jest.mock('../client', () => ({
  getDbPool: () => null,
  createDbPool: () => ({
    query: mockQuery,
    on: () => {},
  }),
}));

function userRow(overrides: Partial<{
  id: string;
  firebase_uid: string;
  email: string;
  name: string;
  first_name: string | null;
  last_name: string | null;
  birth_date: Date | string | null;
  country: string | null;
  gender: string | null;
  avatar_url: string | null;
  city_id: string | null;
  is_mercenary: boolean;
  status: string;
  created_at: Date;
  updated_at: Date;
}> = {}) {
  return {
    id: 'user-1',
    firebase_uid: 'firebase-uid-1',
    email: 'test@example.com',
    name: 'Test User',
    first_name: 'Test',
    last_name: 'User',
    birth_date: null,
    country: null,
    gender: null,
    avatar_url: null,
    city_id: null,
    is_mercenary: false,
    status: 'active',
    created_at: new Date(),
    updated_at: new Date(),
    ...overrides,
  };
}

describe('UsersRepository', () => {
  let repo: UsersRepository;

  beforeAll(() => {
    repo = getUsersRepository();
  });

  beforeEach(() => {
    mockQuery.mockReset();
  });

  it('maps birth_date Date to YYYY-MM-DD without UTC shift', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [userRow({ birth_date: new Date(1994, 1, 3) })],
      rowCount: 1,
    });

    const user = await repo.findById('user-1');

    expect(user).toBeDefined();
    expect(user!.birthDate).toBe('1994-02-03');
  });

  it('maps birth_date string to YYYY-MM-DD', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [userRow({ birth_date: '1994-02-03T00:00:00.000Z' })],
      rowCount: 1,
    });

    const user = await repo.findById('user-1');

    expect(user).toBeDefined();
    expect(user!.birthDate).toBe('1994-02-03');
  });

  it('drops unsupported gender values', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [userRow({ gender: 'other' })],
      rowCount: 1,
    });

    const user = await repo.findByFirebaseUid('firebase-uid-1');

    expect(user).toBeDefined();
    expect(user!.gender).toBeUndefined();
  });
});
