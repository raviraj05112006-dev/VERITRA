import 'dart:math' as math;

import '../services/cv_drug_test_service.dart';

const String kNotRecorded = 'Not recorded';

/// One completed field test. Every field that the app does not currently
/// capture is nullable; nothing is invented.
class TestReport {
  final String reportId;
  final DateTime generatedAt;

  final String? testId;
  final String? operatorId;
  final DateTime dateTime;
  final String? testKit;

  /// Substance the operator/kit selected (NOT the CV result).
  final String? suspectedSubstance;
  final List<String>? reagents;

  final double? latitude;
  final double? longitude;
  final double? gpsAccuracy;

  // ---- CV result (copied from CvDrugTestResult) ----
  final String status; // POSITIVE / NEGATIVE / INCONCLUSIVE
  final String message;

  /// Drug named by the CV result. Only set when status is POSITIVE.
  final String? detectedSubstance;

  /// Only set when a colour comparison was actually performed.
  final int? confidence;
  final double? distance;
  final double? labL;
  final double? labA;
  final double? labB;
  final String? referenceName;

  final bool qualityPassed;
  final bool cardDetected;

  // ---- Evidence ----
  final String? originalImagePath;
  final String? processedImagePath;
  final String? sha256;

  const TestReport({
    required this.reportId,
    required this.generatedAt,
    required this.dateTime,
    required this.status,
    required this.message,
    required this.qualityPassed,
    required this.cardDetected,
    this.testId,
    this.operatorId,
    this.testKit,
    this.suspectedSubstance,
    this.reagents,
    this.latitude,
    this.longitude,
    this.gpsAccuracy,
    this.detectedSubstance,
    this.confidence,
    this.distance,
    this.labL,
    this.labA,
    this.labB,
    this.referenceName,
    this.originalImagePath,
    this.processedImagePath,
    this.sha256,
  });

  /// Builds a report from the real CV result. The CV service uses
  /// distance == 999 (and zero Lab values) when a gate failed and no colour
  /// comparison happened; in that case no colour data is stored.
  factory TestReport.fromCvResult({
    required CvDrugTestResult result,
    required String reportId,
    DateTime? dateTime,
    DateTime? generatedAt,
    String? testId,
    String? operatorId,
    String? testKit,
    String? suspectedSubstance,
    List<String>? reagents,
    double? latitude,
    double? longitude,
    double? gpsAccuracy,
    String? originalImagePath,
    String? processedImagePath,
    String? sha256,
  }) {
    final hasColour =
        result.qualityPassed && result.cardDetected && result.distance < 999;

    return TestReport(
      reportId: reportId,
      generatedAt: generatedAt ?? DateTime.now(),
      dateTime: dateTime ?? DateTime.now(),
      testId: testId,
      operatorId: operatorId,
      testKit: testKit,
      suspectedSubstance: suspectedSubstance,
      reagents: reagents,
      latitude: latitude,
      longitude: longitude,
      gpsAccuracy: gpsAccuracy,
      status: result.status,
      message: result.message,
      detectedSubstance: result.isPositive ? result.suspectedDrug : null,
      confidence: hasColour ? result.confidence : null,
      distance: hasColour ? result.distance : null,
      labL: hasColour ? result.labL : null,
      labA: hasColour ? result.labA : null,
      labB: hasColour ? result.labB : null,
      referenceName: hasColour ? result.suspectedDrug : null,
      qualityPassed: result.qualityPassed,
      cardDetected: result.cardDetected,
      originalImagePath: originalImagePath,
      processedImagePath: processedImagePath,
      sha256: sha256,
    );
  }

  // ---------------------------------------------------------------------------
  // Derived state
  // ---------------------------------------------------------------------------

  bool get isPositive => status == 'POSITIVE';
  bool get isNegative => status == 'NEGATIVE';
  bool get isInconclusive => status == 'INCONCLUSIVE';

  bool get hasColourData =>
      distance != null && labL != null && labA != null && labB != null;

  bool get hasLocation => latitude != null && longitude != null;

  String get locationStatus =>
      hasLocation ? 'GPS position recorded' : 'Location not recorded';

  String get resultHeadline {
    if (isPositive) return 'PRESUMPTIVE RESULT';
    if (isNegative) return 'NO REFERENCE MATCH';
    return 'INCONCLUSIVE';
  }

  /// Big text under the headline. Never shows a drug unless POSITIVE.
  String get resultValue {
    if (isPositive && detectedSubstance != null) {
      return detectedSubstance!.toUpperCase();
    }
    if (isNegative) return 'NEGATIVE';
    return 'INCONCLUSIVE';
  }

  String get confidenceText =>
      confidence == null ? 'Not applicable' : '$confidence%';

  String get pdfFileName {
    final id = (testId != null && testId!.trim().isNotEmpty)
        ? testId!
        : reportId;
    final safe = id.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    return 'NarcoX_Report_$safe.pdf';
  }

  // ---------------------------------------------------------------------------
  // Formatting
  // ---------------------------------------------------------------------------

  static String _p2(int v) => v.toString().padLeft(2, '0');

  static String formatDate(DateTime t) =>
      '${t.year}-${_p2(t.month)}-${_p2(t.day)}';

  static String formatTime(DateTime t) =>
      '${_p2(t.hour)}:${_p2(t.minute)}:${_p2(t.second)}';

  String get dateText => formatDate(dateTime);
  String get timeText => formatTime(dateTime);
  String get generatedText =>
      '${formatDate(generatedAt)} ${formatTime(generatedAt)}';

  String get reagentsText => (reagents == null || reagents!.isEmpty)
      ? kNotRecorded
      : reagents!.join(', ');

  String get latitudeText =>
      latitude == null ? kNotRecorded : latitude!.toStringAsFixed(6);
  String get longitudeText =>
      longitude == null ? kNotRecorded : longitude!.toStringAsFixed(6);
  String get gpsAccuracyText => gpsAccuracy == null
      ? kNotRecorded
      : '${gpsAccuracy!.toStringAsFixed(1)} m';

  // ---------------------------------------------------------------------------
  // Copy / JSON (for Test Log persistence)
  // ---------------------------------------------------------------------------

  TestReport copyWith({
    String? originalImagePath,
    String? processedImagePath,
    String? sha256,
  }) {
    return TestReport(
      reportId: reportId,
      generatedAt: generatedAt,
      dateTime: dateTime,
      testId: testId,
      operatorId: operatorId,
      testKit: testKit,
      suspectedSubstance: suspectedSubstance,
      reagents: reagents,
      latitude: latitude,
      longitude: longitude,
      gpsAccuracy: gpsAccuracy,
      status: status,
      message: message,
      detectedSubstance: detectedSubstance,
      confidence: confidence,
      distance: distance,
      labL: labL,
      labA: labA,
      labB: labB,
      referenceName: referenceName,
      qualityPassed: qualityPassed,
      cardDetected: cardDetected,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      processedImagePath: processedImagePath ?? this.processedImagePath,
      sha256: sha256 ?? this.sha256,
    );
  }

  Map<String, dynamic> toJson() => {
    'reportId': reportId,
    'generatedAt': generatedAt.toIso8601String(),
    'testId': testId,
    'operatorId': operatorId,
    'dateTime': dateTime.toIso8601String(),
    'testKit': testKit,
    'suspectedSubstance': suspectedSubstance,
    'reagents': reagents,
    'latitude': latitude,
    'longitude': longitude,
    'gpsAccuracy': gpsAccuracy,
    'status': status,
    'message': message,
    'detectedSubstance': detectedSubstance,
    'confidence': confidence,
    'distance': distance,
    'labL': labL,
    'labA': labA,
    'labB': labB,
    'referenceName': referenceName,
    'qualityPassed': qualityPassed,
    'cardDetected': cardDetected,
    'originalImagePath': originalImagePath,
    'processedImagePath': processedImagePath,
    'sha256': sha256,
  };

  factory TestReport.fromJson(Map<String, dynamic> j) {
    return TestReport(
      reportId: j['reportId'] as String,
      generatedAt: DateTime.parse(j['generatedAt'] as String),
      dateTime: DateTime.parse(j['dateTime'] as String),
      testId: j['testId'] as String?,
      operatorId: j['operatorId'] as String?,
      testKit: j['testKit'] as String?,
      suspectedSubstance: j['suspectedSubstance'] as String?,
      reagents: (j['reagents'] as List?)?.map((e) => e.toString()).toList(),
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      gpsAccuracy: (j['gpsAccuracy'] as num?)?.toDouble(),
      status: j['status'] as String,
      message: j['message'] as String,
      detectedSubstance: j['detectedSubstance'] as String?,
      confidence: (j['confidence'] as num?)?.toInt(),
      distance: (j['distance'] as num?)?.toDouble(),
      labL: (j['labL'] as num?)?.toDouble(),
      labA: (j['labA'] as num?)?.toDouble(),
      labB: (j['labB'] as num?)?.toDouble(),
      referenceName: j['referenceName'] as String?,
      qualityPassed: j['qualityPassed'] as bool? ?? false,
      cardDetected: j['cardDetected'] as bool? ?? false,
      originalImagePath: j['originalImagePath'] as String?,
      processedImagePath: j['processedImagePath'] as String?,
      sha256: j['sha256'] as String?,
    );
  }
}

/// Converts CIELAB (D65, L 0..100, a/b centred on 0) to sRGB 0..255.
/// Used only to draw a swatch of the measured/reference colour.
List<int> labToSrgb(double l, double a, double b) {
  final fy = (l + 16.0) / 116.0;
  final fx = fy + a / 500.0;
  final fz = fy - b / 200.0;

  double finv(double t) {
    final t3 = t * t * t;
    return t3 > 0.008856 ? t3 : (t - 16.0 / 116.0) / 7.787;
  }

  final x = 0.95047 * finv(fx);
  final y = 1.0 * finv(fy);
  final z = 1.08883 * finv(fz);

  final rl = 3.2406 * x - 1.5372 * y - 0.4986 * z;
  final gl = -0.9689 * x + 1.8758 * y + 0.0415 * z;
  final bl = 0.0557 * x - 0.2040 * y + 1.0570 * z;

  int gamma(double c) {
    final v = c <= 0.0031308
        ? 12.92 * c
        : 1.055 * math.pow(c < 0 ? 0.0 : c, 1.0 / 2.4).toDouble() - 0.055;
    final clamped = v < 0.0 ? 0.0 : (v > 1.0 ? 1.0 : v);
    return (clamped * 255.0).round();
  }

  return [gamma(rl), gamma(gl), gamma(bl)];
}