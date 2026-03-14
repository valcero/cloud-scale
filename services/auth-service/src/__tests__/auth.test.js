const request = require('supertest');
const app = require('../index');

describe('Auth Service', () => {
  describe('GET /health/live', () => {
    it('should return 200 with ok status', async () => {
      const res = await request(app).get('/health/live');
      expect(res.status).toBe(200);
      expect(res.body.status).toBe('ok');
    });
  });

  describe('POST /api/auth/register', () => {
    it('should return 400 if email is missing', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({ password: 'test123' });
      expect(res.status).toBe(400);
    });

    it('should return 400 if password is missing', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({ email: 'test@test.com' });
      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/auth/login', () => {
    it('should return 400 if credentials missing', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({});
      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/auth/verify', () => {
    it('should return 401 without token', async () => {
      const res = await request(app).get('/api/auth/verify');
      expect(res.status).toBe(401);
    });
  });
});
