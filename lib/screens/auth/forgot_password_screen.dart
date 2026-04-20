import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final TextEditingController emailController =
  TextEditingController();

  bool isLoading = false;
  bool emailSent = false;

  Future<void> _sendResetEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showMessage("Please enter your email");
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: email);

      setState(() => emailSent = true);

      _showMessage("Password reset link sent to your email");
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Error occurred");
    } catch (e) {
      _showMessage("Something went wrong");
    }

    setState(() => isLoading = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 30),

                /// 🔹 LOGO
                Image.asset(
                  "assets/logo/unblockr_logo.png",
                  width: 90,
                ),

                const SizedBox(height: 40),

                /// 🔹 TITLE
                Text(
                  emailSent
                      ? "Check your email"
                      : "Forgot Password",
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E2A38),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  emailSent
                      ? "We’ve sent a password reset link.\nPlease check your inbox."
                      : "Enter your email to receive a reset link",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 30),

                /// 🔹 EMAIL FIELD
                if (!emailSent)
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      hint: "Email",
                      icon: Icons.email_outlined,
                    ),
                  ),

                const SizedBox(height: 30),

                /// 🔹 BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: emailSent
                        ? () => Navigator.pop(context)
                        : (isLoading ? null : _sendResetEmail),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5AA9E6),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : Text(
                      emailSent
                          ? "Back to Login"
                          : "Send Reset Link",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// 🔹 BACK BUTTON
                if (emailSent)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Back to Login",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF5AA9E6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}