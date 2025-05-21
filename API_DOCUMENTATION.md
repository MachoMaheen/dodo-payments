# Dodo Payments API Documentation

This document provides detailed information about the Dodo Payments API endpoints, request/response formats, and example requests.

## Base URL

```
http://localhost:8080
```

## Authentication

Many endpoints require authentication using JSON Web Tokens (JWT). To authenticate, include the JWT token in the Authorization header:

```
Authorization: Bearer YOUR_JWT_TOKEN
```

You can obtain a JWT token by calling the `/users/login` endpoint.

## Endpoints

### Health Check

#### GET /health

Check if the API and database are operational.

**Response**:

```json
{
  "status": "ok",
  "message": "Service is healthy"
}
```

### User Management

#### POST /users/register

Register a new user account.

**Request Body**:

```json
{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "securePassword123"
}
```

**Validation**:

- `username`: 3-50 characters
- `email`: Valid email format
- `password`: At least 8 characters

**Response** (201 Created):

```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "username": "johndoe",
  "email": "john@example.com"
}
```

**Error Responses**:

- 400 Bad Request: Invalid input data
- 409 Conflict: Username or email already exists

#### POST /users/login

Authenticate a user and get a JWT token.

**Request Body**:

```json
{
  "username": "johndoe",
  "password": "securePassword123"
}
```

**Response** (200 OK):

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer"
}
```

**Error Responses**:

- 400 Bad Request: Invalid input data
- 401 Unauthorized: Invalid credentials

#### GET /users/profile

Get the authenticated user's profile.

**Headers**:

- `Authorization: Bearer YOUR_JWT_TOKEN`

**Response** (200 OK):

```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "username": "johndoe",
  "email": "john@example.com"
}
```

**Error Responses**:

- 401 Unauthorized: Missing or invalid token

### Transaction Management

#### POST /transactions

Create a new transaction.

**Headers**:

- `Authorization: Bearer YOUR_JWT_TOKEN`

**Request Body**:

```json
{
  "recipient_id": "123e4567-e89b-12d3-a456-426614174001",
  "amount": 100.5,
  "currency": "USD"
}
```

**Validation**:

- `recipient_id`: Valid UUID
- `amount`: Greater than 0
- `currency`: 3-letter code (e.g., USD, EUR)

**Response** (201 Created):

```json
{
  "id": "123e4567-e89b-12d3-a456-426614174002",
  "sender_id": "123e4567-e89b-12d3-a456-426614174000",
  "recipient_id": "123e4567-e89b-12d3-a456-426614174001",
  "amount": 100.5,
  "currency": "USD",
  "status": "completed",
  "created_at": "2025-05-21T12:34:56Z"
}
```

**Error Responses**:

- 400 Bad Request: Invalid input data or insufficient funds
- 401 Unauthorized: Missing or invalid token
- 404 Not Found: Recipient not found

#### GET /transactions/{id}

Get a specific transaction by ID.

**Headers**:

- `Authorization: Bearer YOUR_JWT_TOKEN`

**Parameters**:

- `id`: Transaction UUID

**Response** (200 OK):

```json
{
  "id": "123e4567-e89b-12d3-a456-426614174002",
  "sender_id": "123e4567-e89b-12d3-a456-426614174000",
  "recipient_id": "123e4567-e89b-12d3-a456-426614174001",
  "amount": 100.5,
  "currency": "USD",
  "status": "completed",
  "created_at": "2025-05-21T12:34:56Z"
}
```

**Error Responses**:

- 401 Unauthorized: Missing or invalid token
- 404 Not Found: Transaction not found or not accessible by the authenticated user

#### GET /transactions

List transactions for the authenticated user.

**Headers**:

- `Authorization: Bearer YOUR_JWT_TOKEN`

**Query Parameters**:

- `limit` (optional): Maximum number of transactions to return (default: 10)
- `offset` (optional): Number of transactions to skip (default: 0)
- `status` (optional): Filter by status (pending, completed, failed)

**Response** (200 OK):

```json
{
  "transactions": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174002",
      "sender_id": "123e4567-e89b-12d3-a456-426614174000",
      "recipient_id": "123e4567-e89b-12d3-a456-426614174001",
      "amount": 100.5,
      "currency": "USD",
      "status": "completed",
      "created_at": "2025-05-21T12:34:56Z"
    },
    {
      "id": "123e4567-e89b-12d3-a456-426614174003",
      "sender_id": "123e4567-e89b-12d3-a456-426614174001",
      "recipient_id": "123e4567-e89b-12d3-a456-426614174000",
      "amount": 50.25,
      "currency": "USD",
      "status": "completed",
      "created_at": "2025-05-20T15:45:30Z"
    }
  ],
  "total": 42
}
```

**Error Responses**:

- 401 Unauthorized: Missing or invalid token

### Account Management

#### GET /accounts/balance

Get the account balance for the authenticated user.

**Headers**:

- `Authorization: Bearer YOUR_JWT_TOKEN`

**Response** (200 OK):

```json
{
  "balance": 899.5,
  "currency": "USD"
}
```

**Error Responses**:

- 401 Unauthorized: Missing or invalid token

## Error Responses

All error responses follow this format:

```json
{
  "status": "error",
  "message": "Detailed error message"
}
```

Common HTTP status codes:

- 400: Bad Request (invalid input data)
- 401: Unauthorized (missing or invalid authentication)
- 404: Not Found (resource not found)
- 409: Conflict (resource already exists)
- 429: Too Many Requests (rate limit exceeded)
- 500: Internal Server Error

## Rate Limiting

The API implements rate limiting to prevent abuse. Current limits:

- User registration and login: 10 requests per minute
- All other authenticated endpoints: 100 requests per minute

When rate limits are exceeded, the API will respond with a 429 Too Many Requests status code.
