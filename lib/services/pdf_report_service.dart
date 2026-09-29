import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/test_report.dart';
import 'cv_drug_test_service.dart';

/// Builds the field-test report PDF from a [TestReport]. Uses only real data;
/// missing values are printed as "Not recorded".
class PdfReportService {
  static final PdfColor _navy = PdfColor.fromInt(0xFF0B2A4A);
  static final PdfColor _grey = PdfColor.fromInt(0xFF5F6B7A);
  static final PdfColor _line = PdfColor.fromInt(0xFFD0D7E2);
  static final PdfColor _panel = PdfColor.fromInt(0xFFF3F6FA);

  static const String disclaimer =
      'Presumptive field-test result. Laboratory confirmation required.';

  Future<Uint8List> build(TestReport r) async {
    final base = pw.Font.helvetica();
    final bold = pw.Font.helveticaBold();
    final mono = pw.Font.courier();

    final original = _loadImage(r.originalImagePath);
    final processed = _loadImage(r.processedImagePath);

    final doc = pw.Document(
      title: 'NarcoX Field Drug Test Report',
      author: 'NarcoX',
      creator: 'VERITRA / NarcoX',
    );

    pw.TextStyle st(double size,
        {bool isBold = false, PdfColor? color, pw.Font? font}) {
      return pw.TextStyle(
        font: font ?? (isBold ? bold : base),
        fontSize: size,
        color: color ?? PdfColors.black,
      );
    }

    pw.Widget sectionTitle(String title) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
        padding: const pw.EdgeInsets.only(bottom: 3),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _navy, width: 1.2)),
        ),
        child: pw.Text(title, style: st(11, isBold: true, color: _navy)),
      );
    }

    pw.Widget kv(String label, String value, {pw.Font? valueFont}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 130,
              child: pw.Text(label, style: st(9.5, color: _grey)),
            ),
            pw.Expanded(
              child: pw.Text(_t(value), style: st(9.5, font: valueFont)),
            ),
          ],
        ),
      );
    }

    pw.Widget imageBox(String caption, pw.MemoryImage? image, String emptyText) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(caption, style: st(9, color: _grey)),
          pw.SizedBox(height: 3),
          pw.Container(
            height: 210,
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: _panel,
              border: pw.Border.all(color: _line),
            ),
            child: image == null
                ? pw.Center(
              child: pw.Text(emptyText, style: st(9, color: _grey)),
            )
                : pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ],
      );
    }

    final resultColor = r.isPositive
        ? PdfColor.fromInt(0xFFB45309)
        : r.isNegative
        ? PdfColor.fromInt(0xFF166534)
        : PdfColor.fromInt(0xFF475569);

    pw.Widget resultBox() {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: _panel,
          border: pw.Border.all(color: resultColor, width: 1.5),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(r.resultHeadline, style: st(9.5, color: _grey)),
            pw.SizedBox(height: 2),
            pw.Text(_t(r.resultValue),
                style: st(20, isBold: true, color: resultColor)),
            pw.SizedBox(height: 6),
            pw.Text('Confidence: ${r.confidenceText}', style: st(10)),
            pw.Text('Status: ${r.status}', style: st(10, isBold: true)),
            pw.SizedBox(height: 4),
            pw.Text(_t(r.message), style: st(9, color: _grey)),
          ],
        ),
      );
    }

    pw.Widget swatch(String caption, List<int> rgb) {
      return pw.Row(
        children: [
          pw.Container(
            width: 36,
            height: 36,
            decoration: pw.BoxDecoration(
              color: PdfColor(rgb[0] / 255.0, rgb[1] / 255.0, rgb[2] / 255.0),
              border: pw.Border.all(color: _line),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(caption, style: st(9, color: _grey)),
        ],
      );
    }

    final List<pw.Widget> colourSection = [];
    if (r.hasColourData) {
      final measured = labToSrgb(r.labL!, r.labA!, r.labB!);
      final profile = r.referenceName == null
          ? null
          : CvDrugTestService.referenceProfiles[r.referenceName!];

      colourSection.addAll([
        kv('L*', r.labL!.toStringAsFixed(2)),
        kv('a*', r.labA!.toStringAsFixed(2)),
        kv('b*', r.labB!.toStringAsFixed(2)),
        kv('Reference', r.referenceName ?? kNotRecorded),
        kv('Distance', r.distance!.toStringAsFixed(2)),
        kv('Threshold', CvDrugTestService.matchThreshold.toStringAsFixed(1)),
        pw.SizedBox(height: 6),
        swatch('Measured colour (derived from CIELAB)', measured),
        if (profile != null) ...[
          pw.SizedBox(height: 4),
          swatch(
            'Reference profile colour',
            labToSrgb(profile[0], profile[1], profile[2]),
          ),
        ],
      ]);
    } else {
      colourSection.add(
        pw.Text(
          'No colour comparison was performed for this test. ${_t(r.message)}',
          style: st(9.5, color: _grey),
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 30, 36, 36),
        ),
        header: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _navy, width: 2)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('VERITRA', style: st(22, isBold: true, color: _navy)),
                  pw.Text('FIELD DRUG TEST REPORT',
                      style: st(11, isBold: true)),
                  pw.Text('Powered by NarcoX', style: st(8.5, color: _grey)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Report ID: ${r.reportId}', style: st(9)),
                  pw.Text('Test ID: ${r.testId ?? kNotRecorded}',
                      style: st(9)),
                  pw.Text('Generated: ${r.generatedText}', style: st(9)),
                ],
              ),
            ],
          ),
        ),
        footer: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _line)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(disclaimer, style: st(8, color: _grey)),
              pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}',
                  style: st(8, color: _grey)),
            ],
          ),
        ),
        build: (ctx) => [
          sectionTitle('TEST INFORMATION'),
          kv('Test ID', r.testId ?? kNotRecorded),
          kv('Test Kit', r.testKit ?? kNotRecorded),
          kv('Suspected Substance', r.suspectedSubstance ?? kNotRecorded),
          kv('Reagents', r.reagentsText),
          kv('Test Date', r.dateText),
          kv('Test Time', r.timeText),
          kv('Operator', r.operatorId ?? kNotRecorded),
          sectionTitle('LOCATION'),
          kv('Latitude', r.latitudeText),
          kv('Longitude', r.longitudeText),
          kv('GPS Accuracy', r.gpsAccuracyText),
          kv('Location Status', r.locationStatus),
          sectionTitle('RESULT'),
          resultBox(),
          sectionTitle('EVIDENCE'),
          imageBox('Original captured image', original,
              'Original image not available'),
          pw.SizedBox(height: 8),
          if (processed != null)
            imageBox('Processed image', processed, ''),
          if (processed == null)
            pw.Text(
              'No processed/annotated image was produced for this test.',
              style: st(9, color: _grey),
            ),
          sectionTitle('COLOUR ANALYSIS'),
          ...colourSection,
          sectionTitle('EVIDENCE INTEGRITY'),
          pw.Text('IMAGE INTEGRITY', style: st(9, isBold: true)),
          pw.SizedBox(height: 2),
          pw.Text('SHA-256 (of the original captured image file):',
              style: st(9, color: _grey)),
          pw.SizedBox(height: 2),
          pw.Text(
            r.sha256 ?? kNotRecorded,
            style: st(8.5, font: mono),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _panel,
              border: pw.Border.all(color: _line),
            ),
            child: pw.Text(
              'DISCLAIMER: $disclaimer This report does not confirm the '
                  'presence or identity of any substance.',
              style: st(9, isBold: true),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// Standard PDF fonts only cover Latin-1; replace anything else.
  String _t(String s) {
    return s
        .replaceAll('\u2014', '-')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2019', "'")
        .replaceAll(RegExp(r'[^\x00-\xFF]'), '?');
  }

  /// Decodes, orients and downsizes an image for embedding. The evidence hash
  /// is always computed from the original file, never from this copy.
  pw.MemoryImage? _loadImage(String? path, {int maxWidth = 1200}) {
    if (path == null) return null;

    final file = File(path);
    if (!file.existsSync()) return null;

    final decoded = img.decodeImage(file.readAsBytesSync());
    if (decoded == null) return null;

    var image = img.bakeOrientation(decoded);

    if (image.width > maxWidth) {
      image = img.copyResize(image, width: maxWidth);
    }

    return pw.MemoryImage(Uint8List.fromList(img.encodeJpg(image, quality: 85)));
  }
}