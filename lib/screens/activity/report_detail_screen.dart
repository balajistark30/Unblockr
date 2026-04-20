import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unblockr/models/report_model.dart';
import 'package:unblockr/repositories/report_repository.dart';

class ReportDetailScreen extends StatefulWidget {
  final ReportModel report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final _repo = ReportRepository();
  bool _resolving = false;

  bool get _isResolved => widget.report.status == ReportStatus.resolved;

  Future<void> _markResolved() async {
    setState(() => _resolving = true);
    try {
      await _repo.markResolved(widget.report.id);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _resolving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark as resolved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final plates = report.blockingVehicles.isNotEmpty
        ? report.blockingVehicles
        : (report.blockedVehicle.isNotEmpty ? [report.blockedVehicle] : []);
    final confidence = report.mlResult?.confidence ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: Text(
          "Report Details",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      bottomNavigationBar: !_isResolved
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _resolving ? null : _markResolved,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34C759),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _resolving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Mark as Resolved",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            )
          : null,

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          children: [

            /// STATUS BANNER
            _statusBanner(_isResolved),

            const SizedBox(height: 16),

            /// PLATES + CONFIDENCE
            _card(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_car_outlined),
                      const SizedBox(width: 8),
                      Text(
                        plates.isNotEmpty ? plates.join('  ·  ') : '—',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (report.mlResult != null)
                    Text(
                      "${(confidence * 100).toStringAsFixed(0)}%",
                      style: GoogleFonts.inter(color: Colors.grey[600]),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// ISSUE TYPE
            _card(
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined),
                  const SizedBox(width: 8),
                  Text(
                    report.issueType,
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// IMAGES (network URLs from Storage)
            if (report.imageUrls.isNotEmpty)
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("Photos"),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: report.imageUrls.length,
                        itemBuilder: (_, i) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                report.imageUrls[i],
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 110,
                                  height: 110,
                                  color: const Color(0xFFF2F2F7),
                                  child: const Icon(Icons.broken_image_outlined,
                                      color: Colors.grey),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            if (report.imageUrls.isNotEmpty) const SizedBox(height: 16),

            /// CUSTOM MESSAGE (if notification was sent)
            if (report.notification?.customMessage != null &&
                report.notification!.customMessage!.isNotEmpty)
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("Message sent"),
                    const SizedBox(height: 8),
                    Text(
                      report.notification!.customMessage!,
                      style: GoogleFonts.inter(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),

            if (report.notification?.customMessage != null &&
                report.notification!.customMessage!.isNotEmpty)
              const SizedBox(height: 16),

            /// LOCATION
            _card(
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined),
                  const SizedBox(width: 8),
                  Text(
                    report.locationShared
                        ? "Location shared with owner"
                        : "Location not shared",
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// TIMESTAMP
            _card(
              child: Row(
                children: [
                  const Icon(Icons.access_time),
                  const SizedBox(width: 8),
                  Text(
                    _formatFullTime(report.reportedAt),
                    style: GoogleFonts.inter(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBanner(bool isResolved) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isResolved
            ? const Color(0xFFE6F7EC)
            : const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            isResolved
                ? Icons.check_circle_rounded
                : Icons.warning_amber_rounded,
            size: 50,
            color: isResolved
                ? const Color(0xFF34C759)
                : const Color(0xFFFF9500),
          ),
          const SizedBox(height: 10),
          Text(
            isResolved ? "Resolved" : "Pending Action",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.grey[700],
      ),
    );
  }

  String _formatFullTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return "${time.day}/${time.month}/${time.year} • $h:$m";
  }
}
