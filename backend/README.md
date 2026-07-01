# Khata Ledger Backend

Production-ready Node.js, Express, and MongoDB backend for a shop/store credit ledger application.

## Architecture

The backend follows MVC with a service and repository layer:

- `controllers/`: HTTP request and response orchestration.
- `services/`: business rules, ledger integrity, auth, reports, notifications, exports.
- `repositories/`: Mongoose query abstraction.
- `validators/`: `express-validator` request contracts.
- `middleware/`: authentication, authorization, validation, rate limiting, centralized errors.
- `models/`: normalized MongoDB schemas and indexes.
- `config/`: environment, MongoDB, Firebase, Swagger.

Financial writes are performed by the service layer and create:

- customer due update
- transaction record
- audit log
- notification record
- optional Firebase Cloud Messaging push

## Setup

```bash
cp .env.example .env
npm install
npm run dev
```

The API runs on `http://localhost:5000/api` by default.

Swagger UI is available at:

```txt
http://localhost:5000/api-docs
```

## Environment

Required production values:

- `MONGO_URI`
- `JWT_ACCESS_SECRET`
- `JWT_REFRESH_SECRET`
- `CORS_ORIGIN`

Optional Firebase Cloud Messaging:

- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`

## API Summary

Auth:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/logout`
- `POST /api/auth/refresh`
- `POST /api/auth/change-password`
- `POST /api/auth/fcm-token`

Owner:

- `GET /api/customers`
- `POST /api/customers`
- `GET /api/customers/:id`
- `PUT /api/customers/:id`
- `DELETE /api/customers/:id`
- `POST /api/customers/:id/suspend`
- `POST /api/customers/:id/addDue`
- `POST /api/customers/:id/payment`
- `POST /api/customers/:id/reduceDue`
- `GET /api/customers/:id/history`

Customer:

- `GET /api/customer/profile`
- `GET /api/customer/due`
- `GET /api/customer/history`

Reports:

- `GET /api/reports/dashboard`
- `GET /api/reports/monthly`
- `GET /api/reports/outstanding`
- `GET /api/reports/transactions`
- `GET /api/reports/export/pdf`
- `GET /api/reports/export/csv`
- `GET /api/reports/export/excel`

Notifications:

- `GET /api/notifications`
- `PUT /api/notifications/:id/read`

## Testing

```bash
npm test
```

The test suite uses `mongodb-memory-server` and `supertest`.

## Deployment

Use a managed MongoDB database, set strong JWT secrets, configure an HTTPS reverse proxy, and restrict `CORS_ORIGIN` to trusted app origins. Run the app with a process manager such as PM2, Docker, or your platform runtime.
