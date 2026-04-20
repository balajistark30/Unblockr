import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:unblockr/providers/vehicle_provider.dart';
import 'package:unblockr/models/vehicle_model.dart';
import 'package:unblockr/models/report_result.dart';
import 'package:unblockr/repositories/report_repository.dart';
import 'package:unblockr/screens/profile/my_vehicles_screen.dart';
import 'package:unblockr/screens/report/processing_screen.dart';
import 'package:unblockr/screens/report/result_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ImagePicker _picker = ImagePicker();
  final _repo = ReportRepository();

  List<XFile> images = [];
  String issueType = "Blocking";
  Vehicle? selectedVehicle;
  bool shareLocation = false;

  final List<TextEditingController> plateControllers = [
    TextEditingController(),
  ];
  final TextEditingController descriptionController = TextEditingController();

  final List<String> issueTypes = [
    "Blocking",
    "Double Parked",
    "Illegal Parking",
    "No Parking Zone",
    "Other",
  ];

  @override
  void dispose() {
    for (final c in plateControllers) {
      c.dispose();
    }
    descriptionController.dispose();
    super.dispose();
  }

  // ── IMAGE PICKER ─────────────────────────────────────────────────────────

  Future<void> _showImageSourcePicker() async {
    if (images.length >= 6) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text("Take Photo"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text("Choose from Gallery"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() => images.add(picked));
    }
  }

  void _removeImage(int index) {
    setState(() => images.removeAt(index));
  }

  // ── SUBMIT ───────────────────────────────────────────────────────────────

  Future<void> _submitReport() async {
    final plates = plateControllers
        .map((e) => e.text.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toList();

    if (plates.isEmpty) {
      _snack("Enter plate number");
      return;
    }

    if (images.isEmpty) {
      _snack("Add at least one image");
      return;
    }

    if (!shareLocation) {
      _snack("Please agree to share your location");
      return;
    }

    // Navigate to processing screen while we work in the background
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(
          onTimeout: () {},
        ),
      ),
    );

    try {
      // 1. Upload images, run ML analysis, create Firestore document
      final (:reportId, :mlResult) = await _repo.submitReport(
        images: images,
        blockingPlates: plates,
        issueType: issueType,
        reporterVehicle: selectedVehicle?.number ?? '',
        shareLocation: shareLocation,
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
      );

      if (!mounted) return;

      // 2. Go straight to result — doc is already confirmed, no stream needed
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            reportId: reportId,
            result: ReportResult(
              isBlocking: mlResult.isBlocked,
              confidence: mlResult.confidence,
              plate: mlResult.blockingVehicles.isNotEmpty
                  ? mlResult.blockingVehicles.first
                  : '',
            ),
            images: images,
            blockingPlates: mlResult.blockingVehicles.isNotEmpty
                ? mlResult.blockingVehicles.map((p) => p.toUpperCase()).toList()
                : plates,
            issueType: issueType,
            locationShared: shareLocation,
            description: descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
            userVehicleNumber: selectedVehicle?.number,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _snack("Submission failed: ${e.toString()}");
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vehicles = context.watch<VehicleProvider>().vehicles;
    // Set default or reset if the current selection no longer exists in the list
    if (vehicles.isEmpty) {
      selectedVehicle = null;
    } else if (selectedVehicle == null ||
        !vehicles.any((v) => v.number == selectedVehicle!.number)) {
      selectedVehicle = vehicles.first;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      /// 🔥 STICKY BUTTON
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _submitReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5AA9E6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              "Report Now",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),

      appBar: AppBar(
        title: Text(
          "Report Issue",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E2A38),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🚘 VEHICLE
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title("Your Vehicle"),
                  const SizedBox(height: 8),
                  vehicles.isEmpty
                      ? _noVehicleState()
                      : _vehicleDropdown(vehicles),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// 🚗 BLOCKING PLATE
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title("Blocking Vehicle *"),
                  const SizedBox(height: 10),
                  Column(
                    children: List.generate(
                      plateControllers.length,
                          (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: plateControllers[i],
                                textCapitalization:
                                TextCapitalization.characters,
                                decoration:
                                _inputDecoration("Enter plate number"),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (plateControllers.length > 1)
                              GestureDetector(
                                onTap: () {
                                  // Capture first, remove from list, then
                                  // dispose after Flutter detaches it
                                  final toDispose = plateControllers[i];
                                  setState(() => plateControllers.removeAt(i));
                                  WidgetsBinding.instance
                                      .addPostFrameCallback(
                                          (_) => toDispose.dispose());
                                },
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        plateControllers.add(TextEditingController());
                      });
                    },
                    child: const Text("+ Add another"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// 📸 PHOTOS
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title("Photos"),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: images.isEmpty ? _uploadBox() : _imageGrid(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// ⚠️ ISSUE TYPE
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title("Issue Type"),
                  const SizedBox(height: 8),
                  _dropdown(
                    value: issueType,
                    items: issueTypes,
                    onChanged: (val) => setState(() => issueType = val!),
                  ),
                ],
              ),
            ),

            if (issueType == "Other") ...[
              const SizedBox(height: 16),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title("Describe Issue"),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: _inputDecoration("Explain the issue"),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            /// 📍 SHARE LOCATION
            _card(
              child: Row(
                children: [
                  Checkbox(
                    value: shareLocation,
                    activeColor: const Color(0xFF5AA9E6),
                    onChanged: (val) =>
                        setState(() => shareLocation = val ?? false),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Share my location *",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "Required to submit this report",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF5AA9E6),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── REUSABLE WIDGETS ─────────────────────────────────────────────────────

  /// 🔹 CARD
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _title(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }

  /// 🔹 UPLOAD BOX
  Widget _uploadBox() {
    return GestureDetector(
      onTap: _showImageSourcePicker,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(18),
        dashPattern: const [6, 3],
        color: const Color(0xFF5AA9E6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.add_a_photo_outlined,
                size: 40,
                color: Color(0xFF5AA9E6),
              ),
              const SizedBox(height: 10),
              Text(
                "Add scene photos",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 IMAGE GRID
  Widget _imageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length < 6 ? images.length + 1 : images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        if (index == images.length && images.length < 6) {
          return GestureDetector(
            onTap: _showImageSourcePicker,
            child: DottedBorder(
              borderType: BorderType.RRect,
              radius: const Radius.circular(14),
              dashPattern: const [6, 3],
              color: Colors.grey,
              child: const Center(
                child: Icon(Icons.add, color: Color(0xFF5AA9E6)),
              ),
            ),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(images[index].path),
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 🔹 INPUT
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  /// 🔹 DROPDOWN
  Widget _dropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _vehicleDropdown(List<Vehicle> vehicles) {
    return _dropdown(
      value: selectedVehicle!.number,
      items: vehicles.map((v) => v.number).toList(),
      onChanged: (val) {
        setState(() {
          selectedVehicle = vehicles.firstWhere((v) => v.number == val);
        });
      },
    );
  }

  Widget _noVehicleState() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("No vehicles found"),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const MyVehiclesScreen()),
          ),
          child: const Text("Add Vehicle"),
        ),
      ],
    );
  }
}