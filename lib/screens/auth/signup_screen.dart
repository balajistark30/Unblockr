import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:unblockr/providers/vehicle_provider.dart';
import 'package:unblockr/screens/home/main_screen.dart';
import 'package:unblockr/widgets/social_button.dart';
import 'package:unblockr/screens/auth/verify_email_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  /// 🔥 SIGNUP FUNCTION (WITH EMAIL VERIFICATION)
  Future<void> _handleSignup() async {
    final email = emailController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (email.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    setState(() => isLoading = true);

    try {
      /// 🔥 CREATE USER
      final credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      /// 🔥 SAVE DISPLAY NAME
      await credential.user!.updateDisplayName(username);

      /// 🔥 SEND EMAIL VERIFICATION
      await credential.user!.sendEmailVerification();

      if (!mounted) return;
      /// 👉 Navigate to verification screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const VerifyEmailScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      _showError(_friendlyError(e));
    } catch (e) {
      _showError("Something went wrong");
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _handleGoogleSignup() async {
    setState(() => isLoading = true);

    try {
      await GoogleSignIn.instance.initialize();
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;

      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception("No ID token returned from Google.");
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      context.read<VehicleProvider>().syncAllPlates().catchError((_) {});

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    } on GoogleSignInException catch (e) {
      if (e.code.name.toLowerCase().contains("canceled")) {
        _showError("Google sign-in was cancelled.");
      } else {
        _showError("Google sign-in failed: ${e.description ?? e.code.name}");
      }
    } on FirebaseAuthException catch (e) {
      _showError(_friendlyError(e));
    } catch (_) {
      _showError("Google sign-up failed. Please try again.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return "An account already exists with this email.";
      case 'invalid-email':
        return "Please enter a valid email address.";
      case 'weak-password':
        return "Password must be at least 6 characters.";
      case 'network-request-failed':
        return "Network error. Check your internet connection.";
      default:
        return e.message ?? "Signup failed.";
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
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
                const SizedBox(height: 40),

                /// 🔹 LOGO
                Image.asset("assets/logo/unblockr_logo.png", width: 100),

                const SizedBox(height: 20),

                /// 🔹 TITLE
                Text(
                  "Create account",
                  style: GoogleFonts.inter(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E2A38),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Join Unblockr and solve parking faster",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                /// 🔹 EMAIL
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    hint: "Email",
                    icon: Icons.email_outlined,
                  ),
                ),

                const SizedBox(height: 16),

                /// 🔹 USERNAME
                TextField(
                  controller: usernameController,
                  decoration: _inputDecoration(
                    hint: "Username",
                    icon: Icons.person_outline,
                  ),
                ),

                const SizedBox(height: 16),

                /// 🔹 PASSWORD
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: _inputDecoration(
                    hint: "Password",
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// 🔹 CONFIRM PASSWORD
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: _inputDecoration(
                    hint: "Confirm Password",
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword =
                          !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// 🔹 SIGNUP BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5AA9E6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : Text(
                      "Sign Up",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// 🔹 DIVIDER
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[400])),
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "or sign up with",
                        style:
                        GoogleFonts.inter(color: Colors.grey[600]),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[400])),
                  ],
                ),

                const SizedBox(height: 20),

                /// 🔹 GOOGLE SIGNUP
                SocialButton(
                  logo: "assets/logo/google.png",
                  text: "Continue with Google",
                  onTap: isLoading ? () {} : _handleGoogleSignup,
                ),

                const SizedBox(height: 30),

                /// 🔹 LOGIN REDIRECT
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style:
                      GoogleFonts.inter(color: Colors.grey[700]),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Login",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF5AA9E6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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