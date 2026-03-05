// lib/config/constants.dart
// baseHost = LAN IP of the PC running the backend.
// Physical Android device → use PC's Wi-Fi IP (not localhost).
// Android emulator       → use 10.0.2.2:8000
// Desktop/Chrome         → use localhost:8000

class AppConstants {
  // ── Backend host ────────────────────────────────────────────────────
  static const String baseHost = '192.168.18.202:8000';
  static const String httpBase = 'http://$baseHost';
  static const String wsBase   = 'ws://$baseHost';

  // ── REST endpoints ──────────────────────────────────────────────────
  static const String loginUrl        = '$httpBase/auth/login';
  static const String meUrl           = '$httpBase/auth/me';
  static const String usersUrl        = '$httpBase/auth/users';
  static const String historyUrl      = '$httpBase/messages/history';
  static const String sendUrl         = '$httpBase/messages/send';
  static const String uploadUrl       = '$httpBase/uploads/image';
  static String imageUrl(String filename) => '$httpBase/uploads/image/$filename';
  static String deleteUrl(String id)      => '$httpBase/messages/$id';

  // ── WebSocket ───────────────────────────────────────────────────────
  static String wsUrl(String phone, String token) =>
      '$wsBase/ws/$phone?token=$token';

  // ── Hardcoded allowed users ─────────────────────────────────────────
  static const Map<String, String> users = {
    '9110687983': 'Prajwal',
    '7338532833': 'Ishwarya',
  };

  // ── UI ──────────────────────────────────────────────────────────────
  static const int historyPageSize = 50;
}
