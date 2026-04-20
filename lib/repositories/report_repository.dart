import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/report_model.dart';
import '../services/location_service.dart';

// ── CLOUDINARY CONFIG ──────────────────────────────────────────────────────
// Sign up free at https://cloudinary.com  (no credit card needed)
// Dashboard → Cloud Name  |  Settings → Upload → unsigned preset
const _cloudName    = 'dooe8swie';        // ← your cloud name
const _uploadPreset = 'unblockr_reports'; // ← unsigned preset name

// ── BACKEND CONFIG ─────────────────────────────────────────────────────────
// Run  `ngrok http 8000`  on CUDA3 and paste the https URL below.
// Example: 'https://a1b2-34-56-78-90.ngrok-free.app'
const _backendUrl = 'http://172.22.168.13:8000'; // CUDA3 direct IP

class ReportRepository {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── UPLOAD IMAGES → Cloudinary ─────────────────────────────────────────────
  Future<({List<String> urls, List<String> publicIds})> uploadImages({
    required String reportId,
    required List<XFile> images,
    void Function(double progress)? onProgress,
  }) async {
    final urls      = <String>[];
    final publicIds = <String>[];

    final endpoint = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    for (int i = 0; i < images.length; i++) {
      final file = File(images[i].path);
      if (!file.existsSync()) {
        throw Exception('Image file not found: ${images[i].path}');
      }

      final request = http.MultipartRequest('POST', endpoint)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder']        = 'reports/$reportId'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send();
      final body     = await streamed.stream.bytesToString();

      if (streamed.statusCode != 200) {
        throw Exception('Cloudinary upload failed (${streamed.statusCode}): $body');
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      urls.add(json['secure_url'] as String);
      publicIds.add(json['public_id'] as String);

      onProgress?.call((i + 1) / images.length * 0.5); // first 50% = upload
    }

    return (urls: urls, publicIds: publicIds);
  }

  // ── CALL CUDA3 FASTAPI BACKEND ─────────────────────────────────────────────
  /// Sends images to your FastAPI /report/analyze endpoint.
  /// Returns a populated MlResult.
  Future<MlResult> analyzeWithBackend({
    required List<XFile> images,
    required String issueType,
    required String reporterVehicle,
    required List<String> enteredPlates,
  }) async {
    final uri     = Uri.parse('$_backendUrl/report/analyze');
    final request = http.MultipartRequest('POST', uri);

    // Attach every image as a separate "images" field
    for (final img in images) {
      request.files.add(
        await http.MultipartFile.fromPath('images', img.path),
      );
    }

    request.fields['issue_type']       = issueType;
    request.fields['selected_vehicle'] = reporterVehicle;
    request.fields['entered_plates']   = enteredPlates.join(',');

    try {
      // LLaVA inference can be slow on first call — allow up to 3 minutes
      final streamed = await request.send()
          .timeout(const Duration(minutes: 3));
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode != 200) {
        throw Exception('Backend analysis failed (${streamed.statusCode}): $body');
      }

      final json = jsonDecode(body) as Map<String, dynamic>;

      return MlResult(
        isBlocked:        json['is_blocked']   as bool,
        blockedVehicle:   (json['blocked_vehicle']  as String?) ?? '',
        blockingVehicles: List<String>.from(json['blocking_vehicles'] ?? []),
        confidence:       (json['confidence']  as num).toDouble(),
        rawResponse:      body,
        processedAt:      DateTime.now(),
      );
    } on SocketException {
      throw Exception(
        'Cannot reach backend at $_backendUrl. '
        'Make sure the FastAPI server and ngrok are running on CUDA3.',
      );
    } on HttpException {
      throw Exception(
        'HTTP error connecting to backend. Check that ngrok URL is correct.',
      );
    }
  }

  // ── SUBMIT REPORT (full flow) ──────────────────────────────────────────────
  /// 1. Upload images to Cloudinary
  /// 2. Get GPS location
  /// 3. Call CUDA3 backend for ML analysis
  /// 4. Write Firestore doc with status=confirmed + mlResult
  /// Returns reportId and the ML result so the caller can go straight
  /// to ResultScreen without waiting for a stream.
  Future<({String reportId, MlResult mlResult})> submitReport({
    required List<XFile>  images,
    required List<String> blockingPlates,
    required String       issueType,
    required String       reporterVehicle,
    required bool         shareLocation,
    String?               description,
    void Function(double progress)? onProgress,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    // 1. Reserve Firestore doc ID
    final docRef   = _db.collection('reports').doc();
    final reportId = docRef.id;

    // 2. Get location (non-blocking — null if it fails)
    GeoPoint? location;
    if (shareLocation) {
      try {
        location = await LocationService.getCurrentLocation();
      } catch (_) {}
    }

    // 3. Upload images to Cloudinary  (progress 0 → 50%)
    final (:urls, :publicIds) = await uploadImages(
      reportId:   reportId,
      images:     images,
      onProgress: onProgress,
    );

    // 4. Call CUDA3 backend  (progress 50 → 100%)
    onProgress?.call(0.5);
    final mlResult = await analyzeWithBackend(
      images:          images,
      issueType:       issueType,
      reporterVehicle: reporterVehicle,
      enteredPlates:   blockingPlates,
    );
    onProgress?.call(1.0);

    // 5. Write Firestore document — already confirmed, no Cloud Function needed
    final report = ReportModel(
      id:               reportId,
      reportedBy:       uid,
      reportedAt:       DateTime.now(),
      status:           ReportStatus.confirmed, // ← skip pending entirely
      locationShared:   shareLocation,
      location:         location,
      issueType:        issueType,
      description:      description,
      reporterVehicle:  reporterVehicle,
      blockedVehicle:   mlResult.blockedVehicle,
      blockingVehicles: blockingPlates,          // keep user-entered plates
      imageUrls:        urls,
      imagePaths:       publicIds,
      mlResult:         mlResult,
      readers:          [uid],
    );

    await docRef.set(report.toMap());
    return (reportId: reportId, mlResult: mlResult);
  }

  // ── NOTIFY OWNER ───────────────────────────────────────────────────────────
  Future<void> requestNotification({
    required String reportId,
    String?         customMessage,
  }) async {
    await _db.collection('reports').doc(reportId).update({
      'notification': {
        'customMessage': customMessage,
        'requestedAt':   FieldValue.serverTimestamp(),
      },
      'notificationRequested': true,
    });
  }

  // ── MARK RESOLVED ──────────────────────────────────────────────────────────
  Future<void> markResolved(String reportId) async {
    await _db.collection('reports').doc(reportId).update({
      'status':     'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── GET REPORT ONCE ────────────────────────────────────────────────────────
  Future<ReportModel?> getReport(String reportId) async {
    final snap = await _db.collection('reports').doc(reportId).get();
    return snap.exists ? ReportModel.fromDoc(snap) : null;
  }

  // ── DELETE REPORT ──────────────────────────────────────────────────────────
  /// Deletes the Firestore document.
  /// Cloudinary image cleanup is done server-side using stored public_ids.
  Future<void> deleteReport(String reportId) async {
    await _db.collection('reports').doc(reportId).delete();
  }

  // ── MY REPORTS ─────────────────────────────────────────────────────────────
  Stream<List<ReportModel>> myReports() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('reports')
        .where('reportedBy', isEqualTo: uid)
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ReportModel.fromDoc).toList());
  }

  // ── REPORTS ABOUT MY VEHICLE ───────────────────────────────────────────────
  Stream<List<ReportModel>> reportsAboutMe() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('reports')
        .where('readers', arrayContains: uid)
        .where('reportedBy', isNotEqualTo: uid)
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ReportModel.fromDoc).toList());
  }
}
