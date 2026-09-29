import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../models/test_report.dart';
import '../services/cv_drug_test_service.dart';
import 'report_screen.dart';

class CameraScreen extends StatefulWidget {
  final String? testId;
  final String? operatorId;
  final String? testKit;
  final String? suspectedSubstance;
  final List<String>? reagents;

  final double? latitude;
  final double? longitude;
  final double? gpsAccuracy;

  final DateTime? testDateTime;

  const CameraScreen({
    super.key,
    this.testId,
    this.operatorId,
    this.testKit,
    this.suspectedSubstance,
    this.reagents,
    this.latitude,
    this.longitude,
    this.gpsAccuracy,
    this.testDateTime,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;

  final CvDrugTestService _cvService = CvDrugTestService();

  bool _cameraReady = false;
  bool _analyzing = false;

  XFile? _photo;
  CvDrugTestResult? _result;

  String? _reportId;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('No camera available.');
      }

      CameraDescription selectedCamera = cameras.first;

      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        }
      }

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        _cameraReady = true;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera error: $e'),
        ),
      );
    }
  }

  Future<void> _capture() async {
    if (!_cameraReady ||
        _controller == null ||
        _analyzing) {
      return;
    }

    try {
      setState(() {
        _analyzing = true;
      });

      final photo = await _controller!.takePicture();

      final bytes = await File(photo.path).readAsBytes();

      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        throw Exception(
          'Could not decode captured image.',
        );
      }

      if (!mounted) return;

      setState(() {
        _photo = photo;
        _result = null;
        _reportId = null;
      });

      await _controller!.pausePreview();

      /*
       * CAMERA
       *   ↓
       * CV SERVICE
       *   ↓
       * ARUCO CARD DETECTION
       *   ↓
       * PERSPECTIVE CORRECTION
       *   ↓
       * COLOUR / LAB ANALYSIS
       *   ↓
       * RESULT
       */

      final result = await _cvService.analyzeImage(
        photo.path,
      );

      if (!mounted) return;

      setState(() {
        _result = result;
        _analyzing = false;

        _reportId =
        'RPT-${DateTime.now().millisecondsSinceEpoch}';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _analyzing = false;

        _result = CvDrugTestResult(
          status: 'INCONCLUSIVE',
          message: 'Camera/CV processing failed: $e',
          suspectedDrug: null,
          labL: 0,
          labA: 0,
          labB: 0,
          distance: 999,
          confidence: 0,
          qualityPassed: false,
          cardDetected: false,
        );
      });
    }
  }

  Future<void> _retake() async {
    setState(() {
      _photo = null;
      _result = null;
      _analyzing = false;
      _reportId = null;
    });

    try {
      await _controller?.resumePreview();
    } catch (_) {}
  }

  Future<void> _continueToReport() async {
    /*
     * The button must never work before:
     *
     * 1. A photo exists
     * 2. CV analysis has finished
     * 3. We have a CV result
     */
    if (_photo == null ||
        _result == null ||
        _analyzing) {
      return;
    }

    final reportId =
        _reportId ??
            'RPT-${DateTime.now().millisecondsSinceEpoch}';

    final report = TestReport.fromCvResult(
      result: _result!,
      reportId: reportId,
      generatedAt: DateTime.now(),
      dateTime: widget.testDateTime ?? DateTime.now(),

      testId: widget.testId,
      operatorId: widget.operatorId,
      testKit: widget.testKit,
      suspectedSubstance: widget.suspectedSubstance,
      reagents: widget.reagents,

      latitude: widget.latitude,
      longitude: widget.longitude,
      gpsAccuracy: widget.gpsAccuracy,

      originalImagePath: _photo!.path,
    );

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportScreen(
          report: report,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'NarcoX • Guided Capture',
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: !_cameraReady
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _photo == null
          ? _cameraView()
          : _resultView(),
    );
  }

  Widget _cameraView() {
    return Stack(
      children: [
        Positioned.fill(
          child: CameraPreview(
            _controller!,
          ),
        ),

        Positioned(
          top: 25,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Text(
                  'PLACE REFERENCE CARD IN FRAME',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Keep all 4 corner markers visible',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),

        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.78,
            height: MediaQuery.of(context).size.height * 0.58,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        Positioned(
          bottom: 35,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _capture,
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    width: 5,
                    color: Colors.blue,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.black,
                  size: 34,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultView() {
    return Column(
      children: [
        Expanded(
          child: Image.file(
            File(_photo!.path),
            fit: BoxFit.contain,
          ),
        ),

        _resultPanel(),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            8,
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed:
                  (!_analyzing && _result != null)
                      ? _continueToReport
                      : null,
                  icon: const Icon(
                    Icons.description_outlined,
                  ),
                  label: const Text(
                    'CONTINUE TO REPORT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF123B5D),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    Colors.grey.shade400,
                    disabledForegroundColor:
                    Colors.white70,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 45,
                child: OutlinedButton.icon(
                  onPressed:
                  _analyzing ? null : _retake,
                  icon: const Icon(
                    Icons.camera_alt,
                  ),
                  label: const Text(
                    'RETAKE PHOTO',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: Colors.white70,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resultPanel() {
    if (_analyzing) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'ANALYZING IMAGE...',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Detecting reference card and analysing colour',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final result = _result;

    if (result == null) {
      return const SizedBox();
    }

    final Color statusColor;

    switch (result.status) {
      case 'POSITIVE':
        statusColor = Colors.green;
        break;

      case 'NEGATIVE':
        statusColor = Colors.red;
        break;

      default:
        statusColor = Colors.orange;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'NARCOX CV ANALYSIS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius:
                  BorderRadius.circular(8),
                ),
                child: Text(
                  result.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              if (result.cardDetected)
                const Text(
                  'CARD DETECTED',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                )
              else
                const Text(
                  'CARD NOT DETECTED',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          if (result.suspectedDrug != null)
            Text(
              result.suspectedDrug!,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

          const SizedBox(height: 5),

          Text(
            result.message,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _metric(
                  'CONFIDENCE',
                  '${result.confidence}%',
                ),
              ),
              Expanded(
                child: _metric(
                  'LAB Δ',
                  result.distance.toStringAsFixed(2),
                ),
              ),
              Expanded(
                child: _metric(
                  'QUALITY',
                  result.qualityPassed
                      ? 'PASS'
                      : 'FAIL',
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'LAB: '
                'L ${result.labL.toStringAsFixed(1)}   '
                'a ${result.labA.toStringAsFixed(1)}   '
                'b ${result.labB.toStringAsFixed(1)}',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Presumptive field result — laboratory confirmation required.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(
      String title,
      String value,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}