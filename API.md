# Dodo Payments API Documentation

## Overview

The Dodo Payments API allows you to manage users, transactions, and account balances in a secure payment system. All endpoints except for registration, login, and health check require authentication via a JWT token.

## Base URL

```
http://localhost:8080
```

## Authentication

Most endpoints require authentication via a JWT token. After logging in, you'll receive a token that should be included in the `Authorization` header of subsequent requests:

```
Authorization: Bearer <your_token>
```

---

## Endpoints

### Health Check

#### GET /health

Check the health status of the API.

**Response (200 OK)**

```json
{
  "status": "ok",
  "message": "Service is healthy"
}
```

---

### User Management

#### POST /api/users/register

Register a new user.

**Request Body**

```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "SecurePassword123"
}
```

**Response (201 Created)**

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-1234567890ab",
  "username": "john_doe",
  "email": "john@example.com",
  "created_at": "2025-05-22T14:30:15.123456Z",
  "updated_at": "2025-05-22T14:30:15.123456Z"
}
```

#### POST /api/users/login

Login with existing user credentials.

**Request Body**

```json
{
  "username": "john_doe",
  "password": "SecurePassword123"
}
```

**Response (200 OK)**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user_id": "a1b2c3d4-e5f6-7890-abcd-1234567890ab"
}
```

#### GET /api/users/profile

Get the current user's profile.

**Headers**

```
Authorization: Bearer <your_token>
```

**Response (200 OK)**

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-1234567890ab",
  "username": "john_doe",
  "email": "john@example.com",
  "created_at": "2025-05-22T14:30:15.123456Z",
  "updated_at": "2025-05-22T14:30:15.123456Z"
}
```

---

### Account Management

#### GET /api/accounts/balance

Get the current user's account balance.

**Headers**

```
Authorization: Bearer <your_token>
```

**Response (200 OK)**

```json
{
  "balance": 100.0,
  "currency": "USD"
}
```

---

### Transaction Management

#### POST /api/transactions

Create a new transaction.

**Headers**

```
Authorization: Bearer <your_token>
```

**Request Body**

```json
{
  "recipient_id": "b2c3d4e5-f6a7-8901-bcde-234567890abc",
  "amount": 10.0,
  "currency": "USD",
  "description": "Payment for services"
}
```

**Response (201 Created)**

```json
{
  "id": "c3d4e5f6-a7b8-9012-cdef-3456789012ab",
  "sender_id": "a1b2c3d4-e5f6-7890-abcd-1234567890ab",
  "recipient_id": "b2c3d4e5-f6a7-8901-bcde-234567890abc",
  "amount": 10.0,
  "currency": "USD",
  "description": "Payment for services",
  "status": "completed",
  "created_at": "2025-05-22T14:35:22.123456Z"
}
```

#### GET /api/transactions/:id

Get a specific transaction by ID.

**Headers**

```
Authorization: Bearer <your_token>
```

**Response (200 OK)**

```json
{
  "id": "c3d4e5f6-a7b8-9012-cdef-3456789012ab",
  "sender_id": "a1b2c3d4-e5f6-7890-abcd-1234567890ab",
  "recipient_id": "b2c3d4e5-f6a7-8901-bcde-234567890abc",
  "amount": 10.0,
  "currency": "USD",
  "description": "Payment for services",
  "status": "completed",
  "created_at": "2025-05-22T14:35:22.123456Z"
}
```

#### GET /api/transactions

Get a list of transactions for the current user.

**Headers**

```
Authorization: Bearer <your_token>
```

**Query Parameters**

- `limit` (optional, default: 10): Number of transactions to return
- `offset` (optional, default: 0): Offset for pagination
- `status` (optional): Filter by status ("pending", "completed", "failed")

**Response (200 OK)**

```json
{
  "transactions": [
    {
      "id": "c3d4e5f6-a7b8-9012-cdef-3456789012ab",
      "sender_id": "a1b2c3d4-e5f6-7890-abcd-1234567890ab",
      "recipient_id": "b2c3d4e5-f6a7-8901-bcde-234567890abc",
      "amount": 10.0,
      "currency": "USD",
      "description": "Payment for services",
      "status": "completed",
      "created_at": "2025-05-22T14:35:22.123456Z"
    },
    {
      "id": "d4e5f6a7-b8c9-0123-defg-456789012345",
      "sender_id": "a1b2c3d4-e5f6-7890-abcd-1234567890ab",
      "recipient_id": "c3d4e5f6-a7b8-9012-cdef-3456789012ab",
      "amount": 5.0,
      "currency": "USD",
      "description": "Dinner payment",
      "status": "completed",
      "created_at": "2025-05-22T13:22:10.123456Z"
    }
  ],
  "total": 10,
  "page": 0,
  "per_page": 10
}
```

---

### Admin Endpoints

#### POST /admin/fund/:user_id

Fund a user's account (for testing purposes).

**Request Body**

```json
{
  "amount": 100.0
}
```

**Response (200 OK)**

```json
{
  "status": "success",
  "credited": 100.0,
  "user_id": "a1b2c3d4-e5f6-7890-abcd-1234567890ab"
}
```

---

## Error Responses

All endpoints may return error responses in the following format:

**Error Response (4xx/5xx)**

```json
{
  "status": "error",
  "message": "A description of what went wrong"
}
```

Common error status codes:

- 400: Bad Request (invalid input data)
- 401: Unauthorized (missing or invalid authentication)
- 403: Forbidden (insufficient permissions)
- 404: Not Found (resource doesn't exist)
- 500: Internal Server Error (server-side issue)

## Rate Limiting

API requests are rate-limited to prevent abuse. If you exceed the rate limit, you'll receive a 429 Too Many Requests response.

## Security

- All sensitive API endpoints require JWT authentication
- Passwords are securely hashed before storage
- The API enforces SSL/TLS when deployed in production
- Input validation is performed on all endpoints
