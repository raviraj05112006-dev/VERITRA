import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path_provider/path_provider.dart';

import '../models/test_report.dart';
import 'cv_drug_test_service.dart';

/// Evidence handling: SHA-256 of the ORIGINAL captured image file, durable
/// copy of that image, PDF storage, and TestReport construction.
class EvidenceService {
  /// SHA-256 of the raw bytes of the file at [path] (streamed).
  Future<String> sha256OfFile(String path) async {
    final digest = await crypto.sha256.bind(File(path).openRead()).first;
    return digest.toString();
  }

  String sha256OfBytes(List<int> bytes) => crypto.sha256.convert(bytes).toString();

  Future<bool> verifyImage(String path, String expectedSha256) async {
    if (!await File(path).exists()) return false;
    return (await sha256OfFile(path)).toLowerCase() ==
        expectedSha256.toLowerCase();
  }

  Future<Directory> _subDir(String name) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}$name');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> evidenceDirectory() => _subDir('evidence');
  Future<Directory> reportsDirectory() => _subDir('reports');

  /// Copies the captured image (which may live in a temp/cache folder) into
  /// permanent app storage as an exact byte copy. Returns the new path.
  Future<String> preserveOriginal(String sourcePath, String reportId) async {
    final dir = await evidenceDirectory();
    final dot = sourcePath.lastIndexOf('.');
    final ext = (dot >= 0 && dot > sourcePath.lastIndexOf(Platform.pathSeparator))
        ? sourcePath.substring(dot)
        : '.jpg';
    final target = File('${dir.path}${Platform.pathSeparator}${reportId}_original$ext');
    await File(sourcePath).copy(target.path);
    return target.path;
  }

  /// Saves PDF bytes into <app documents>/reports/<fileName>.
  Future<File> savePdf(Uint8List bytes, String fileName) async {
    final dir = await reportsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    return file.writeAsBytes(bytes, flush: true);
  }

  String generateReportId([DateTime? now]) {
    final t = now ?? DateTime.now();
    String p(int v, [int w = 2]) => v.toString().padLeft(w, '0');
    return 'RPT-${t.year}${p(t.month)}${p(t.day)}-${p(t.hour)}${p(t.minute)}${p(t.second)}';
  }

  /// One call to turn a finished CV analysis into a TestReport.
  ///
  /// The hash is computed from the ORIGINAL captured file; the file is then
  /// copied byte-for-byte into permanent storage and the copy is re-hashed to
  /// prove it is identical. If the copy cannot be verified, the original path
  /// is kept instead.
  Future<TestReport> createReport({
    required CvDrugTestResult result,
    required String originalImagePath,
    String? testId,
    String? operatorId,
    String? testKit,
    String? suspectedSubstance,
    List<String>? reagents,
    double? latitude,
    double? longitude,
    double? gpsAccuracy,
    String? processedImagePath,
    DateTime? testDateTime,
  }) async {
    final reportId = generateReportId();

    String? hash;
    String storedPath = originalImagePath;

    if (await File(originalImagePath).exists()) {
      hash = await sha256OfFile(originalImagePath);

      try {
        final copied = await preserveOriginal(originalImagePath, reportId);
        if (await sha256OfFile(copied) == hash) {
          storedPath = copied;
        }
      } catch (_) {
        // Keep the original path if the copy fails.
      }
    }

    return TestReport.fromCvResult(
      result: result,
      reportId: reportId,
      dateTime: testDateTime,
      testId: testId,
      operatorId: operatorId,
      testKit: testKit,
      suspectedSubstance: suspectedSubstance,
      reagents: reagents,
      latitude: latitude,
      longitude: longitude,
      gpsAccuracy: gpsAccuracy,
      originalImagePath: storedPath,
      processedImagePath: processedImagePath,
      sha256: hash,
    );
  }
}