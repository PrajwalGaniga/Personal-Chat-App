# Prajwal & Ishwarya Chat — Backend

## Setup

```bash
cd backend
pip install -r requirements.txt
```

## Run the server

```bash
python main.py
# OR
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## API Docs
Visit http://localhost:8000/docs

## Authentication
`POST /auth/login`
```json
{ "phone": "9110687983" }   // Prajwal
{ "phone": "7338532833" }   // Ishwarya
```
Returns a `token` — use it for WebSocket and protected endpoints.

## Real-time Chat (WebSocket)
```
ws://localhost:8000/ws/{phone}?token={token}
```
Send: `{ "content": "Hi!", "message_type": "text" }`

## Image Upload
`POST /uploads/image`  (multipart form)
- `sender_phone`: your phone number
- `file`: image file

Images saved to `backend/img/`. Served at `/uploads/image/{filename}`.

## Message History
`GET /messages/history?limit=50&skip=0`
`GET /messages/history/date/2026-03-05`
