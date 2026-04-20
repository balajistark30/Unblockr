import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'package:unblockr/models/vehicle_model.dart';
import 'package:unblockr/providers/vehicle_provider.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final vehicles = context.watch<VehicleProvider>().vehicles;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FF),
      appBar: AppBar(
        title: Text(
          "My Vehicles",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E2A38),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFEAF3FF),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF5AA9E6),
        foregroundColor: Colors.white,
        onPressed: () => _openAddVehicleSheet(),
        icon: const Icon(Icons.add),
        label: Text(
          "Add Vehicle",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: vehicles.isEmpty ? _emptyState() : _vehicleList(vehicles),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 84,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No Vehicles Added",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E2A38),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add your vehicle to get started",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vehicleList(List<Vehicle> vehicles) {
    return ListView.builder(
      itemCount: vehicles.length,
      itemBuilder: (context, index) =>
          _vehicleCard(vehicles[index], index),
    );
  }

  Widget _vehicleCard(Vehicle vehicle, int index) {
    final imageFile = vehicle.image != null
        ? File(vehicle.image!)
        : null;

    final imageExists =
        imageFile != null && imageFile.existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: imageExists
                ? Image.file(
              imageFile!,
              height: 72,
              width: 72,
              fit: BoxFit.cover,
            )
                : Container(
              height: 72,
              width: 72,
              color: const Color(0xFFEAF3FF),
              alignment: Alignment.center,
              child: const Icon(Icons.directions_car, size: 30),
            ),
          ),
          const SizedBox(width: 16),

          /// TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: const Color(0xFF1E2A38),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  vehicle.model,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vehicle.number,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: const Color(0xFF1E2A38),
                    ),
                  ),
                ),
              ],
            ),
          ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == "edit") {
                _openAddVehicleSheet(editIndex: index);
              } else {
                _confirmDelete(index);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: "edit", child: Text("Edit")),
              PopupMenuItem(value: "delete", child: Text("Delete")),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int index) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Delete Vehicle",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          "Are you sure you want to delete this vehicle?",
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () {
              context.read<VehicleProvider>().deleteVehicle(index);
              Navigator.pop(context);
            },
            child: Text(
              "Delete",
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 FIXED IMAGE PICKER (PERMANENT STORAGE)
  Future<void> _pickVehicleImage(
      BuildContext modalContext,
      void Function(String path) onPicked,
      ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: modalContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text("Take Photo"),
                onTap: () =>
                    Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text("Choose from Gallery"),
                onTap: () =>
                    Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (picked == null) return;

    /// 🔥 COPY TO PERMANENT STORAGE
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
    DateTime.now().millisecondsSinceEpoch.toString();

    final savedImage = await File(picked.path).copy(
      '${dir.path}/$fileName.jpg',
    );

    onPicked(savedImage.path);
  }

  void _openAddVehicleSheet({int? editIndex}) {
    final provider = context.read<VehicleProvider>();
    final vehicles = provider.vehicles;

    final existing =
    editIndex != null ? vehicles[editIndex] : null;

    final nameController =
    TextEditingController(text: existing?.name ?? "");
    final modelController =
    TextEditingController(text: existing?.model ?? "");
    final numberController =
    TextEditingController(text: existing?.number ?? "");

    String? imagePath = existing?.image;

    bool nameError = false;
    bool modelError = false;
    bool numberError = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom:
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: () async {
                        await _pickVehicleImage(context, (path) {
                          setModalState(() => imagePath = path);
                        });
                      },
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor:
                        const Color(0xFFEAF3FF),
                        backgroundImage: imagePath != null
                            ? FileImage(File(imagePath!))
                            : null,
                        child: imagePath == null
                            ? const Icon(Icons.camera_alt)
                            : null,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _inputField(
                      controller: nameController,
                      hint: "Vehicle Name",
                      errorText:
                      nameError ? "Required" : null,
                    ),
                    const SizedBox(height: 12),

                    _inputField(
                      controller: modelController,
                      hint: "Model",
                      errorText:
                      modelError ? "Required" : null,
                    ),
                    const SizedBox(height: 12),

                    _inputField(
                      controller: numberController,
                      hint: "Vehicle Number",
                      errorText:
                      numberError ? "Required" : null,
                      capitalize: true,
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        setModalState(() {
                          nameError =
                              nameController.text.isEmpty;
                          modelError =
                              modelController.text.isEmpty;
                          numberError =
                              numberController.text.isEmpty;
                        });

                        if (nameError ||
                            modelError ||
                            numberError) return;

                        final vehicle = Vehicle(
                          name: nameController.text.trim(),
                          model: modelController.text.trim(),
                          number: numberController.text.trim().toUpperCase(),
                          image: imagePath,
                        );

                        if (editIndex != null) {
                          provider.updateVehicle(
                              editIndex, vehicle);
                        } else {
                          provider.addVehicle(vehicle);
                        }

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              editIndex != null
                                  ? 'Vehicle updated'
                                  : 'Vehicle added',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Text("Save"),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    String? errorText,
    bool capitalize = false,
  }) {
    return TextField(
      controller: controller,
      textCapitalization:
          capitalize ? TextCapitalization.characters : TextCapitalization.none,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        filled: true,
        fillColor: const Color(0xFFF7F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}