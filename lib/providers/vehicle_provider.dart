import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:unblockr/models/vehicle_model.dart';
import 'package:unblockr/repositories/plate_repository.dart';

class VehicleProvider extends ChangeNotifier {
  final Box _box = Hive.box('vehicles');
  final _plateRepo = PlateRepository();

  List<Vehicle> get vehicles {
    return _box.values
        .map((e) => Vehicle.fromMap(Map<dynamic, dynamic>.from(e)))
        .toList();
  }

  /// Adds a vehicle locally (Hive) and registers its plate in Firestore.
  Future<void> addVehicle(Vehicle vehicle) async {
    _box.add(vehicle.toMap());
    notifyListeners();
    await _plateRepo.registerPlate(vehicle.number);
  }

  /// Updates a vehicle locally and re-registers the plate if the number changed.
  Future<void> updateVehicle(int index, Vehicle vehicle) async {
    final old = vehicles[index];
    _box.putAt(index, vehicle.toMap());
    notifyListeners();

    if (old.number.toUpperCase() != vehicle.number.toUpperCase()) {
      await _plateRepo.unregisterPlate(old.number);
    }
    await _plateRepo.registerPlate(vehicle.number);
  }

  /// Deletes a vehicle locally and removes its plate from Firestore.
  Future<void> deleteVehicle(int index) async {
    final plate = vehicles[index].number;
    _box.deleteAt(index);
    notifyListeners();
    await _plateRepo.unregisterPlate(plate);
  }

  /// Re-registers all current vehicles in Firestore (e.g. after sign-in).
  Future<void> syncAllPlates() async {
    final plates = vehicles.map((v) => v.number).toList();
    await _plateRepo.registerPlates(plates);
  }
}
