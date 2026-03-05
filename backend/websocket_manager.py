from typing import Dict, List
from fastapi import WebSocket
import json


class ConnectionManager:
    """
    Manages active WebSocket connections for the two-user chat app.
    Only Prajwal (9110687983) and Ishwarya (7338532833) can connect.
    """

    def __init__(self):
        # Maps phone_number -> WebSocket
        self.active_connections: Dict[str, WebSocket] = {}

    async def connect(self, websocket: WebSocket, phone: str):
        await websocket.accept()
        self.active_connections[phone] = websocket
        print(f"[WS] Connected: {phone}  | Active: {list(self.active_connections.keys())}")

    def disconnect(self, phone: str):
        self.active_connections.pop(phone, None)
        print(f"[WS] Disconnected: {phone}  | Active: {list(self.active_connections.keys())}")

    async def broadcast(self, message: dict):
        """Send a message to ALL connected clients (both Prajwal & Ishwarya)."""
        dead = []
        for phone, ws in self.active_connections.items():
            try:
                await ws.send_text(json.dumps(message, default=str))
            except Exception as e:
                print(f"[WS] Failed to send to {phone}: {e}")
                dead.append(phone)
        for phone in dead:
            self.disconnect(phone)

    def is_online(self, phone: str) -> bool:
        return phone in self.active_connections

    def online_users(self) -> List[str]:
        return list(self.active_connections.keys())


# Singleton manager shared across routes
manager = ConnectionManager()
