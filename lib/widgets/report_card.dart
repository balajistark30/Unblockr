import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unblockr/models/report_model.dart';
import 'package:unblockr/screens/activity/report_detail_screen.dart';

class ReportCard extends StatelessWidget {
  final ReportModel report;

  const ReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final isResolved = report.status == ReportStatus.resolved;
    final plates = report.blockingVehicles.isNotEmpty
        ? report.blockingVehicles.join('  ·  ')
        : (report.blockedVehicle.isNotEmpty ? report.blockedVehicle : '—');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportDetailScreen(report: report),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [

            /// IMAGE PREVIEW (network URL)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: report.imageUrls.isNotEmpty
                  ? Image.network(
                      report.imageUrls.first,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),

            const SizedBox(width: 14),

            /// DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// PLATE(S)
                  Text(
                    plates,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// STATUS
                  Row(
                    children: [
                      Icon(
                        isResolved
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        size: 16,
                        color: isResolved
                            ? const Color(0xFF34C759)
                            : const Color(0xFFFF9500),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isResolved ? "Resolved" : "Pending",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isResolved
                              ? const Color(0xFF34C759)
                              : const Color(0xFFFF9500),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  /// TIME
                  Text(
                    _formatTime(report.reportedAt),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0xFFF2F2F7),
      child: const Icon(Icons.image_outlined, color: Colors.grey),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return "$m ${m == 1 ? 'min' : 'mins'} ago";
    } else if (diff.inHours < 24) {
      final h = diff.inHours;
      return "$h ${h == 1 ? 'hr' : 'hrs'} ago";
    } else {
      final d = diff.inDays;
      return "$d ${d == 1 ? 'day' : 'days'} ago";
    }
  }
}
