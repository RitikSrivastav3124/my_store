const mongoose = require('mongoose');
const ArchiveManifest = require('../src/models/archiveManifest.model');
const { ARCHIVE_STATES } = require('../src/constants/archiveStates');

describe('ArchiveManifest model', () => {
  const validManifest = () =>
    new ArchiveManifest({
      ownerId: new mongoose.Types.ObjectId(),
      periodStart: new Date('2026-01-01T00:00:00.000Z'),
      periodEnd: new Date('2026-01-02T00:00:00.000Z'),
      transactionCount: 0
    });

  it('requires batch fields and defaults to pending', () => {
    const manifest = validManifest();

    expect(manifest.validateSync()).toBeUndefined();
    expect(manifest.status).toBe(ARCHIVE_STATES.PENDING);
    expect(new ArchiveManifest().validateSync().errors).toEqual(
      expect.objectContaining({
        ownerId: expect.anything(),
        periodStart: expect.anything(),
        periodEnd: expect.anything(),
        transactionCount: expect.anything()
      })
    );
  });

  it('accepts only defined archive states and declares required indexes', () => {
    const manifest = validManifest();
    manifest.status = 'invalid';

    expect(manifest.validateSync().errors.status).toBeDefined();
    expect(ArchiveManifest.schema.indexes()).toEqual(
      expect.arrayContaining([
        [{ ownerId: 1, status: 1 }, { background: true }],
        [{ ownerId: 1, periodStart: -1 }, { background: true }],
        [{ storageProvider: 1, storageKey: 1 }, { background: true }]
      ])
    );
  });
});
