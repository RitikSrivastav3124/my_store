const UserRepository = require('../repositories/user.repository');
const { verifyAccessToken } = require('../utils/jwt');
const AppError = require('../utils/appError');
const { USER_STATUS } = require('../constants/statusCodes');

const authenticate = async (req, _res, next) => {
  try {
    const header = req.headers.authorization || '';
    const [scheme, token] = header.split(' ');

    if (scheme !== 'Bearer' || !token) {
      throw new AppError('Authentication token is required', 401);
    }

    const payload = verifyAccessToken(token);
    const user = await UserRepository.findById(payload.sub);

    if (!user || user.status !== USER_STATUS.ACTIVE) {
      throw new AppError('User is not active or does not exist', 401);
    }

    req.user = user;
    next();
  } catch (error) {
    next(error);
  }
};

module.exports = authenticate;
