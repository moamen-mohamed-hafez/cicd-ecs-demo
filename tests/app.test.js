const request = require('supertest');
const app = require('../src/app');

describe('Health endpoint', () => {
  it('returns 200 with status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});

describe('API route', () => {
  it('returns JSON with message field', async () => {
    const res = await request(app).get('/api');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('message');
  });
});