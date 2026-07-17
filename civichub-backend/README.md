# CivicHub Backend

Spring Boot backend for the CivicHub MVP.

## Authentication API

### Register

`POST /api/auth/register`

Sample request:

```json
{
  "fullName": "Nguyen Van A",
  "email": "citizen@example.com",
  "password": "strongPassword",
  "phone": "0909000000"
}
```

Successful response uses HTTP `201 Created` and returns an access token.

### Login

`POST /api/auth/login`

Sample request:

```json
{
  "email": "citizen@example.com",
  "password": "strongPassword"
}
```

Successful response uses HTTP `200 OK` and returns an access token.

### Current User

`GET /api/auth/me`

Requires an access token:

```http
Authorization: Bearer <accessToken>
```

The endpoint returns safe profile fields only. It does not return password hashes or internal security details.

## JWT

- Token type: `Bearer`
- Expiration unit in API responses: seconds
- Expiration source: `app.jwt.expiration-ms` / `JWT_EXPIRATION_MS`
- JWT subject: user email
- JWT claims: `userId`, `role`
- Production secrets must be supplied through environment variables. Do not commit real secrets.
