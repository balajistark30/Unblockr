import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {

  int step = 0;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final List<TextEditingController> otpControllers =
  List.generate(6, (_) => TextEditingController());

  final List<FocusNode> otpFocusNodes =
  List.generate(6, (_) => FocusNode());

  bool obscurePassword = true;

  void nextStep() {
    setState(() {
      step++;
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    for (var controller in otpControllers) {
      controller.dispose();
    }

    for (var node in otpFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  /// EMAIL STEP
  Widget emailStep() {
    return Column(
      children: [

        Text(
          "Forgot Password",
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E2A38),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          "Enter the email associated with your account",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 30),

        TextField(
          controller: emailController,
          decoration: InputDecoration(
            hintText: "Email",
            prefixIcon: const Icon(Icons.email_outlined),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              // TODO: send reset code API
              nextStep();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5AA9E6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              "Send Code",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// OTP STEP
  Widget otpStep() {
    return Column(
      children: [

        Text(
          "Enter Code",
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E2A38),
          ),
        ),

        const SizedBox(height: 10),

        Text(
          "We sent a 6 digit code to your email",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.grey[600],
          ),
        ),

        const SizedBox(height: 30),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            6,
                (index) => SizedBox(
              width: 45,
              child: TextField(
                controller: otpControllers[index],
                focusNode: otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,

                onChanged: (value) {

                  if (value.isNotEmpty && index < 5) {
                    FocusScope.of(context)
                        .requestFocus(otpFocusNodes[index + 1]);
                  }

                  if (value.isEmpty && index > 0) {
                    FocusScope.of(context)
                        .requestFocus(otpFocusNodes[index - 1]);
                  }

                },

                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              // TODO: verify OTP API
              nextStep();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5AA9E6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              "Verify",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// RESET PASSWORD STEP
  Widget resetPasswordStep() {
    return Column(
      children: [

        Text(
          "Reset Password",
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E2A38),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          "Enter your new password",
          style: GoogleFonts.inter(
            color: Colors.grey[600],
          ),
        ),

        const SizedBox(height: 30),

        TextField(
          controller: passwordController,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            hintText: "New Password",
            prefixIcon: const Icon(Icons.lock_outline),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 16),

        TextField(
          controller: confirmPasswordController,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            hintText: "Confirm Password",
            prefixIcon: const Icon(Icons.lock_outline),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {

              if (passwordController.text != confirmPasswordController.text) {

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Passwords do not match"),
                  ),
                );

                return;
              }

              // TODO: reset password API

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5AA9E6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              "Update Password",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    Widget body;

    if (step == 0) {
      body = emailStep();
    } else if (step == 1) {
      body = otpStep();
    } else {
      body = resetPasswordStep();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FF),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),

            child: Column(
              children: [

                const SizedBox(height: 30),

                Image.asset(
                  "assets/logo/unblockr_logo.png",
                  width: 90,
                ),

                const SizedBox(height: 40),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: body,
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