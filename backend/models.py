from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


# ─── Auth ────────────────────────────────────────────────────────────────────

class LoginRequest(BaseModel):
    phone: str  # "9110687983" or "7338532833"


class LoginResponse(BaseModel):
    success: bool
    name: str
    phone: str
    token: str  # simple identity token (phone number encoded)
    message: str


# ─── Messages ────────────────────────────────────────────────────────────────

class MessageCreate(BaseModel):
    sender_phone: str
    content: str
    message_type: str = "text"  # "text" | "image"


class MessageOut(BaseModel):
    id: str
    sender_phone: str
    sender_name: str
    content: str              # text content OR image filename (for images)
    message_type: str         # "text" | "image"
    timestamp: datetime
    date_label: str           # e.g. "Today", "Yesterday", "05 Mar 2026"


# ─── WebSocket payload ───────────────────────────────────────────────────────

class WSMessage(BaseModel):
    sender_phone: str
    content: str
    message_type: str = "text"
