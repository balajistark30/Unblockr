import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/report_result.dart';
import '../../repositories/plate_repository.dart';
import '../../repositories/report_repository.dart';

class ResultScreen extends StatefulWidget {
  final String reportId;
  final ReportResult result;
  final List<XFile> images;

  // Report context passed from ReportScreen
  final List<String> blockingPlates;
  final String issueType;
  final String? description;
  final String? userVehicleNumber;
  final bool locationShared;

  const ResultScreen({
    super.key,
    required this.reportId,
    required this.result,
    required this.images,
    required this.blockingPlates,
    required this.issueType,
    required this.locationShared,
    this.description,
    this.userVehicleNumber,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  final TextEditingController messageController = TextEditingController();
  final _repo = ReportRepository();
  final _plateRepo = PlateRepository();
  late AnimationController _bannerController;
  late Animation<double> _bannerFade;
  late Animation<Offset> _bannerSlide;
  bool _notificationSent = false;
  bool _isPlateRegistered = false;
  bool _plateCheckDone = false;
  int _selectedImageIndex = 0;

  static const int maxChars = 200;
  static const double threshold = 0.75;

  @override
  void initState() {
    super.initState();
    messageController.addListener(() => setState(() {}));
    _checkPlateRegistration();

    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bannerFade = CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeOut,
    );
    _bannerSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeOutCubic,
    ));

    _bannerController.forward();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    messageController.dispose();
    super.dispose();
  }

  bool get isHighConfidence => widget.result.confidence >= threshold;

  String get _formattedTime {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final mo = now.month.toString().padLeft(2, '0');
    return '$d/$mo/${now.year} at $h:$m';
  }

  String get _issueLabel {
    switch (widget.issueType) {
      case 'Blocking':
        return 'Blocking Vehicle';
      case 'Double Parked':
        return 'Double Parking';
      case 'Illegal Parking':
        return 'Illegal Parking';
      case 'No Parking Zone':
        return 'No Parking Zone Violation';
      case 'Other':
        return 'Other Violation';
      default:
        return widget.issueType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBlocking = widget.result.isBlocking;
    final confidence = widget.result.confidence;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: Text(
          'Report Result',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: const Color(0xFF0D1B2A),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF0D1B2A)),
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ),
      bottomNavigationBar: _buildCTA(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          // ── VERDICT BANNER ──────────────────────────────────────────
          FadeTransition(
            opacity: _bannerFade,
            child: SlideTransition(
              position: _bannerSlide,
              child: _verdictBanner(isBlocking, confidence),
            ),
          ),

          const SizedBox(height: 16),

          // ── PHOTOS ──────────────────────────────────────────────────
          if (widget.images.isNotEmpty) ...[
            _sectionHeader('Evidence Photos'),
            const SizedBox(height: 8),
            _photoGallery(),
            const SizedBox(height: 16),
          ],

          // ── NOTIFICATION PAYLOAD ─────────────────────────────────────
          _sectionHeader('Notification Preview'),
          const SizedBox(height: 8),
          _card(child: _notificationPayload()),

          const SizedBox(height: 16),

          // ── REPORT SUMMARY ───────────────────────────────────────────
          _sectionHeader('Report Summary'),
          const SizedBox(height: 8),
          _card(child: _reportSummary()),

          const SizedBox(height: 16),

          // ── OPTIONAL MESSAGE ─────────────────────────────────────────
          _sectionHeader('Personal Message'),
          const SizedBox(height: 8),
          _card(child: _messageBox()),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'This message will be included in the notification sent to the vehicle owner.',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: const Color(0xFF8A9BB0),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── VERDICT BANNER ───────────────────────────────────────────────────────
  Widget _verdictBanner(bool isBlocking, double confidence) {
    final color =
    isBlocking ? const Color(0xFFFF3B30) : const Color(0xFF34C759);
    final bgColor =
    isBlocking ? const Color(0xFFFFF1F0) : const Color(0xFFF0FBF3);
    final borderColor =
    isBlocking ? const Color(0xFFFFCDCA) : const Color(0xFFB6EFC4);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isBlocking
                  ? Icons.warning_rounded
                  : Icons.check_circle_rounded,
              size: 36,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isBlocking ? 'Blocking Confirmed' : 'No Blockage Detected',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isBlocking
                ? 'AI analysis confirmed a vehicle is blocking your access'
                : 'AI analysis did not detect a blocking vehicle',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF5A6B7E),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Confidence bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AI Confidence',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5A6B7E),
                    ),
                  ),
                  Text(
                    '${(confidence * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: confidence,
                  minHeight: 8,
                  backgroundColor: Colors.white,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── PHOTO GALLERY ────────────────────────────────────────────────────────
  Widget _photoGallery() {
    return Column(
      children: [
        // Large preview
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.file(
              File(widget.images[_selectedImageIndex].path),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (widget.images.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              itemBuilder: (_, i) {
                final selected = i == _selectedImageIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF5AA9E6)
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(widget.images[i].path),
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // ── NOTIFICATION PAYLOAD ─────────────────────────────────────────────────
  Widget _notificationPayload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _payloadRow(
          icon: Icons.directions_car_rounded,
          label: widget.blockingPlates.length > 1
              ? 'Blocking Plates'
              : 'Blocking Plate',
          value: widget.blockingPlates.join('  ·  '),
          valueColor: const Color(0xFFFF3B30),
          isBold: true,
        ),
        _divider(),
        _payloadRow(
          icon: Icons.warning_amber_rounded,
          label: 'Violation Type',
          value: _issueLabel,
        ),
        _divider(),
        _payloadRow(
          icon: Icons.photo_library_outlined,
          label: 'Evidence Photos',
          value: '${widget.images.length} photo${widget.images.length != 1 ? 's' : ''} attached',
        ),
        _divider(),
        _payloadRow(
          icon: Icons.location_on_rounded,
          label: 'Location',
          value: widget.locationShared
              ? 'GPS coordinates included'
              : 'Not shared',
          valueColor: widget.locationShared
              ? const Color(0xFF34C759)
              : const Color(0xFF8A9BB0),
        ),
        _divider(),
        _payloadRow(
          icon: Icons.access_time_rounded,
          label: 'Reported At',
          value: _formattedTime,
        ),
        if (widget.userVehicleNumber != null) ...[
          _divider(),
          _payloadRow(
            icon: Icons.person_outline_rounded,
            label: 'Your Vehicle',
            value: widget.userVehicleNumber!,
          ),
        ],
        if (widget.description != null && widget.description!.isNotEmpty) ...[
          _divider(),
          _payloadRow(
            icon: Icons.notes_rounded,
            label: 'Additional Notes',
            value: widget.description!,
          ),
        ],
      ],
    );
  }

  Widget _payloadRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: const Color(0xFF5A6B7E)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8A9BB0),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight:
                    isBold ? FontWeight.w700 : FontWeight.w500,
                    color: valueColor ?? const Color(0xFF0D1B2A),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    color: const Color(0xFFF2F4F8),
    thickness: 1,
  );

  // ── REPORT SUMMARY ───────────────────────────────────────────────────────
  Widget _reportSummary() {
    final confidence = widget.result.confidence;
    final isHigh = confidence >= threshold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isHigh
                    ? const Color(0xFFF0FBF3)
                    : const Color(0xFFFFF8EC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isHigh
                        ? Icons.verified_rounded
                        : Icons.info_outline_rounded,
                    size: 13,
                    color: isHigh
                        ? const Color(0xFF34C759)
                        : const Color(0xFFFF9F0A),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isHigh ? 'High Confidence' : 'Low Confidence',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isHigh
                          ? const Color(0xFF34C759)
                          : const Color(0xFFFF9F0A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          isHigh
              ? 'The AI has identified a likely violation with high confidence. You can proceed to notify the vehicle owner.'
              : 'The AI is not fully confident in this result. Consider capturing additional photos for a more accurate analysis before notifying the owner.',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: const Color(0xFF5A6B7E),
            height: 1.6,
          ),
        ),
        if (!isHigh) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt_outlined,
                      size: 15, color: Color(0xFF5AA9E6)),
                  const SizedBox(width: 6),
                  Text(
                    'Retake Photos',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5AA9E6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── MESSAGE BOX ──────────────────────────────────────────────────────────
  Widget _messageBox() {
    final length = messageController.text.length;
    final nearLimit = length > maxChars * 0.8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: messageController,
          maxLength: maxChars,
          maxLines: 4,
          minLines: 3,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: const Color(0xFF0D1B2A),
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText: 'Write a polite message to the vehicle owner… (optional)',
            hintStyle: GoogleFonts.dmSans(
              fontSize: 14,
              color: const Color(0xFFB0BEC5),
            ),
            border: InputBorder.none,
            counterText: '',
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Keep it respectful and factual',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: const Color(0xFF8A9BB0),
              ),
            ),
            Text(
              '$length / $maxChars',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: nearLimit
                    ? const Color(0xFFFF9F0A)
                    : const Color(0xFF8A9BB0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── CTA BUTTON ───────────────────────────────────────────────────────────
  Widget _buildCTA() {
    if (!isHighConfidence) return const SizedBox.shrink();

    // Still checking Firestore
    if (!_plateCheckDone) {
      return Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).padding.bottom + 12),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Plate not registered in Unblockr
    if (!_isPlateRegistered) {
      return Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFFFE0A3), width: 1.5),
              ),
              child: Column(
                children: [
                  const Icon(Icons.person_off_rounded,
                      color: Color(0xFFFF9F0A), size: 32),
                  const SizedBox(height: 10),
                  Text(
                    'Vehicle Not Registered',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: const Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This vehicle is not registered on Unblockr, so we cannot notify the owner.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: const Color(0xFF5A6B7E),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D1B2A),
                  side: const BorderSide(color: Color(0xFFD0D5DD)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Go Back Home',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_notificationSent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FBF3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFB6EFC4), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF34C759), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Notification Sent',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: const Color(0xFF34C759),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _sendNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D1B2A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.send_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Notify Vehicle Owner',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            _notificationSent
                ? 'The owner has been notified with all report details'
                : 'A notification will be sent with all report details above',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: const Color(0xFF8A9BB0),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────
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

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF8A9BB0),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Future<void> _checkPlateRegistration() async {
    // Check if any of the blocking plates are registered in the app
    for (final plate in widget.blockingPlates) {
      if (await _plateRepo.isPlateRegistered(plate)) {
        if (mounted) setState(() { _isPlateRegistered = true; _plateCheckDone = true; });
        return;
      }
    }
    if (mounted) setState(() => _plateCheckDone = true);
  }

  Future<void> _sendNotification() async {
    HapticFeedback.mediumImpact();

    try {
      final message = messageController.text.trim();
      await _repo.requestNotification(
        reportId: widget.reportId,
        customMessage: message.isEmpty ? null : message,
      );

      if (!mounted) return;
      setState(() => _notificationSent = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Owner notified successfully',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send notification. Please try again.',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}