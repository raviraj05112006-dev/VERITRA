import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../services/cv_drug_test_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
  });

  @override
  State<CameraScreen> createState() =>
      _CameraScreenState();
}

class _CameraScreenState
    extends State<CameraScreen> {
  CameraController? _controller;

  final CvDrugTestService _cvService =
  CvDrugTestService();

  bool _cameraReady = false;
  bool _analyzing = false;

  XFile? _photo;

  CvDrugTestResult? _result;

  int _imageWidth = 1;
  int _imageHeight = 1;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras =
      await availableCameras();

      if (cameras.isEmpty) {
        throw Exception(
          'No camera available.',
        );
      }

      CameraDescription selectedCamera =
          cameras.first;

      for (final camera in cameras) {
        if (camera.lensDirection ==
            CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        }
      }

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup:
        ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        _cameraReady = true;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
          Text('Camera error: $e'),
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

      final photo =
      await _controller!.takePicture();

      final bytes =
      await File(photo.path)
          .readAsBytes();

      final decoded =
      img.decodeImage(bytes);

      if (decoded == null) {
        throw Exception(
          'Could not decode captured image.',
        );
      }

      if (!mounted) return;

      setState(() {
        _photo = photo;
        _imageWidth = decoded.width;
        _imageHeight = decoded.height;
        _result = null;
      });

      await _controller!.pausePreview();

      /*
       * THIS IS NOW THE IMPORTANT PART.
       *
       * Camera image
       *       ↓
       * CvDrugTestService
       *       ↓
       * DartCV
       *       ↓
       * ArUco
       *       ↓
       * Perspective correction
       *       ↓
       * LAB
       *       ↓
       * Result
       */
      final result =
      await _cvService.analyzeImage(
        photo.path,
      );

      if (!mounted) return;

      setState(() {
        _result = result;
        _analyzing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _analyzing = false;

        _result =
            CvDrugTestResult(
              status: 'INCONCLUSIVE',
              message:
              'Camera/CV processing failed: $e',
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
    });

    try {
      await _controller?.resumePreview();
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
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
        child:
        CircularProgressIndicator(),
      )
          : _photo == null
          ? _cameraView()
          : _resultView(),
    );
  }

  // ---------------------------------------------------------------------------
  // CAMERA
  // ---------------------------------------------------------------------------

  Widget _cameraView() {
    return Stack(
      children: [
        Positioned.fill(
          child: CameraPreview(
            _controller!,
          ),
        ),

        /*
         * Capture guidance.
         */
        Positioned(
          top: 25,
          left: 20,
          right: 20,
          child: Container(
            padding:
            const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
              Colors.black.withOpacity(
                0.65,
              ),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Text(
                  'PLACE REFERENCE CARD IN FRAME',
                  textAlign:
                  TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Keep all 4 corner markers visible',
                  textAlign:
                  TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),

        /*
         * Centre guide.
         */
        Center(
          child: Container(
            width:
            MediaQuery.of(context)
                .size
                .width *
                0.78,
            height:
            MediaQuery.of(context)
                .size
                .height *
                0.58,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              borderRadius:
              BorderRadius.circular(12),
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
                decoration:
                BoxDecoration(
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

  // ---------------------------------------------------------------------------
  // RESULT
  // ---------------------------------------------------------------------------

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
          padding:
          const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            20,
          ),
          child: SizedBox(
            width: double.infinity,
            child:
            ElevatedButton.icon(
              onPressed:
              _analyzing
                  ? null
                  : _retake,
              icon: const Icon(
                Icons.camera_alt,
              ),
              label: const Text(
                'RETAKE PHOTO',
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // RESULT PANEL
  // ---------------------------------------------------------------------------

  Widget _resultPanel() {
    if (_analyzing) {
      return Container(
        width: double.infinity,
        padding:
        const EdgeInsets.all(20),
        color: Colors.white,
        child: const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'ANALYZING IMAGE...',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Detecting reference card and analysing colour',
              textAlign:
              TextAlign.center,
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
      padding:
      const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'NARCOX CV ANALYSIS',
            style: TextStyle(
              fontSize: 12,
              fontWeight:
              FontWeight.bold,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration:
                BoxDecoration(
                  color: statusColor,
                  borderRadius:
                  BorderRadius.circular(
                    8,
                  ),
                ),
                child: Text(
                  result.status,
                  style:
                  const TextStyle(
                    color: Colors.white,
                    fontWeight:
                    FontWeight.bold,
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
                    fontWeight:
                    FontWeight.bold,
                    fontSize: 12,
                  ),
                )
              else
                const Text(
                  'CARD NOT DETECTED',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight:
                    FontWeight.bold,
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
                fontWeight:
                FontWeight.bold,
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
                  result.distance
                      .toStringAsFixed(2),
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
              fontStyle:
              FontStyle.italic,
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
            fontWeight:
            FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ],
    );
  }
}