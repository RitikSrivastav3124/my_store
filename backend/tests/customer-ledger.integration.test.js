const request = require('supertest');
const app = require('../src/app');
const Notification = require('../src/models/notification.model');

const registerOwner = async () => {
  const response = await request(app).post('/api/auth/register').send({
    name: 'Owner',
    phone: '+918888888888',
    email: 'owner@example.com',
    password: 'StrongPass123!'
  });

  return response.body.data.accessToken;
};

const createCustomer = async (token, openingDue = 0) => {
  const response = await request(app)
    .post('/api/customers')
    .set('Authorization', `Bearer ${token}`)
    .send({
      name: 'Customer One',
      phone: '+917777777777',
      email: 'customer@example.com',
      password: 'Customer123!',
      creditLimit: 5000,
      openingDue
    });

  expect(response.status).toBe(201);
  return response.body.data._id;
};

const ledgerRequest = (token, customerId, operation, payload) =>
  request(app)
    .post(`/api/customers/${customerId}/${operation}`)
    .set('Authorization', `Bearer ${token}`)
    .send(payload);

const getCustomer = (token, customerId) =>
  request(app).get(`/api/customers/${customerId}`).set('Authorization', `Bearer ${token}`);

describe('Owner customer and ledger APIs', () => {
  it('creates a customer, adds due, and records payment', async () => {
    const token = await registerOwner();
    const customerId = await createCustomer(token, 100);

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
    expect(await Notification.countDocuments()).toBe(1);

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
    expect(await Notification.countDocuments()).toBe(1);

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
    expect(await Notification.countDocuments()).toBe(2);
  });

  it('applies concurrent payments atomically and records their actual balances', async () => {
    const token = await registerOwner();
    const customerId = await createCustomer(token, 1000);

    const responses = await Promise.all([
      ledgerRequest(token, customerId, 'payment', {
        amount: 500,
        requestId: 'concurrent-payment-500'
      }),
      ledgerRequest(token, customerId, 'payment', {
        amount: 300,
        requestId: 'concurrent-payment-300'
      })
    ]);

    expect(responses.map((response) => response.status)).toEqual([201, 201]);
    expect(responses.map((response) => response.body.data.transaction.balanceAfter).sort((a, b) => a - b)).toEqual([
      200,
      500
    ]);
    responses.forEach((response) => {
      expect(response.body.data.customer.currentDue).toBe(response.body.data.transaction.balanceAfter);
    });

    const customer = await getCustomer(token, customerId);
    expect(customer.body.data.currentDue).toBe(200);
  });

  it('allows only one concurrent overpayment and never makes the balance negative', async () => {
    const token = await registerOwner();
    const customerId = await createCustomer(token, 100);

    const responses = await Promise.all([
      ledgerRequest(token, customerId, 'payment', {
        amount: 80,
        requestId: 'concurrent-overpayment-a'
      }),
      ledgerRequest(token, customerId, 'payment', {
        amount: 80,
        requestId: 'concurrent-overpayment-b'
      })
    ]);

    expect(responses.map((response) => response.status).sort()).toEqual([201, 400]);
    expect(responses.find((response) => response.status === 400).body.message).toBe(
      'Payment or reduction cannot exceed current due'
    );

    const customer = await getCustomer(token, customerId);
    expect(customer.body.data.currentDue).toBe(20);
  });

  it('applies concurrent due additions atomically', async () => {
    const token = await registerOwner();
    const customerId = await createCustomer(token, 1000);

    const responses = await Promise.all([
      ledgerRequest(token, customerId, 'addDue', {
        amount: 500,
        requestId: 'concurrent-add-due-500'
      }),
      ledgerRequest(token, customerId, 'addDue', {
        amount: 300,
        requestId: 'concurrent-add-due-300'
      })
    ]);

    expect(responses.map((response) => response.status)).toEqual([201, 201]);
    expect(responses.map((response) => response.body.data.transaction.balanceAfter).sort((a, b) => a - b)).toEqual([
      1500,
      1800
    ]);

    const customer = await getCustomer(token, customerId);
    expect(customer.body.data.currentDue).toBe(1800);
  });

  it('keeps the final balance correct for mixed concurrent ledger operations', async () => {
    const token = await registerOwner();
    const customerId = await createCustomer(token, 1000);

    const responses = await Promise.all([
      ledgerRequest(token, customerId, 'addDue', {
        amount: 500,
        requestId: 'concurrent-mixed-add'
      }),
      ledgerRequest(token, customerId, 'payment', {
        amount: 200,
        requestId: 'concurrent-mixed-payment'
      }),
      ledgerRequest(token, customerId, 'reduceDue', {
        amount: 300,
        requestId: 'concurrent-mixed-reduction'
      })
    ]);

    expect(responses.map((response) => response.status)).toEqual([201, 201, 201]);
    responses.forEach((response) => {
      expect(response.body.data.customer.currentDue).toBe(response.body.data.transaction.balanceAfter);
    });

    const customer = await getCustomer(token, customerId);
    expect(customer.body.data.currentDue).toBe(1000);
  });
});
