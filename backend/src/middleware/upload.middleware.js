const multer = require('multer');
const AppError = require('../utils/appError');

const storage = multer.memoryStorage();

const upload = multer({
  storage,
  limits: {
    fileSize: 2 * 1024 * 1024
  },
  fileFilter: (_req, file, cb) => {
    if (!file.mimetype.startsWith('image/')) {
      return cb(new AppError('Only image uploads are allowed', 400));
    }

    return cb(null, true);
  }
});

module.exports = upload;
