const request = require('supertest');
const app = require('../src/app');
const RefreshToken = require('../src/models/refreshToken.model');
const { hashToken } = require('../src/utils/jwt');

describe('Auth API', () => {
  it('registers an owner and returns access and refresh tokens', async () => {
    const response = await request(app).post('/api/auth/register').send({
      name: 'Store Owner',
      phone: '+919999999999',
      email: 'owner@example.com',
      password: 'StrongPass123!'
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
      password: 'StrongPass123!'
    });

    const response = await request(app).post('/api/auth/login').send({
      identifier: 'owner@example.com',
      password: 'StrongPass123!'
    });

    expect(response.status).toBe(200);
    expect(response.body.data.user.email).toBe('owner@example.com');
  });

  it('rotates a refresh token and revokes the original token', async () => {
    const registration = await request(app).post('/api/auth/register').send({
      name: 'Store Owner',
      phone: '+919999999999',
      email: 'owner@example.com',
      password: 'StrongPass123!'
    });
    const oldRefreshToken = registration.body.data.refreshToken;

    const response = await request(app).post('/api/auth/refresh').send({ refreshToken: oldRefreshToken });

    expect(response.status).toBe(200);
    expect(response.body.data.accessToken).toBeTruthy();
    expect(response.body.data.refreshToken).toBeTruthy();

    const oldToken = await RefreshToken.findOne({ tokenHash: hashToken(oldRefreshToken) });
    const replacement = await RefreshToken.findOne({ tokenHash: hashToken(response.body.data.refreshToken) });
    expect(oldToken.revokedAt).not.toBeNull();
    expect(oldToken.replacedByTokenHash).toBe(replacement.tokenHash);
    expect(replacement.revokedAt).toBeNull();
  });

  it('rejects reuse of an already rotated refresh token', async () => {
    const registration = await request(app).post('/api/auth/register').send({
      name: 'Store Owner',
      phone: '+919999999999',
      email: 'owner@example.com',
      password: 'StrongPass123!'
    });
    const oldRefreshToken = registration.body.data.refreshToken;

    await request(app).post('/api/auth/refresh').send({ refreshToken: oldRefreshToken }).expect(200);
    const response = await request(app).post('/api/auth/refresh').send({ refreshToken: oldRefreshToken });

    expect(response.status).toBe(401);
    expect(response.body.message).toBe('Invalid refresh token');
  });

  it('allows exactly one concurrent rotation of the same refresh token', async () => {
    const registration = await request(app).post('/api/auth/register').send({
      name: 'Store Owner',
      phone: '+919999999999',
      email: 'owner@example.com',
      password: 'StrongPass123!'
    });
    const oldRefreshToken = registration.body.data.refreshToken;

    const responses = await Promise.all([
      request(app).post('/api/auth/refresh').send({ refreshToken: oldRefreshToken }),
      request(app).post('/api/auth/refresh').send({ refreshToken: oldRefreshToken })
    ]);
    const successfulResponse = responses.find((response) => response.status === 200);
    const failedResponse = responses.find((response) => response.status === 401);

    expect(successfulResponse).toBeDefined();
    expect(failedResponse).toBeDefined();
    expect(failedResponse.body.message).toBe('Invalid refresh token');

    const tokens = await RefreshToken.find({ userId: registration.body.data.user._id });
    const originalToken = tokens.find((token) => token.tokenHash === hashToken(oldRefreshToken));
    const replacements = tokens.filter((token) => token.replacedByTokenHash === null);
    expect(originalToken.revokedAt).not.toBeNull();
    expect(replacements).toHaveLength(1);
    expect(replacements[0].tokenHash).toBe(hashToken(successfulResponse.body.data.refreshToken));

    await request(app)
      .post('/api/auth/refresh')
      .send({ refreshToken: successfulResponse.body.data.refreshToken })
      .expect(200);
  });
});
