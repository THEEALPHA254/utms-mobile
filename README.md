# UTMS Mobile Setup (Flutter + UTMS Backend)

This app consumes the Django backend in `UTMS-backend`.

## 1) Start backend first

From `UTMS-backend`:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

Keep this terminal running.

## 2) Run mobile app

From `UTMS-mobile`:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Use the right base URL for your target:

- Android emulator: `http://10.0.2.2:8000/api`
- iOS simulator: `http://127.0.0.1:8000/api`
- Physical phone on same Wi-Fi: `http://<YOUR_PC_LAN_IP>:8000/api`

Example for physical device:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api
```

## 3) Quick API checks

Open docs:

- Swagger: `http://127.0.0.1:8000/api/docs/`
- Schema: `http://127.0.0.1:8000/api/schema/`

Expected auth routes used by mobile:

- `POST /api/auth/login/`
- `POST /api/auth/register/student/`
- `POST /api/auth/token/refresh/`

## 4) End-to-end test flow

1. Launch backend.
2. Launch app with proper `API_BASE_URL`.
3. Register student account in app.
4. Login with same account.
5. Navigate screens:
   - Routes/trips list
   - My bookings
   - Wallet balance/top-up
   - Notifications
6. Force-close and reopen app to confirm token/session restore works.

## 5) If requests fail

- Confirm backend terminal is running and has no errors.
- Confirm device URL can reach server (wrong host is most common issue).
- If using physical device, ensure firewall allows port `8000`.
- Verify backend responds via browser or Postman first.
