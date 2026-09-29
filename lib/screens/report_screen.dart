import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/test_report.dart';
import '../services/evidence_service.dart';
import '../services/pdf_report_service.dart';
import 'color_analysis_screen.dart';

/// Shown right after a completed field test. Receives a single [TestReport].
class ReportScreen extends StatefulWidget {
  final TestReport report;

  /// Called by "Finish". If null, pops back to the first route.
  final VoidCallback? onFinish;

  const ReportScreen({super.key, required this.report, this.onFinish});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const Color _navy = Color(0xFF0B2A4A);

  final EvidenceService _evidence = EvidenceService();
  final PdfReportService _pdf = PdfReportService();

  late TestReport _report;
  Uint8List? _pdfBytes;
  String? _pdfPath;
  bool _busy = false;
  bool _hashing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    _ensureHash();
  }

  /// If the report arrived without a hash, compute it from the ORIGINAL image
  /// file (never from a rendering).
  Future<void> _ensureHash() async {
    final path = _report.originalImagePath;
    if (_report.sha256 != null || path == null) return;
    if (!await File(path).exists()) return;

    setState(() => _hashing = true);
    try {
      final h = await _evidence.sha256OfFile(path);
      if (!mounted) return;
      setState(() => _report = _report.copyWith(sha256: h));
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not compute SHA-256: $e');
    } finally {
      if (mounted) setState(() => _hashing = false);
    }
  }

  Future<bool> _ensurePdf() async {
    if (_pdfBytes != null) return true;
    if (_busy) return false;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // Let the spinner paint before the (synchronous) image work starts.
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final bytes = await _pdf.build(_report);
      final file = await _evidence.savePdf(bytes, _report.pdfFileName);

      if (!mounted) return false;
      setState(() {
        _pdfBytes = bytes;
        _pdfPath = file.path;
      });
      return true;
    } catch (e) {
      if (mounted) setState(() => _error = 'PDF generation failed: $e');
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generate() async {
    // Force regeneration (e.g. after hash finished computing).
    setState(() => _pdfBytes = null);
    final ok = await _ensurePdf();
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved: ${_report.pdfFileName}')),
      );
    }
  }

  Future<void> _view() async {
    if (!await _ensurePdf() || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PdfViewPage(
          bytes: _pdfBytes!,
          fileName: _report.pdfFileName,
        ),
      ),
    );
  }

  Future<void> _share() async {
    if (!await _ensurePdf()) return;
    await Printing.sharePdf(
      bytes: _pdfBytes!,
      filename: _report.pdfFileName,
    );
  }

  void _finish() {
    if (widget.onFinish != null) {
      widget.onFinish!();
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Test Report'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(r),
          _section('TEST INFORMATION', [
            _kv('Test ID', r.testId ?? kNotRecorded),
            _kv('Test Kit', r.testKit ?? kNotRecorded),
            _kv('Suspected Substance', r.suspectedSubstance ?? kNotRecorded),
            _kv('Reagents', r.reagentsText),
            _kv('Test Date', r.dateText),
            _kv('Test Time', r.timeText),
            _kv('Operator ID', r.operatorId ?? kNotRecorded),
          ]),
          _section('LOCATION', [
            _kv('Latitude', r.latitudeText),
            _kv('Longitude', r.longitudeText),
            _kv('GPS Accuracy', r.gpsAccuracyText),
            _kv('Location status', r.locationStatus),
          ]),
          _section('RESULT', [_resultBox(r)]),
          _section('EVIDENCE', [
            const Text('Original captured image',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _image(r.originalImagePath, 'Original image not available'),
            const SizedBox(height: 12),
            const Text('Processed image',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (r.processedImagePath != null)
              _image(r.processedImagePath, 'Processed image not available')
            else
              Text(
                'No processed/annotated image is produced for this test.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
          ]),
          _section('EVIDENCE INTEGRITY', [
            const Text('IMAGE INTEGRITY',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('SHA-256 (original captured image file)',
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            if (_hashing)
              const LinearProgressIndicator()
            else
              SelectableText(
                r.sha256 ?? kNotRecorded,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Presumptive field-test result.\nLaboratory confirmation required.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (_pdfPath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Saved to: $_pdfPath',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            ),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ColorAnalysisScreen(report: _report),
              ),
            ),
            icon: const Icon(Icons.palette_outlined),
            label: const Text('Color Analysis'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy ? null : _generate,
            icon: _busy
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.picture_as_pdf),
            label: const Text('Generate PDF Report'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: (_busy || _pdfBytes == null) ? null : _view,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('View PDF'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: (_busy || _pdfBytes == null) ? null : _share,
            icon: const Icon(Icons.share_outlined),
            label: const Text('Save / Share PDF'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _finish,
            child: const Text('Finish / Back to Test Log'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI pieces
  // ---------------------------------------------------------------------------

  Widget _header(TestReport r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VERITRA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const Text(
            'Field Drug Test Report',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          const Text(
            'Powered by NarcoX',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text('Report ID: ${r.reportId}',
              style: const TextStyle(color: Colors.white)),
          Text('Test ID: ${r.testId ?? kNotRecorded}',
              style: const TextStyle(color: Colors.white)),
          Text('Generated: ${r.generatedText}',
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _resultBox(TestReport r) {
    final Color c = r.isPositive
        ? const Color(0xFFB45309)
        : r.isNegative
        ? const Color(0xFF166534)
        : const Color(0xFF475569);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withAlpha(20),
        border: Border.all(color: c, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.resultHeadline,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            r.resultValue,
            style: TextStyle(
                color: c, fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text('Confidence: ${r.confidenceText}'),
          Text('Status: ${r.status}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(r.message, style: TextStyle(color: Colors.grey.shade800)),
        ],
      ),
    );
  }

  Widget _image(String? path, String emptyText) {
    if (path == null || !File(path).existsSync()) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(emptyText),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.file(
        File(path),
        height: 240,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          height: 120,
          alignment: Alignment.center,
          color: Colors.grey.shade200,
          child: Text(emptyText),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(k, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Expanded(
            child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
                color: _navy,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _PdfViewPage extends StatelessWidget {
  final Uint8List bytes;
  final String fileName;

  const _PdfViewPage({required this.bytes, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName, style: const TextStyle(fontSize: 14)),
        backgroundColor: const Color(0xFF0B2A4A),
        foregroundColor: Colors.white,
      ),
      body: PdfPreview(
        build: (format) async => bytes,
        pdfFileName: fileName,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
      ),
    );
  }
}