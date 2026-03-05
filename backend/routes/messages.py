"""
messages.py — REST endpoints for message history and sending messages.
WebSocket-based real-time chat is handled in main.py.
"""

from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from datetime import datetime, timezone, timedelta
from bson import ObjectId
from database import messages_collection
from models import MessageCreate, MessageOut

router = APIRouter(prefix="/messages", tags=["Messages"])

ALLOWED_USERS = {
    "9110687983": "Prajwal",
    "7338532833": "Ishwarya",
}

IST = timezone(timedelta(hours=5, minutes=30))


def _date_label(dt: datetime) -> str:
    """Return human-readable date label like WhatsApp."""
    now_ist = datetime.now(IST).date()
    msg_date = dt.astimezone(IST).date()
    delta = (now_ist - msg_date).days
    if delta == 0:
        return "Today"
    elif delta == 1:
        return "Yesterday"
    else:
        return msg_date.strftime("%d %b %Y")


def _serialize(doc: dict) -> MessageOut:
    ts: datetime = doc["timestamp"]
    return MessageOut(
        id=str(doc["_id"]),
        sender_phone=doc["sender_phone"],
        sender_name=ALLOWED_USERS.get(doc["sender_phone"], "Unknown"),
        content=doc["content"],
        message_type=doc.get("message_type", "text"),
        timestamp=ts,
        date_label=_date_label(ts),
    )


@router.get("/history", response_model=List[MessageOut])
async def get_history(
    limit: int = Query(50, ge=1, le=200),
    skip: int = Query(0, ge=0),
):
    """Fetch paginated message history (newest ‹limit› messages)."""
    cursor = messages_collection.find().sort("timestamp", 1)
    docs = await cursor.to_list(length=None)
    # Apply pagination from the end (WhatsApp-style — latest messages)
    total = len(docs)
    start = max(0, total - limit - skip)
    end = max(0, total - skip)
    page = docs[start:end]
    return [_serialize(d) for d in page]


@router.get("/history/date/{date_str}", response_model=List[MessageOut])
async def get_messages_by_date(date_str: str):
    """
    Fetch messages for a specific date.
    date_str format: YYYY-MM-DD
    """
    try:
        target = datetime.strptime(date_str, "%Y-%m-%d").replace(tzinfo=IST)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")

    start = target.replace(hour=0, minute=0, second=0, microsecond=0)
    end = target.replace(hour=23, minute=59, second=59, microsecond=999999)

    cursor = messages_collection.find({
        "timestamp": {"$gte": start, "$lte": end}
    }).sort("timestamp", 1)
    docs = await cursor.to_list(length=None)
    return [_serialize(d) for d in docs]


@router.post("/send", response_model=MessageOut)
async def send_message(payload: MessageCreate):
    """
    Send a text message via REST (fallback — prefer WebSocket for real-time).
    """
    if payload.sender_phone not in ALLOWED_USERS:
        raise HTTPException(status_code=403, detail="Unauthorized sender.")

    now = datetime.now(timezone.utc)
    doc = {
        "sender_phone": payload.sender_phone,
        "content": payload.content,
        "message_type": payload.message_type,
        "timestamp": now,
    }
    result = await messages_collection.insert_one(doc)
    doc["_id"] = result.inserted_id
    return _serialize(doc)


@router.delete("/{message_id}")
async def delete_message(message_id: str, sender_phone: str):
    """Delete a message by ID (only sender can delete their own message)."""
    try:
        oid = ObjectId(message_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid message ID.")

    doc = await messages_collection.find_one({"_id": oid})
    if not doc:
        raise HTTPException(status_code=404, detail="Message not found.")
    if doc["sender_phone"] != sender_phone:
        raise HTTPException(status_code=403, detail="You can only delete your own messages.")

    await messages_collection.delete_one({"_id": oid})
    return {"success": True, "message": "Message deleted."}
