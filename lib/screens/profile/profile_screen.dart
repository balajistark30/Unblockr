import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:unblockr/screens/settings/settings_screen.dart';

import '../auth/login_screen.dart';
import 'my_vehicles_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : 'User';
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FF),

      appBar: AppBar(
        title: Text(
          "Profile",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E2A38),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFEAF3FF),
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            const SizedBox(height: 20),

            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFF5AA9E6),
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),

            const SizedBox(height: 15),

            Text(
              displayName,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              email,
              style: GoogleFonts.inter(
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 30),

            ListTile(
              leading: const Icon(Icons.directions_car),
              title: const Text("My Vehicles"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyVehiclesScreen(),
                    ),
                  );
                },
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () async {
                // Firebase sign-out FIRST — clears the session immediately.
                // Google sign-out is fire-and-forget to avoid hangs.
                await FirebaseAuth.instance.signOut();
                GoogleSignIn.instance.signOut().catchError((_) {});

                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}