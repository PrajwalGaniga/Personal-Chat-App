"""
uploads.py — Image upload endpoint.
Images are saved to backend/img/ folder.
"""

import os
import uuid
import aiofiles
from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from fastapi.responses import FileResponse
from datetime import datetime, timezone
from database import messages_collection

router = APIRouter(prefix="/uploads", tags=["Uploads"])

ALLOWED_USERS = {
    "9110687983": "Prajwal",
    "7338532833": "Ishwarya",
}

ALLOWED_MIME = {"image/jpeg", "image/png", "image/gif", "image/webp"}
IMG_DIR = os.path.join(os.path.dirname(__file__), "..", "img")

# Ensure img directory exists
os.makedirs(IMG_DIR, exist_ok=True)


@router.post("/image")
async def upload_image(
    sender_phone: str = Form(...),
    file: UploadFile = File(...),
):
    """
    Upload an image, save it to backend/img/, and store a message record in MongoDB.
    Returns the saved filename and the message document.
    """
    if sender_phone not in ALLOWED_USERS:
        raise HTTPException(status_code=403, detail="Unauthorized sender.")

    if file.content_type not in ALLOWED_MIME:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type: {file.content_type}. Allowed: JPEG, PNG, GIF, WEBP."
        )

    # Generate unique filename preserving extension
    ext = file.filename.rsplit(".", 1)[-1] if "." in file.filename else "jpg"
    unique_name = f"{uuid.uuid4().hex}.{ext}"
    save_path = os.path.join(IMG_DIR, unique_name)

    # Save file to disk
    async with aiofiles.open(save_path, "wb") as out:
        content = await file.read()
        await out.write(content)

    # Save message record to MongoDB
    now = datetime.now(timezone.utc)
    doc = {
        "sender_phone": sender_phone,
        "content": unique_name,          # store filename as content
        "message_type": "image",
        "timestamp": now,
        "original_filename": file.filename,
    }
    result = await messages_collection.insert_one(doc)

    return {
        "success": True,
        "message_id": str(result.inserted_id),
        "filename": unique_name,
        "original_filename": file.filename,
        "url": f"/uploads/image/{unique_name}",
        "sender_phone": sender_phone,
        "sender_name": ALLOWED_USERS[sender_phone],
        "timestamp": now.isoformat(),
        "message_type": "image",
    }


@router.get("/image/{filename}")
async def get_image(filename: str):
    """Serve a saved image by filename."""
    # Sanitize filename — no directory traversal
    filename = os.path.basename(filename)
    file_path = os.path.join(IMG_DIR, filename)

    if not os.path.isfile(file_path):
        raise HTTPException(status_code=404, detail="Image not found.")

    return FileResponse(file_path)
