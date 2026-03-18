import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FF),

      appBar: AppBar(
        title: Text(
          "Report",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E2A38),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFEAF3FF),
        elevation: 0,
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: Color(0xFF5AA9E6),
            ),

            const SizedBox(height: 20),

            Text(
              "Report a blocked car",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Take a photo of the blocking vehicle to notify the owner.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () {
                // TODO open camera
              },

              icon: const Icon(Icons.camera_alt),

              label: const Text("Scan Vehicle"),

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5AA9E6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}