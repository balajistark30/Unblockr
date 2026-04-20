import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:unblockr/providers/vehicle_provider.dart';
import 'package:unblockr/screens/home/main_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _pollTimer;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    // Poll every 4 seconds so the user doesn't have to tap manually
    _pollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _checkVerified(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerified() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
    } catch (_) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) {
      _pollTimer?.cancel();
      if (!mounted) return;

      context.read<VehicleProvider>().syncAllPlates().catchError((_) {});

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _resending = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification email sent")),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to resend. Please try again.")),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: Color(0xFF5AA9E6),
              ),
              const SizedBox(height: 20),
              Text(
                "Verify your email",
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E2A38),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "We sent a verification link to\n${FirebaseAuth.instance.currentUser?.email ?? 'your email'}.\nOpen it to continue.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "This page will advance automatically once verified.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _checkVerified,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5AA9E6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "I have verified",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _resending ? null : _resendEmail,
                child: Text(
                  _resending ? "Sending…" : "Resend email",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF5AA9E6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
