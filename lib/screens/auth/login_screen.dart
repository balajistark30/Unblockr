import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:unblockr/providers/vehicle_provider.dart';
import 'package:unblockr/screens/auth/forgot_password_screen.dart';
import 'package:unblockr/screens/auth/signup_screen.dart';
import 'package:unblockr/screens/auth/verify_email_screen.dart';
import 'package:unblockr/screens/home/main_screen.dart';
import 'package:unblockr/widgets/social_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (!mounted) return;

      if (user != null && !user.emailVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
        );
        return;
      }

      context.read<VehicleProvider>().syncAllPlates().catchError((_) {});

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint("EMAIL LOGIN ERROR CODE: ${e.code}");
      debugPrint("EMAIL LOGIN ERROR MESSAGE: ${e.message}");
      _showError(_friendlyFirebaseError(e));
    } catch (e, st) {
      debugPrint("EMAIL LOGIN UNKNOWN ERROR: $e");
      debugPrintStack(stackTrace: st);
      _showError("Something went wrong. Please try again.");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => isLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize();

      final GoogleSignInAccount googleUser =
      await googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          "Google sign-in succeeded but no ID token was returned.",
        );
      }

      final OAuthCredential credential =
      GoogleAuthProvider.credential(idToken: idToken);

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      context.read<VehicleProvider>().syncAllPlates().catchError((_) {});

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } on GoogleSignInException catch (e, st) {
      debugPrint("GOOGLE SIGN-IN EXCEPTION CODE: ${e.code}");
      debugPrint("GOOGLE SIGN-IN EXCEPTION DESCRIPTION: ${e.description}");
      debugPrintStack(stackTrace: st);

      if (e.code.name.toLowerCase().contains("canceled")) {
        _showError("Google sign-in was cancelled.");
      } else {
        _showError(
          "Google sign-in failed: ${e.description ?? e.code.name}",
        );
      }
    } on FirebaseAuthException catch (e, st) {
      debugPrint("FIREBASE GOOGLE AUTH ERROR CODE: ${e.code}");
      debugPrint("FIREBASE GOOGLE AUTH ERROR MESSAGE: ${e.message}");
      debugPrintStack(stackTrace: st);

      _showError(_friendlyGoogleFirebaseError(e));
    } catch (e, st) {
      debugPrint("GOOGLE LOGIN UNKNOWN ERROR: $e");
      debugPrintStack(stackTrace: st);

      _showError(
        "Google login failed. Check Firebase Google Sign-In setup and try again.",
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _friendlyFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return "Please enter a valid email address.";
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return "Incorrect email or password.";
      case 'too-many-requests':
        return "Too many attempts. Please try again later.";
      case 'network-request-failed':
        return "Network error. Check your internet connection.";
      default:
        return e.message ?? "Login failed.";
    }
  }

  String _friendlyGoogleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return "This email is already linked to another sign-in method.";
      case 'invalid-credential':
        return "Google credential was invalid. Recheck Firebase setup.";
      case 'operation-not-allowed':
        return "Google Sign-In is not enabled in Firebase Authentication.";
      case 'network-request-failed':
        return "Network error. Check your internet connection.";
      default:
        return e.message ??
            "Google login failed. Please verify Google Sign-In setup.";
    }
  }

  void _showError(String message) {
    if (!mounted) return;
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

                Image.asset("assets/logo/unblockr_logo.png", width: 110),

                const SizedBox(height: 20),

                Text(
                  "Welcome back",
                  style: GoogleFonts.inter(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E2A38),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Login to continue",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 40),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    hint: "Email",
                    icon: Icons.email_outlined,
                  ),
                ),

                const SizedBox(height: 16),

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

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Forgot Password?",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF5AA9E6),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5AA9E6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      "Login",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[400])),
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "or continue with",
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[400])),
                  ],
                ),

                const SizedBox(height: 20),

                SocialButton(
                  logo: "assets/logo/google.png",
                  text: "Continue with Google",
                  onTap: () {
                    if (!isLoading) {
                      _handleGoogleLogin();
                    }
                  },
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "New here?",
                      style: GoogleFonts.inter(
                        color: Colors.grey[700],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignupScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Create an account",
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