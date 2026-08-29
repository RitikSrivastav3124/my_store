const request = require('supertest');
const ExcelJS = require('exceljs');
const app = require('../src/app');
const User = require('../src/models/user.model');
const Customer = require('../src/models/customer.model');
const ROLES = require('../src/constants/roles');
const { USER_STATUS } = require('../src/constants/statusCodes');

const binaryParser = (response, callback) => {
  const chunks = [];
  response.on('data', (chunk) => chunks.push(chunk));
  response.on('end', () => callback(null, Buffer.concat(chunks)));
};

const registerOwner = async () => {
  const response = await request(app).post('/api/auth/register').send({
    name: 'Export Owner',
    phone: '+919999999999',
    email: 'export-owner@example.com',
    password: 'StrongPass123!'
  });

  return response.body.data.accessToken;
};

const createOutstandingCustomers = async (ownerId) => {
  const batchUsers = Array.from({ length: 501 }, (_value, index) => ({
    name: `Batch Customer ${String(index).padStart(3, '0')}`,
    phone: `+910000${String(index).padStart(6, '0')}`,
    email: `batch-customer-${index}@example.com`,
    password: 'not-used',
    role: ROLES.CUSTOMER,
    status: USER_STATUS.ACTIVE
  }));
  batchUsers.push(
    {
      name: 'Customer .*',
      phone: '+919100000001',
      email: 'literal@example.com',
      password: 'not-used',
      role: ROLES.CUSTOMER,
      status: USER_STATUS.ACTIVE
    },
    {
      name: 'Deleted Customer',
      phone: '+919100000002',
      email: 'deleted@example.com',
      password: 'not-used',
      role: ROLES.CUSTOMER,
      status: USER_STATUS.DELETED
    }
  );

  const users = await User.insertMany(batchUsers);
  await Customer.insertMany(
    users.map((user) => ({
      ownerId,
      userId: user._id,
      creditLimit: 5000,
      currentDue: 100
    }))
  );
};

describe('Outstanding exports', () => {
  it('streams all formats in batches while preserving outstanding filters', async () => {
    const token = await registerOwner();
    const owner = await User.findOne({ email: 'export-owner@example.com' });
    await createOutstandingCustomers(owner._id);

    const csvResponse = await request(app)
      .get('/api/reports/export/csv')
      .set('Authorization', `Bearer ${token}`)
      .buffer(true)
      .parse(binaryParser);
    const csv = csvResponse.body.toString('utf8');
    const csvRows = csv.trimEnd().split('\n');
    const exportedNames = csvRows.slice(1).map((row) => row.match(/^"((?:""|[^"])*)"/)[1]);

    expect(csvResponse.status).toBe(200);
    expect(csvResponse.headers['content-type']).toContain('text/csv');
    expect(csvRows[0]).toBe('"Name","Phone","Email","Status","Current Due","Credit Limit","Updated At"');
    expect(exportedNames).toHaveLength(502);
    expect(new Set(exportedNames).size).toBe(502);
    expect(exportedNames).toContain('Batch Customer 000');
    expect(exportedNames).toContain('Batch Customer 500');
    expect(exportedNames).toContain('Customer .*');
    expect(exportedNames).not.toContain('Deleted Customer');

    const literalSearchResponse = await request(app)
      .get('/api/reports/export/csv')
      .query({ search: '.*' })
      .set('Authorization', `Bearer ${token}`)
      .buffer(true)
      .parse(binaryParser);

    expect(literalSearchResponse.status).toBe(200);
    expect(literalSearchResponse.body.toString('utf8')).toContain('"Customer .*"');
    expect(literalSearchResponse.body.toString('utf8')).not.toContain('Batch Customer');

    const excelResponse = await request(app)
      .get('/api/reports/export/excel')
      .query({ search: 'Batch Customer 500' })
      .set('Authorization', `Bearer ${token}`)
      .buffer(true)
      .parse(binaryParser);
    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(excelResponse.body);
    const worksheet = workbook.getWorksheet('Outstanding');

    expect(excelResponse.status).toBe(200);
    expect(excelResponse.headers['content-type']).toContain(
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    );
    expect(workbook.creator).toBe('Khata Ledger');
    expect(workbook.created).toBeInstanceOf(Date);
    expect(worksheet.getRow(1).values.slice(1)).toEqual([
      'Name',
      'Phone',
      'Email',
      'Status',
      'Current Due',
      'Credit Limit',
      'Updated At'
    ]);
    expect(worksheet.rowCount).toBe(2);
    expect(worksheet.getRow(2).getCell('A').value).toBe('Batch Customer 500');

    const pdfResponse = await request(app)
      .get('/api/reports/export/pdf')
      .query({ search: 'Batch Customer 500' })
      .set('Authorization', `Bearer ${token}`)
      .buffer(true)
      .parse(binaryParser);

    expect(pdfResponse.status).toBe(200);
    expect(pdfResponse.headers['content-type']).toContain('application/pdf');
    expect(pdfResponse.body.subarray(0, 5).toString()).toBe('%PDF-');
  });
});
