import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'package:unblockr/providers/settings_provider.dart';
import 'package:unblockr/screens/auth/login_screen.dart';
import 'package:unblockr/screens/profile/my_vehicles_screen.dart';
import 'package:unblockr/screens/profile/profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FF),
      appBar: AppBar(
        title: Text(
          "Settings",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E2A38),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFEAF3FF),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// 👤 PROFILE CARD
          _sectionCard(
            child: ListTile(
              leading: const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFEAF3FF),
                child: Icon(Icons.person),
              ),
              title: Text(
                "Your Profile",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                "View and edit profile",
                style: GoogleFonts.inter(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
          ),

          const SizedBox(height: 16),

          /// 🚗 MY VEHICLES
          _sectionCard(
            child: ListTile(
              leading: const Icon(Icons.directions_car),
              title: Text(
                "My Vehicles",
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyVehiclesScreen(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          /// 🔔 NOTIFICATIONS
          _sectionCard(
            child: Column(
              children: [
                _switchTile(
                  icon: Icons.volume_up,
                  title: "Notification Sound",
                  value: settings.soundEnabled,
                  onChanged: settings.toggleSound,
                ),
                const Divider(height: 1),
                _switchTile(
                  icon: Icons.vibration,
                  title: "Vibration",
                  value: settings.vibrationEnabled,
                  onChanged: settings.toggleVibration,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// ⚙️ APP PREFERENCES
          _sectionCard(
            child: _switchTile(
              icon: Icons.dark_mode,
              title: "Dark Mode",
              value: settings.darkMode,
              onChanged: settings.toggleDarkMode,
            ),
          ),

          const SizedBox(height: 16),

          /// 🆘 ABOUT
          _sectionCard(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(
                "About Unblockr",
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                "Version 1.0.0",
                style: GoogleFonts.inter(fontSize: 12),
              ),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: "Unblockr",
                  applicationVersion: "1.0.0",
                  applicationLegalese:
                  "AI-powered parking alerts for smarter cities.",
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          /// 🚪 LOGOUT
          _sectionCard(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                "Log Out",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              onTap: () => _confirmLogout(context),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Log Out", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text(
          "Are you sure you want to log out?",
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Log Out",
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Firebase sign-out FIRST — this is what actually clears the session.
    // Google sign-out is fire-and-forget: in google_sign_in v7 calling
    // signOut() without initialize() can hang, which would block Firebase
    // sign-out and leave the user stuck.
    await FirebaseAuth.instance.signOut();
    GoogleSignIn.instance.signOut().catchError((_) {});

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  /// 🔹 CARD WRAPPER
  Widget _sectionCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
      child: child,
    );
  }

  /// 🔹 SWITCH TILE
  Widget _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon),
      title: Text(
        title,
        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
      ),
      activeColor: const Color(0xFF5AA9E6),
    );
  }
}