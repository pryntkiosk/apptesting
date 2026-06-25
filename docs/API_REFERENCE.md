# Mobile API Reference

Base URL: `<API_BASE_URL>/api/mobile`
Auth: `Authorization: Bearer <token>` on all routes except login.

## Auth

### POST `/auth/login`
```json
{ "email": "admin@prynt.app", "password": "admin123" }
```
→ `{ "token": "...", "user": { "id", "name", "email", "role", "user_type" } }`
Works for both admins (email or username) and delivery partners.

### GET `/auth/me`
Returns the current user.

### POST `/fcm/register` / `/fcm/unregister`
```json
{ "token": "<fcm-device-token>" }
```

## Delivery partners (admin only)

| Method | Path | Body / Notes |
|--------|------|--------------|
| GET | `/partners` | list |
| POST | `/partners` | `{name, phone, email, password, status}` |
| PUT | `/partners/{id}` | any subset incl. `password`, `status` |
| DELETE | `/partners/{id}` | unassigns their open requests |

## Kiosks

| Method | Path | Role | Notes |
|--------|------|------|-------|
| GET | `/kiosks` | any | adds `paper_level_pct`, `is_online`, `status` |
| GET | `/kiosks/{id}` | any | |
| POST | `/kiosks` | admin | create (location + levels) |
| PUT | `/kiosks/{id}` | admin | update; re-checks levels |
| POST | `/kiosks/{id}/levels` | admin | `{pages_remaining?, ink_level?}` |
| DELETE | `/kiosks/{id}` | admin | also deletes its requests/alerts |
| POST | `/kiosks/{id}/alert` | admin | `{alert_type: "paper"\|"ink"}` → manual alert |

## Service requests

| Method | Path | Role | Notes |
|--------|------|------|-------|
| GET | `/requests?status=` | admin | all (optional status filter) |
| GET | `/requests` | delivery | `{available:[], assigned:[]}` |
| GET | `/requests/{id}` | any | |
| POST | `/requests/{id}/accept` | delivery | atomic claim; `409` if already taken |
| POST | `/requests/{id}/status` | assigned partner / admin | `{status: "in_progress"\|"completed"}` |

On `completed`: linked alert resolved; paper restored to capacity / ink to 100%;
admins notified.

## Dashboards

| Method | Path | Role |
|--------|------|------|
| GET | `/dashboard/admin` | admin |
| GET | `/dashboard/delivery` | delivery |
| GET | `/notifications?limit=` | any | activity feed |

### Admin dashboard response
```json
{
  "total_kiosks": 4, "online_kiosks": 1, "offline_kiosks": 3,
  "active_alerts": 2, "pending_requests": 2, "accepted_requests": 0,
  "in_progress_requests": 0, "completed_requests": 5,
  "recent_activity": [ { "...service_request..." } ]
}
```

## Error format
Non-2xx responses return `{ "detail": "message" }`. The app surfaces `detail`
directly. `401` triggers automatic logout; `409` is shown as a soft warning
(e.g. request already claimed).
