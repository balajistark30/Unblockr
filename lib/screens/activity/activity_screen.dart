import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unblockr/models/report_model.dart';
import 'package:unblockr/repositories/report_repository.dart';
import 'package:unblockr/widgets/report_card.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _repo = ReportRepository();

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

      body: StreamBuilder<List<ReportModel>>(
        stream: _repo.myReports(),
        builder: (context, mySnap) {
          final myReports = mySnap.data ?? [];

          final pending =
              myReports.where((r) => r.status != ReportStatus.resolved).length;
          final resolved =
              myReports.where((r) => r.status == ReportStatus.resolved).length;

          return Padding(
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
                        count: "$pending",
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        icon: Icons.check_circle,
                        title: "Resolved",
                        count: "$resolved",
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

                        TabBar(
                          labelStyle: GoogleFonts.inter(
                              fontWeight: FontWeight.w600),
                          unselectedLabelStyle: GoogleFonts.inter(),
                          tabs: const [
                            Tab(text: "My Reports"),
                            Tab(text: "Reports About Me"),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Expanded(
                          child: TabBarView(
                            children: [
                              // ── MY REPORTS ──────────────────────────────
                              _buildList(mySnap),

                              // ── REPORTS ABOUT ME ────────────────────────
                              StreamBuilder<List<ReportModel>>(
                                stream: _repo.reportsAboutMe(),
                                builder: (context, aboutSnap) =>
                                    _buildList(aboutSnap),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(AsyncSnapshot<List<ReportModel>> snap) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snap.hasError) {
      return Center(
        child: Text(
          "Something went wrong",
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }

    final reports = snap.data ?? [];

    if (reports.isEmpty) {
      return Center(
        child: Text(
          "No reports yet",
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (_, i) => ReportCard(report: reports[i]),
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text("$count cases"),
        ],
      ),
    );
  }
}
