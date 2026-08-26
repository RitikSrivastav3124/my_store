const request = require('supertest');
const app = require('../src/app');

const registerOwner = async () => {
  const response = await request(app).post('/api/auth/register').send({
    name: 'Owner',
    phone: '+918888888888',
    email: 'owner@example.com',
    password: 'StrongPass123!'
  });

  return response.body.data.accessToken;
};

describe('Owner customer and ledger APIs', () => {
  it('creates a customer, adds due, and records payment', async () => {
    const token = await registerOwner();

    const createResponse = await request(app)
      .post('/api/customers')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'Customer One',
        phone: '+917777777777',
        email: 'customer@example.com',
        password: 'Customer123!',
        creditLimit: 5000,
        openingDue: 100
      });

    expect(createResponse.status).toBe(201);
    const customerId = createResponse.body.data._id;

    const dueRequestId = 'test-add-due-0001';
    const dueResponse = await request(app)
      .post(`/api/customers/${customerId}/addDue`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        amount: 250,
        description: 'Groceries',
        paymentMethod: 'other',
        requestId: dueRequestId
      });

    expect(dueResponse.status).toBe(201);
    expect(dueResponse.body.data.customer.currentDue).toBe(350);

    const duplicateDueResponse = await request(app)
      .post(`/api/customers/${customerId}/addDue`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        amount: 250,
        description: 'Groceries',
        paymentMethod: 'other',
        requestId: dueRequestId
      });

    expect(duplicateDueResponse.status).toBe(201);
    expect(duplicateDueResponse.body.data.customer.currentDue).toBe(350);
    expect(duplicateDueResponse.body.data.idempotentReplay).toBe(true);

    const paymentResponse = await request(app)
      .post(`/api/customers/${customerId}/payment`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        amount: 150,
        description: 'Cash payment',
        paymentMethod: 'cash'
      });

    expect(paymentResponse.status).toBe(201);
    expect(paymentResponse.body.data.customer.currentDue).toBe(200);
  });
});
