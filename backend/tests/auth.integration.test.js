const request = require('supertest');
const app = require('../src/app');

describe('Auth API', () => {
  it('registers an owner and returns access and refresh tokens', async () => {
    const response = await request(app).post('/api/auth/register').send({
      name: 'Store Owner',
      phone: '+919999999999',
      email: 'owner@example.com',
      password: 'StrongPass123'
    });

    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);
    expect(response.body.data.user.role).toBe('owner');
    expect(response.body.data.accessToken).toBeTruthy();
    expect(response.body.data.refreshToken).toBeTruthy();
    expect(response.body.data.user.password).toBeUndefined();
  });

  it('logs in a registered owner', async () => {
    await request(app).post('/api/auth/register').send({
      name: 'Store Owner',
      phone: '+919999999999',
      email: 'owner@example.com',
      password: 'StrongPass123'
    });

    const response = await request(app).post('/api/auth/login').send({
      identifier: 'owner@example.com',
      password: 'StrongPass123'
    });

    expect(response.status).toBe(200);
    expect(response.body.data.user.email).toBe('owner@example.com');
  });
});
