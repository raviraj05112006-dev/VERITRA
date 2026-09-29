import 'dart:io';

import 'package:flutter/material.dart';

import '../models/test_report.dart';
import '../services/cv_drug_test_service.dart';

/// Shows the real colour analysis produced by CvDrugTestService.
/// Nothing here is invented: values come from the TestReport, which copies
/// them from CvDrugTestResult.
class ColorAnalysisScreen extends StatelessWidget {
  final TestReport report;

  const ColorAnalysisScreen({super.key, required this.report});

  static const Color _navy = Color(0xFF0B2A4A);

  Color _swatchColor(double l, double a, double b) {
    final rgb = labToSrgb(l, a, b);
    return Color.fromARGB(255, rgb[0], rgb[1], rgb[2]);
  }

  String get _interpretation {
    if (!report.hasColourData) {
      return 'No colour comparison was performed. ${report.message}';
    }

    final d = report.distance!;
    final name = report.referenceName ?? 'the reference';
    final match = CvDrugTestService.matchThreshold;
    final inc = CvDrugTestService.inconclusiveThreshold;

    if (report.isPositive) {
      return 'Distance ${d.toStringAsFixed(2)} is within the match threshold '
          '(${match.toStringAsFixed(1)}). The reaction colour is consistent '
          'with the $name reference profile. Presumptive only; laboratory '
          'confirmation required.';
    }
    if (report.isInconclusive) {
      return 'Distance ${d.toStringAsFixed(2)} lies between the match '
          'threshold (${match.toStringAsFixed(1)}) and ${inc.toStringAsFixed(1)}. '
          'The colour is not close enough to the $name reference to report a '
          'presumptive result.';
    }
    return 'Distance ${d.toStringAsFixed(2)} exceeds ${inc.toStringAsFixed(1)}. '
        'No sufficiently close match with the reference colour profile.';
  }

  @override
  Widget build(BuildContext context) {
    final profile = report.referenceName == null
        ? null
        : CvDrugTestService.referenceProfiles[report.referenceName!];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Colour Analysis'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card('SAMPLE / REACTION IMAGE', [
            if (report.processedImagePath != null &&
                File(report.processedImagePath!).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(report.processedImagePath!),
                  height: 220,
                  fit: BoxFit.contain,
                ),
              )
            else
              Text(
                'The CV pipeline does not currently export a sample crop. '
                    'The swatch below is drawn from the measured CIELAB values.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
          ]),
          _card('CIELAB (MEASURED)', [
            if (report.hasColourData) ...[
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _swatchColor(
                          report.labL!, report.labA!, report.labB!),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black26),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _kv('L*', report.labL!.toStringAsFixed(2)),
                        _kv('a*', report.labA!.toStringAsFixed(2)),
                        _kv('b*', report.labB!.toStringAsFixed(2)),
                      ],
                    ),
                  ),
                ],
              ),
            ] else
              const Text('Not available: no sample colour was extracted.'),
          ]),
          _card('REFERENCE', [
            _kv('Matched reference', report.referenceName ?? kNotRecorded),
            if (profile != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _swatchColor(profile[0], profile[1], profile[2]),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.black26),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Profile L*=${profile[0].toStringAsFixed(0)}  '
                          'a*=${profile[1].toStringAsFixed(0)}  '
                          'b*=${profile[2].toStringAsFixed(0)}',
                    ),
                  ),
                ],
              ),
            ],
          ]),
          _card('DISTANCE', [
            _kv('Distance',
                report.distance == null ? kNotRecorded : report.distance!.toStringAsFixed(2)),
            _kv('Match threshold',
                CvDrugTestService.matchThreshold.toStringAsFixed(1)),
            _kv('Inconclusive limit',
                CvDrugTestService.inconclusiveThreshold.toStringAsFixed(1)),
            if (report.distance != null) ...[
              const SizedBox(height: 10),
              _distanceBar(report.distance!),
            ],
          ]),
          _card('INTERPRETATION', [
            Text(_interpretation),
            const SizedBox(height: 8),
            Text(
              'Presumptive field-test result. Laboratory confirmation required.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _distanceBar(double d) {
    final match = CvDrugTestService.matchThreshold;
    final inc = CvDrugTestService.inconclusiveThreshold;
    final maxScale = inc * 1.5;

    final frac = (d / maxScale).clamp(0.0, 1.0);
    final matchFrac = match / maxScale;
    final incFrac = inc / maxScale;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return SizedBox(
          height: 28,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 10,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 10,
                child: Container(
                  width: w * frac,
                  height: 8,
                  decoration: BoxDecoration(
                    color: d <= match
                        ? const Color(0xFFB45309)
                        : (d <= inc
                        ? const Color(0xFF475569)
                        : const Color(0xFF166534)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Positioned(
                left: w * matchFrac - 1,
                top: 4,
                child: Container(width: 2, height: 20, color: Colors.black87),
              ),
              Positioned(
                left: w * incFrac - 1,
                top: 4,
                child: Container(width: 2, height: 20, color: Colors.black45),
              ),
            ],
          ),
        );
      },
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

  Widget _card(String title, List<Widget> children) {
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