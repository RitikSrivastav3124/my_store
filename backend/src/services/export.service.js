const PDFDocument = require('pdfkit');
const ExcelJS = require('exceljs');
const env = require('../config/env');
const ReportService = require('./report.service');

const escapeCsvValue = (value) => {
  if (value === null || value === undefined) return '';
  const text = String(value);
  return /^[=+\-@\t\r]/.test(text) ? `'${text}` : text;
};

const outstandingColumns = [
  'Name',
  'Phone',
  'Email',
  'Status',
  'Current Due',
  'Credit Limit',
  'Updated At'
];

const outstandingRow = (customer) => ({
  Name: escapeCsvValue(customer.name),
  Phone: escapeCsvValue(customer.phone),
  Email: escapeCsvValue(customer.email || ''),
  Status: escapeCsvValue(customer.status),
  'Current Due': customer.currentDue,
  'Credit Limit': customer.creditLimit,
  'Updated At': escapeCsvValue(customer.updatedAt)
});

const csvLine = (values) =>
  `${values
    .map((value) =>
      typeof value === 'number' ? String(value) : `"${String(value ?? '').replace(/"/g, '""')}"`
    )
    .join(',')}\n`;

const writeChunk = (stream, chunk) =>
  new Promise((resolve, reject) => {
    if (stream.write(chunk)) return resolve();

    const onDrain = () => {
      cleanup();
      resolve();
    };
    const onError = (error) => {
      cleanup();
      reject(error);
    };
    const cleanup = () => {
      stream.removeListener('drain', onDrain);
      stream.removeListener('error', onError);
    };

    stream.once('drain', onDrain);
    stream.once('error', onError);
  });

const endResponse = (res) =>
  new Promise((resolve, reject) => {
    const onError = (error) => {
      cleanup();
      reject(error);
    };
    const onFinish = () => {
      cleanup();
      resolve();
    };
    const cleanup = () => {
      res.removeListener('error', onError);
      res.removeListener('finish', onFinish);
    };
    res.once('error', onError);
    res.once('finish', onFinish);
    res.end();
  });

const pipePdf = (doc, res) =>
  new Promise((resolve, reject) => {
    const cleanup = () => {
      doc.removeListener('error', onError);
      res.removeListener('error', onError);
      res.removeListener('finish', onFinish);
    };
    const onError = (error) => {
      cleanup();
      reject(error);
    };
    const onFinish = () => {
      cleanup();
      resolve();
    };

    doc.once('error', onError);
    res.once('error', onError);
    res.once('finish', onFinish);
    doc.pipe(res);
  });

const abortResponse = (res) => {
  if (!res.writableEnded) res.destroy();
};

class ExportService {
  static async outstandingCsv(ownerId, query, res) {
    try {
      await writeChunk(res, csvLine(outstandingColumns));

      for await (const customers of ReportService.outstandingExportBatches(ownerId, query)) {
        for (const customer of customers) {
          const row = outstandingRow(customer);
          await writeChunk(res, csvLine(outstandingColumns.map((column) => row[column])));
        }
      }

      await endResponse(res);
    } catch (error) {
      abortResponse(res);
      throw error;
    }
  }

  static async outstandingExcel(ownerId, query, res) {
    const workbook = new ExcelJS.stream.xlsx.WorkbookWriter({
      stream: res,
      creator: env.reportBrandName,
      created: new Date(),
      useSharedStrings: false,
      useStyles: true
    });
    try {
      const worksheet = workbook.addWorksheet('Outstanding');
      worksheet.columns = outstandingColumns.map((key) => ({ header: key, key, width: 20 }));
      worksheet.getRow(1).font = { bold: true };

      for await (const customers of ReportService.outstandingExportBatches(ownerId, query)) {
        for (const customer of customers) worksheet.addRow(outstandingRow(customer)).commit();
      }

      worksheet.commit();
      await workbook.commit();
    } catch (error) {
      abortResponse(res);
      throw error;
    }
  }

  static async outstandingPdf(ownerId, query, res) {
    const doc = new PDFDocument({ margin: 40 });
    const completed = pipePdf(doc, res);

    try {
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

      for await (const customers of ReportService.outstandingExportBatches(ownerId, query)) {
        for (const customer of customers) {
          if (doc.y > 740) doc.addPage();
          doc.text(customer.name, 40, doc.y, { continued: true, width: 150 });
          doc.text(customer.phone, 190, doc.y, { continued: true, width: 120 });
          doc.text(String(customer.currentDue), 310, doc.y, { continued: true, width: 80 });
          doc.text(customer.status, 390, doc.y, { width: 100 });
          doc.moveDown(0.4);
        }
      }

      doc.end();
      await completed;
    } catch (error) {
      if (!doc.destroyed) doc.destroy(error);
      abortResponse(res);
      await completed.catch(() => undefined);
      throw error;
    }
  }
}

module.exports = ExportService;
