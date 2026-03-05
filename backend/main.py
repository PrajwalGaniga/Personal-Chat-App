"""
main.py — FastAPI Chat App Entry Point

Private chat app for:
  Prajwal  → 9110687983
  Ishwarya → 7338532833

Features:
  ✅ Phone-number login (no OTP)
  ✅ Real-time WebSocket chat
  ✅ Message history (MongoDB, IST timestamps)
  ✅ Image upload → saved to backend/img/
  ✅ WhatsApp-style date labels (Today, Yesterday, DD Mon YYYY)
"""

import os
import json
import sys
from datetime import datetime, timezone, timedelta

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from database import messages_collection
from websocket_manager import manager
from routes.auth import router as auth_router, ALLOWED_USERS, verify_token
from routes.messages import router as messages_router
from routes.uploads import router as uploads_router

# ─── App Setup ───────────────────────────────────────────────────────────────

app = FastAPI(
    title="Prajwal & Ishwarya Chat API",
    description="Private WhatsApp-like chat backend for two users.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],           # Tighten this in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Static file serving for images ──────────────────────────────────────────

IMG_DIR = os.path.join(os.path.dirname(__file__), "img")
os.makedirs(IMG_DIR, exist_ok=True)

# ─── Routers ─────────────────────────────────────────────────────────────────

app.include_router(auth_router)
app.include_router(messages_router)
app.include_router(uploads_router)

# ─── Constants ───────────────────────────────────────────────────────────────

IST = timezone(timedelta(hours=5, minutes=30))


def _date_label(dt: datetime) -> str:
    now_ist = datetime.now(IST).date()
    msg_date = dt.astimezone(IST).date()
    delta = (now_ist - msg_date).days
    if delta == 0:
        return "Today"
    elif delta == 1:
        return "Yesterday"
    return msg_date.strftime("%d %b %Y")


# ─── WebSocket endpoint ───────────────────────────────────────────────────────

@app.websocket("/ws/{phone}")
async def websocket_chat(websocket: WebSocket, phone: str, token: str = Query(...)):
    """
    WebSocket endpoint for real-time messaging.

    Connect via: ws://localhost:8000/ws/{phone}?token={token}

    The token is the base64 token received from POST /auth/login.
    Messages sent as JSON: { "content": "hello", "message_type": "text" }
    Messages received (broadcast) as JSON:
    {
      "id": "...",
      "sender_phone": "...",
      "sender_name": "...",
      "content": "...",
      "message_type": "text",
      "timestamp": "...",
      "date_label": "Today",
      "event": "new_message"
    }
    """
    # Validate token
    verified_phone = verify_token(token)
    if verified_phone != phone or phone not in ALLOWED_USERS:
        await websocket.close(code=4001)
        return

    await manager.connect(websocket, phone)

    # Notify both users about online status
    await manager.broadcast({
        "event": "user_online",
        "phone": phone,
        "name": ALLOWED_USERS[phone],
        "online_users": manager.online_users(),
    })

    try:
        while True:
            raw = await websocket.receive_text()
            try:
                data = json.loads(raw)
            except json.JSONDecodeError:
                await websocket.send_text(json.dumps({
                    "event": "error",
                    "message": "Invalid JSON payload."
                }))
                continue

            content = data.get("content", "").strip()
            message_type = data.get("message_type", "text")

            if not content:
                continue

            # Persist to MongoDB
            now = datetime.now(timezone.utc)
            doc = {
                "sender_phone": phone,
                "content": content,
                "message_type": message_type,
                "timestamp": now,
            }
            result = await messages_collection.insert_one(doc)

            # Broadcast to all connected clients
            payload = {
                "event": "new_message",
                "id": str(result.inserted_id),
                "sender_phone": phone,
                "sender_name": ALLOWED_USERS[phone],
                "content": content,
                "message_type": message_type,
                "timestamp": now.isoformat(),
                "date_label": _date_label(now),
            }
            await manager.broadcast(payload)

    except WebSocketDisconnect:
        manager.disconnect(phone)
        await manager.broadcast({
            "event": "user_offline",
            "phone": phone,
            "name": ALLOWED_USERS[phone],
            "online_users": manager.online_users(),
        })


# ─── Health check ─────────────────────────────────────────────────────────────

@app.get("/", tags=["Health"])
async def root():
    return {
        "status": "running",
        "app": "Prajwal & Ishwarya Chat",
        "docs": "/docs",
        "websocket": "ws://localhost:8000/ws/{phone}?token={token}",
        "users": [
            {"name": "Prajwal", "phone": "9110687983"},
            {"name": "Ishwarya", "phone": "7338532833"},
        ],
    }


@app.get("/health", tags=["Health"])
async def health():
    try:
        from database import client
        await client.admin.command("ping")
        db_status = "connected"
    except Exception as e:
        db_status = f"error: {e}"

    return {
        "api": "ok",
        "database": db_status,
        "active_connections": manager.online_users(),
        "timestamp": datetime.now(IST).isoformat(),
    }


# ─── Run ──────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
