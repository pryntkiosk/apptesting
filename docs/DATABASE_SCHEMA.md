# Database Schema (MongoDB)

The app reuses the existing Prynt MongoDB database (`DB_NAME`, default
`printflow`). New collections were added for delivery operations. IDs are UUID
strings stored in an `id` field (not Mongo's `_id`).

## `admins`
Existing collection, extended for mobile login + push.

| Field | Type | Notes |
|-------|------|-------|
| id | string (uuid) | PK |
| username | string | web admin login |
| email | string | mobile login (added) |
| password_hash | string | bcrypt |
| role | string | `main` \| `regular` |
| fcm_tokens | string[] | device tokens (added) |
| created_at | ISO string | |

## `delivery_partners` (new)

| Field | Type | Notes |
|-------|------|-------|
| id | string (uuid) | PK |
| name | string | |
| phone | string | |
| email | string | unique, mobile login |
| password_hash | string | bcrypt |
| status | string | `active` \| `inactive` |
| fcm_tokens | string[] | device tokens |
| created_at | ISO string | |
| created_by | string | admin id |

## `kiosks`
Existing collection, extended with location + inventory.

| Field | Type | Notes |
|-------|------|-------|
| id | string (uuid) | PK |
| name | string | Kiosk Name |
| location_name | string | College / Location (added) |
| address | string | Full address (added) |
| city | string | |
| latitude / longitude | number | Maps coordinates (added) |
| pages_remaining | int | current paper (pages) |
| paper_capacity | int | for % computation (added, default 500) |
| ink_level | int | 0–100 (added) |
| low_paper_threshold | int | pages, default 70 (added) |
| low_ink_threshold | int | %, default 20 (added) |
| pages_printed | int | lifetime |
| pricing | object | bw/color single/double |
| is_active | bool | in service |
| status | string | `idle` \| `offline` … |
| last_seen / last_updated | ISO string | |

Computed in API responses (not stored): `paper_level_pct`, `is_online`.

## `service_requests` (new)

| Field | Type | Notes |
|-------|------|-------|
| id | string (uuid) | PK |
| request_number | string | e.g. `SR-00001` |
| kiosk_id / kiosk_name | string | |
| location_name / address | string | snapshot of kiosk |
| latitude / longitude | number | for navigation |
| alert_type | string | `paper` \| `ink` |
| level_value | int | pages or % at trigger time |
| status | string | `pending` \| `accepted` \| `in_progress` \| `completed` |
| assigned_to | string \| null | partner id |
| assigned_name | string \| null | partner name (shown to admin) |
| source | string | `auto` \| `manual` |
| created_at / accepted_at / in_progress_at / completed_at | ISO string | |

## `alerts` (new)
The triggering event; one is created with each service request.

| Field | Type | Notes |
|-------|------|-------|
| id | string (uuid) | PK |
| kiosk_id / kiosk_name | string | |
| alert_type | string | `paper` \| `ink` |
| level_value | int | |
| request_id | string | linked service request |
| source | string | `auto` \| `manual` |
| resolved | bool | true when request completed |
| created_at | ISO string | |

## `notification_logs` (new)
Audit + in-app activity feed.

| Field | Type | Notes |
|-------|------|-------|
| id | string (uuid) | PK |
| title / body | string | |
| data | object | FCM data payload |
| audience | string | `admins` \| `partners` \| `admins+partners` |
| sent / failed | int | delivery counts |
| delivered | bool | whether FCM was configured |
| created_at | ISO string | |

## Indexes (recommended for production)

```javascript
db.delivery_partners.createIndex({ email: 1 }, { unique: true })
db.service_requests.createIndex({ status: 1, assigned_to: 1 })
db.service_requests.createIndex({ kiosk_id: 1, alert_type: 1, status: 1 })
db.alerts.createIndex({ resolved: 1 })
db.notification_logs.createIndex({ created_at: -1 })
db.kiosks.createIndex({ id: 1 }, { unique: true })
```

## Real-time / monitoring

- **Auto alerts:** after each completed print job the backend calls
  `check_kiosk_levels()`, and a background `monitor_loop` re-scans every 5 min.
- A new request is **only** created if no open (`pending`/`accepted`/
  `in_progress`) request of the same type already exists for that kiosk
  (prevents duplicates).
- **First-come claiming** uses an atomic conditional update
  (`status: pending, assigned_to: null`), so exactly one partner wins.
