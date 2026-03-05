"""
auth.py — Phone-number based authentication.

Allowed users:
  Prajwal  → 9110687983
  Ishwarya → 7338532833
"""

from fastapi import APIRouter, HTTPException
from models import LoginRequest, LoginResponse

router = APIRouter(prefix="/auth", tags=["Auth"])

# Hard-coded allowed users (no OTP — just phone number login)
ALLOWED_USERS = {
    "9110687983": "Prajwal",
    "7338532833": "Ishwarya",
}


def _make_token(phone: str) -> str:
    """
    Simple identity token: base64-like encoding of phone.
    (For a production app you'd use JWT — kept simple per spec.)
    """
    import base64
    return base64.b64encode(f"chatapp:{phone}".encode()).decode()


def verify_token(token: str) -> str | None:
    """Returns phone number if token is valid, else None."""
    import base64
    try:
        decoded = base64.b64decode(token.encode()).decode()
        prefix, phone = decoded.split(":", 1)
        if prefix == "chatapp" and phone in ALLOWED_USERS:
            return phone
    except Exception:
        pass
    return None


@router.post("/login", response_model=LoginResponse)
async def login(payload: LoginRequest):
    phone = payload.phone.strip()
    if phone not in ALLOWED_USERS:
        raise HTTPException(
            status_code=403,
            detail="Access denied. Only Prajwal and Ishwarya can use this app."
        )
    name = ALLOWED_USERS[phone]
    token = _make_token(phone)
    return LoginResponse(
        success=True,
        name=name,
        phone=phone,
        token=token,
        message=f"Welcome back, {name}! 👋"
    )


@router.get("/me")
async def get_me(token: str):
    phone = verify_token(token)
    if not phone:
        raise HTTPException(status_code=401, detail="Invalid token.")
    return {"phone": phone, "name": ALLOWED_USERS[phone]}


@router.get("/users")
async def get_users():
    """Returns both users — useful for the frontend to show contact info."""
    return {
        "users": [
            {"phone": p, "name": n} for p, n in ALLOWED_USERS.items()
        ]
    }
