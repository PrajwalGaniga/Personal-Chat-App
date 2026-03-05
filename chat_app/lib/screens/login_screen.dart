// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final provider = context.read<ChatProvider>();
    await provider.login(_phoneController.text.trim());

    if (mounted && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 72),

                  // ── Logo / Icon ─────────────────────────────────────
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF25D366),
                          const Color(0xFF128C7E),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF25D366).withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  ).animate().scale(
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),

                  const SizedBox(height: 32),

                  // ── Title ────────────────────────────────────────────
                  Text(
                    'Welcome 💚',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(
                        begin: 0.3,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      ),

                  const SizedBox(height: 10),

                  Text(
                    'Prajwal & Ishwarya\nPrivate Chat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white54,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 350.ms, duration: 500.ms),

                  const SizedBox(height: 56),

                  // ── Phone field ──────────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Your phone number',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 10,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: Color(0xFF25D366),
                      ),
                      hintText: '10-digit number',
                    ),
                    validator: (val) {
                      if (val == null || val.length != 10) {
                        return 'Enter a valid 10-digit number';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _login(),
                  ).animate().fadeIn(delay: 450.ms, duration: 500.ms),

                  const SizedBox(height: 32),

                  // ── Login button ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF25D366),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _login,
                            icon: const Icon(Icons.login_rounded),
                            label: const Text('Enter Chat'),
                          ),
                  ).animate().fadeIn(delay: 550.ms, duration: 500.ms).slideY(
                        begin: 0.4,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      ),

                  const SizedBox(height: 40),

                  // ── Hint ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2C34),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF25D366).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '🔐 Private access only',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _userRow('Prajwal', '9110687983'),
                        const SizedBox(height: 4),
                        _userRow('Ishwarya', '7338532833'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 650.ms, duration: 500.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _userRow(String name, String phone) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$name  ', style: const TextStyle(color: Colors.white60, fontSize: 13)),
        Text(phone,
            style: const TextStyle(
              color: Color(0xFF25D366),
              fontFamily: 'monospace',
              fontSize: 13,
            )),
      ],
    );
  }
}
