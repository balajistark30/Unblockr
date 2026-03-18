import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FF),

      appBar: AppBar(
        title: Text(
          "Activity",
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
        padding: const EdgeInsets.symmetric(horizontal: 20),

        child: Column(
          children: [

            const SizedBox(height: 10),

            /// Summary cards
            Row(
              children: [

                Expanded(
                  child: _summaryCard(
                    icon: Icons.warning_amber_rounded,
                    title: "Pending",
                    count: "0",
                    color: Colors.orange,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _summaryCard(
                    icon: Icons.check_circle,
                    title: "Resolved",
                    count: "0",
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// Tabs
            Expanded(
              child: DefaultTabController(
                length: 2,

                child: Column(
                  children: [

                    const TabBar(
                      tabs: [
                        Tab(text: "My Reports"),
                        Tab(text: "Reports About Me"),
                      ],
                    ),

                    const SizedBox(height: 10),

                    const Expanded(
                      child: TabBarView(
                        children: [
                          Center(child: Text("No reports yet")),
                          Center(child: Text("No reports about you")),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),

      child: Column(
        children: [

          Icon(icon, color: color, size: 28),

          const SizedBox(height: 8),

          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 4),

          Text("$count cases"),
        ],
      ),
    );
  }
}