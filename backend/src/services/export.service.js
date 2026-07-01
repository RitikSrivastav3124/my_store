const PDFDocument = require('pdfkit');
const XLSX = require('xlsx');
const { Parser } = require('@json2csv/plainjs');
const env = require('../config/env');
const ReportService = require('./report.service');

const flattenOutstanding = (customers) =>
  customers.map((customer) => ({
    Name: customer.name,
    Phone: customer.phone,
    Email: customer.email || '',
    Status: customer.status,
    'Current Due': customer.currentDue,
    'Credit Limit': customer.creditLimit,
    'Updated At': customer.updatedAt
  }));

const pdfToBuffer = (doc) =>
  new Promise((resolve, reject) => {
    const chunks = [];
    doc.on('data', (chunk) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
    doc.end();
  });

class ExportService {
  static async outstandingCsv(ownerId, query) {
    const report = await ReportService.outstanding(ownerId, { ...query, page: 1, limit: 10000 });
    const parser = new Parser();
    return parser.parse(flattenOutstanding(report.customers));
  }

  static async outstandingExcel(ownerId, query) {
    const report = await ReportService.outstanding(ownerId, { ...query, page: 1, limit: 10000 });
    const worksheet = XLSX.utils.json_to_sheet(flattenOutstanding(report.customers));
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Outstanding');
    return XLSX.write(workbook, { type: 'buffer', bookType: 'xlsx' });
  }

  static async outstandingPdf(ownerId, query) {
    const report = await ReportService.outstanding(ownerId, { ...query, page: 1, limit: 10000 });
    const doc = new PDFDocument({ margin: 40 });

    doc.fontSize(18).text(env.reportBrandName, { align: 'center' });
    doc.moveDown(0.5);
    doc.fontSize(13).text('Outstanding Customers Report', { align: 'center' });
    doc.moveDown();

    const generatedAt = new Date().toISOString();
    doc.fontSize(9).text(`Generated at: ${generatedAt}`);
    doc.moveDown();

    doc.fontSize(10).text('Name', 40, doc.y, { continued: true, width: 150 });
    doc.text('Phone', 190, doc.y, { continued: true, width: 120 });
    doc.text('Due', 310, doc.y, { continued: true, width: 80 });
    doc.text('Status', 390, doc.y, { width: 100 });
    doc.moveDown(0.5);

    report.customers.forEach((customer) => {
      if (doc.y > 740) doc.addPage();
      doc.text(customer.name, 40, doc.y, { continued: true, width: 150 });
      doc.text(customer.phone, 190, doc.y, { continued: true, width: 120 });
      doc.text(String(customer.currentDue), 310, doc.y, { continued: true, width: 80 });
      doc.text(customer.status, 390, doc.y, { width: 100 });
      doc.moveDown(0.4);
    });

    return pdfToBuffer(doc);
  }
}

module.exports = ExportService;
