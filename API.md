# Dodo Payments API Documentation

This document provides information about the API endpoints available in the Dodo Payments system, including request/response formats and example requests.

## Base URL

All API endpoints are relative to the base URL: `http://localhost:8080/api`

## Authentication

Most endpoints require authentication using JWT tokens. To authenticate, include the token in the HTTP header:

```
Authorization: Bearer <your_jwt_token>
```

You can obtain a JWT token by logging in through the `/api/users/login` endpoint.

## Endpoints

### User Management

#### Register a new user

**Endpoint:** `POST /users/register`

**Description:** Creates a new user account

**Request Body:**

```json
{
  "username": "johndoe",
  "email": "john.doe@example.com",
  "password": "securepassword123"
}
```

**Response (201 Created):**

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-1234567890ab",
  "username": "johndoe",
  "email": "john.doe@example.com",
  "created_at": "2025-05-22T10:30:45Z",
  "updated_at": "2025-05-22T10:30:45Z"
}
```

**Possible Errors:**

- 400 Bad Request - Invalid input
- 409 Conflict - Username or email already exists

#### User login

**Endpoint:** `POST /users/login`

**Description:** Authenticates a user and returns a JWT token

**Request Body:**

```json
{
  "username": "johndoe",
  "password": "securepassword123"
}
```

**Response (200 OK):**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Possible Errors:**

- 400 Bad Request - Invalid input
- 401 Unauthorized - Invalid credentials

#### Get user profile

**Endpoint:** `GET /users/profile`

**Description:** Returns the profile of the currently authenticated user

**Authentication Required:** Yes

**Response (200 OK):**

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-1234567890ab",
  "username": "johndoe",
  "email": "john.doe@example.com",
  "created_at": "2025-05-22T10:30:45Z",
  "updated_at": "2025-05-22T10:30:45Z"
}
```

**Possible Errors:**

- 401 Unauthorized - Invalid or missing token
- 404 Not Found - User not found

#### Update user profile

**Endpoint:** `PUT /users/profile`

**Description:** Updates the profile of the currently authenticated user

**Authentication Required:** Yes

**Request Body:**

```json
{
  "email": "new.email@example.com"
}
```

**Response (200 OK):**

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-1234567890ab",
  "username": "johndoe",
  "email": "new.email@example.com",
  "created_at": "2025-05-22T10:30:45Z",
  "updated_at": "2025-05-22T11:45:15Z"
}
```

**Possible Errors:**

- 400 Bad Request - Invalid input
- 401 Unauthorized - Invalid or missing token
- 409 Conflict - Email already in use by another user

### Account Management

#### Get user account balance

**Endpoint:** `GET /accounts/balance`

**Description:** Returns the account balance of the currently authenticated user

**Authentication Required:** Yes

**Response (200 OK):**

```json
{
  "user_id": "a1b2c3d4-e5f6-7890-abcd-1234567890ab",
  "balance": "1250.75",
  "currency": "USD"
}
```

**Possible Errors:**

- 401 Unauthorized - Invalid or missing token
- 404 Not Found - Account not found

### Transaction Management

#### Create a new transaction

**Endpoint:** `POST /transactions`

**Description:** Creates a new transaction from the authenticated user to the recipient

**Authentication Required:** Yes

**Request Body:**

```json
{
  "recipient_username": "janedoe",
  "amount": "50.25",
  "description": "Lunch payment"
}
```

**Response (201 Created):**

```json
{
  "id": "b2c3d4e5-f6a7-8901-bcde-23456789abcd",
  "sender_id": "a1b2c3d4-e5f6-7890-abcd-1234567890ab",
  "recipient_id": "f6a7b8c9-d0e1-2345-fghi-6789abcdef01",
  "amount": "50.25",
  "description": "Lunch payment",
  "status": "completed",
  "created_at": "2025-05-22T14:20:30Z"
}
```

**Possible Errors:**

- 400 Bad Request - Invalid input or insufficient funds
- 401 Unauthorized - Invalid or missing token
- 404 Not Found - Recipient not found

#### Get transaction by ID

**Endpoint:** `GET /transactions/{transaction_id}`

**Description:** Returns details of a specific transaction

**Authentication Required:** Yes

**URL Parameters:**

- `transaction_id`: UUID of the transaction

**Response (200 OK):**

```json
{
  "id": "b2c3d4e5-f6a7-8901-bcde-23456789abcd",
  "sender_id": "a1b2c3d4-e5f6-7890-abcd-1234567890ab",
  "recipient_id": "f6a7b8c9-d0e1-2345-fghi-6789abcdef01",
  "amount": "50.25",
  "description": "Lunch payment",
  "status": "completed",
  "created_at": "2025-05-22T14:20:30Z"
}
```

**Possible Errors:**

- 401 Unauthorized - Invalid or missing token
- 403 Forbidden - User not authorized to view this transaction
- 404 Not Found - Transaction not found

#### List user transactions

**Endpoint:** `GET /transactions`

**Description:** Returns a list of transactions for the authenticated user

**Authentication Required:** Yes

**Query Parameters:**

- `limit` (optional): Maximum number of transactions to return (default: 10)
- `offset` (optional): Number of transactions to skip (default: 0)
- `type` (optional): Type of transactions to return ("sent", "received", or "all", default: "all")

**Response (200 OK):**

```json
{
  "transactions": [
    {
      "id": "b2c3d4e5-f6a7-8901-bcde-23456789abcd",
      "sender_id": "a1b2c3d4-e5f6-7890-abcd-1234567890ab",
      "recipient_id": "f6a7b8c9-d0e1-2345-fghi-6789abcdef01",
      "amount": "50.25",
      "description": "Lunch payment",
      "status": "completed",
      "created_at": "2025-05-22T14:20:30Z"
    },
    {
      "id": "c3d4e5f6-a7b8-9012-cdef-3456789abcde",
      "sender_id": "f6a7b8c9-d0e1-2345-fghi-6789abcdef01",
      "recipient_id": "a1b2c3d4-e5f6-7890-abcd-1234567890ab",
      "amount": "25.50",
      "description": "Movie ticket",
      "status": "completed",
      "created_at": "2025-05-21T19:30:15Z"
    }
  ],
  "total": 2
}
```

**Possible Errors:**

- 400 Bad Request - Invalid query parameters
- 401 Unauthorized - Invalid or missing token
