import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../models/detection.dart';
import '../services/ai_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;

  final AIService _aiService = AIService();

  bool _cameraReady = false;
  bool _analyzing = false;

  XFile? _photo;

  List<Detection> _detections = [];

  int _imageWidth = 1;
  int _imageHeight = 1;

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
      final photo = await _controller!.takePicture();

      final bytes = await File(photo.path).readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) {
        throw Exception('Could not read captured image.');
      }

      if (!mounted) return;

      setState(() {
        _photo = photo;
        _imageWidth = decodedImage.width;
        _imageHeight = decodedImage.height;
        _analyzing = true;
        _detections = [];
      });

      await _controller!.pausePreview();

      final results =
      await _aiService.analyzeImage(photo.path);

      if (!mounted) return;

      setState(() {
        _detections = results;
        _analyzing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _analyzing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'AI analysis failed:\n$e',
          ),
        ),
      );
    }
  }

  Future<void> _retake() async {
    setState(() {
      _photo = null;
      _detections = [];
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Capture Drug Image'),
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
          child: CameraPreview(_controller!),
        ),

        Positioned(
          bottom: 35,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _capture,
              child: Container(
                width: 80,
                height: 80,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _buildImageWithBoxes(
                constraints.maxWidth,
                constraints.maxHeight,
              );
            },
          ),
        ),

        _resultPanel(),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            20,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _analyzing ? null : _retake,
              icon: const Icon(Icons.camera_alt),
              label: const Text('RETAKE PHOTO'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWithBoxes(
      double screenWidth,
      double screenHeight,
      ) {
    final imageAspectRatio =
        _imageWidth / _imageHeight;

    final screenAspectRatio =
        screenWidth / screenHeight;

    double displayedWidth;
    double displayedHeight;
    double offsetX;
    double offsetY;

    if (imageAspectRatio > screenAspectRatio) {
      // Image is wider than available area.
      displayedWidth = screenWidth;
      displayedHeight =
          screenWidth / imageAspectRatio;

      offsetX = 0;
      offsetY =
          (screenHeight - displayedHeight) / 2;
    } else {
      // Image is taller than available area.
      displayedHeight = screenHeight;
      displayedWidth =
          screenHeight * imageAspectRatio;

      offsetX =
          (screenWidth - displayedWidth) / 2;
      offsetY = 0;
    }

    return Stack(
      children: [
        Positioned(
          left: offsetX,
          top: offsetY,
          width: displayedWidth,
          height: displayedHeight,
          child: Image.file(
            File(_photo!.path),
            fit: BoxFit.fill,
          ),
        ),

        ..._detections.map(
              (detection) {
            final left =
                offsetX +
                    (detection.x1 / _imageWidth) *
                        displayedWidth;

            final top =
                offsetY +
                    (detection.y1 / _imageHeight) *
                        displayedHeight;

            final width =
                ((detection.x2 - detection.x1) /
                    _imageWidth) *
                    displayedWidth;

            final height =
                ((detection.y2 - detection.y1) /
                    _imageHeight) *
                    displayedHeight;

            return Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.red,
                    width: 3,
                  ),
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    color: Colors.red,
                    child: Text(
                      '${detection.className} '
                          '${(detection.confidence * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        if (_analyzing)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Analyzing image...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _resultPanel() {
    if (_analyzing) {
      return const SizedBox(
        height: 110,
        child: Center(
          child: Text(
            'AI analysis in progress...',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (_detections.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: const Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'NO DETECTION',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'No object exceeded the current '
                  'AI confidence threshold.',
            ),
          ],
        ),
      );
    }

    final best = _detections.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'AI VISUAL DETECTION',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            best.className,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Confidence: '
                '${(best.confidence * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),

          if (_detections.length > 1) ...[
            const SizedBox(height: 8),

            Text(
              '${_detections.length} detections found',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],

          const SizedBox(height: 8),

          const Text(
            'Presumptive AI visual detection — '
                'laboratory confirmation required.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}