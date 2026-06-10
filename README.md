# Geolocation API

Sinatra + PostgreSQL API for IP/URL geolocation (ipstack). JSON:API responses.

## Setup

**Prerequisites:** Docker Desktop, [ipstack](https://ipstack.com/) API key.

```bash
git clone <your-repo-url>
cd geolocation_api
cp .env.example .env   # set IPSTACK_ACCESS_KEY, optionally APP_PORT
make up
```

**Base URL:** `http://localhost:<APP_PORT>` (default `3001`)

## Swagger UI

**Docs & testing:** `http://localhost:<APP_PORT>/api-docs`

Use Swagger to explore and call all endpoints.

### Protected routes

1. Get `client_secret` (shown once on first boot):
   ```bash
   docker compose logs web | grep client_secret
   ```
   Lost? Run `make credentials`. Default `client_id` is `default`.

2. In Swagger, open **POST /api/v1/auth/login** → **Try it out** → submit `client_id` and `client_secret`.

3. Copy `access_token` from the response.

4. Click **Authorize** (top right) → enter `Bearer <access_token>` → **Authorize**.

5. Call any other endpoint from Swagger. Re-login after 24h or container restart.

## Endpoints

| Method | Path | Notes |
|--------|------|-------|
| POST | `/api/v1/auth/login` | public |
| GET | `/api/v1/geolocations` | `filter[query]`, `filter[query_type]`, `page_size`, `page_number` |
| GET | `/api/v1/geolocations/:id` | |
| POST | `/api/v1/geolocations` | requires `IPSTACK_ACCESS_KEY` |
| DELETE | `/api/v1/geolocations/:id` | |

## Commands

```bash
make up          # start
make test        # rspec
make credentials # new client_secret
make seed        # re-seed
make fresh       # wipe DB + rebuild
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| 401 login | `make credentials` |
| 401 API | re-login in Swagger; use `access_token` |
| 503 on POST | set `IPSTACK_ACCESS_KEY` in `.env`, restart |
| empty list | `make seed` |
| migration error | `make fresh` |
