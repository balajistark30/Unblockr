import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Manages the `plates/{plate}` Firestore collection.
///
/// The Cloud Function uses this collection to resolve a plate number
/// to its ownerUid (and later FCM token) when sending blocking notifications.
class PlateRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── REGISTER ───────────────────────────────────────────────────────────────
  /// Writes/merges plates/{plate} with the current user's UID.
  /// Called whenever a vehicle is added.
  Future<void> registerPlate(String plate) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('plates').doc(plate.toUpperCase()).set({
      'ownerUid': uid,
      'registeredAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── UNREGISTER ─────────────────────────────────────────────────────────────
  /// Deletes plates/{plate} only if the current user is the registered owner.
  /// Called when a vehicle is deleted.
  Future<void> unregisterPlate(String plate) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = _db.collection('plates').doc(plate.toUpperCase());
    final snap = await ref.get();

    if (snap.exists && snap.data()?['ownerUid'] == uid) {
      await ref.delete();
    }
  }

  // ── LOOKUP ─────────────────────────────────────────────────────────────────
  /// Returns true if the plate is registered by any user in Firestore.
  Future<bool> isPlateRegistered(String plate) async {
    final snap = await _db.collection('plates').doc(plate.toUpperCase()).get();
    return snap.exists;
  }

  // ── REGISTER BATCH ─────────────────────────────────────────────────────────
  /// Registers multiple plates at once (e.g. on login / token refresh).
  Future<void> registerPlates(List<String> plates) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || plates.isEmpty) return;

    final batch = _db.batch();
    for (final plate in plates) {
      batch.set(
        _db.collection('plates').doc(plate.toUpperCase()),
        {
          'ownerUid': uid,
          'registeredAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }
}
