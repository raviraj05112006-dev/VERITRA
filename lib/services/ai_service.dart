import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;

import '../models/detection.dart';

class AIService {
  late final OnnxRuntime _runtime;
  late final OrtSession _session;

  bool _loaded = false;

  static const List<String> classNames = [
    'Buds',
    'Cannabis-Leaf',
    'Cocaine',
    'Heroin',
    'Marijuana',
    'Shrooms',
    'broto',
    'cannabis',
    'cigar',
    'hookah',
    'lsd',
    'mashrooms',
    'mushrooms',
    'person',
    'pills',
    'rawcannabis',
    'smoke',
    'syringe',
    'syrup',
  ];

  Future<void> loadModel() async {
    if (_loaded) return;

    _runtime = OnnxRuntime();

    _session = await _runtime.createSessionFromAsset(
      'assets/models/best.onnx',
    );

    _loaded = true;

    print('NarcoX AI model loaded');
    print('Input: ${_session.inputNames}');
    print('Output: ${_session.outputNames}');
  }

  Future<List<Detection>> analyzeImage(String imagePath) async {
    await loadModel();

    final bytes = await File(imagePath).readAsBytes();
    final original = img.decodeImage(bytes);

    if (original == null) {
      throw Exception('Could not decode captured image.');
    }

    final resized = img.copyResize(
      original,
      width: 640,
      height: 640,
    );

    final tensorData = _createTensor(resized);

    final input = await OrtValue.fromList(
      tensorData,
      [1, 3, 640, 640],
    );

    final outputs = await _session.run({
      'images': input,
    });

    final output = outputs['output0'];

    if (output == null) {
      throw Exception('YOLO output0 not found.');
    }

    final raw = await output.asFlattenedList();

    return _decodeOutput(
      raw,
      original.width,
      original.height,
    );
  }

  Float32List _createTensor(img.Image image) {
    final tensor = Float32List(3 * 640 * 640);
    var index = 0;

    // R
    for (var y = 0; y < 640; y++) {
      for (var x = 0; x < 640; x++) {
        final pixel = image.getPixel(x, y);
        tensor[index++] = pixel.r / 255.0;
      }
    }

    // G
    for (var y = 0; y < 640; y++) {
      for (var x = 0; x < 640; x++) {
        final pixel = image.getPixel(x, y);
        tensor[index++] = pixel.g / 255.0;
      }
    }

    // B
    for (var y = 0; y < 640; y++) {
      for (var x = 0; x < 640; x++) {
        final pixel = image.getPixel(x, y);
        tensor[index++] = pixel.b / 255.0;
      }
    }

    return tensor;
  }

  List<Detection> _decodeOutput(
      List<dynamic> output,
      int originalWidth,
      int originalHeight,
      ) {
    const candidates = 8400;
    const classes = 19;
    const threshold = 0.50;

    final detections = <Detection>[];

    for (var i = 0; i < candidates; i++) {
      final x = _value(output, 0, i, candidates);
      final y = _value(output, 1, i, candidates);
      final w = _value(output, 2, i, candidates);
      final h = _value(output, 3, i, candidates);

      var bestConfidence = 0.0;
      var bestClass = -1;

      for (var c = 0; c < classes; c++) {
        final confidence =
        _value(output, 4 + c, i, candidates);

        if (confidence > bestConfidence) {
          bestConfidence = confidence;
          bestClass = c;
        }
      }

      if (bestClass < 0 ||
          bestConfidence < threshold) {
        continue;
      }

      var x1 = x - w / 2;
      var y1 = y - h / 2;
      var x2 = x + w / 2;
      var y2 = y + h / 2;

      x1 = x1.clamp(0.0, 640.0);
      y1 = y1.clamp(0.0, 640.0);
      x2 = x2.clamp(0.0, 640.0);
      y2 = y2.clamp(0.0, 640.0);

      x1 = x1 * originalWidth / 640;
      y1 = y1 * originalHeight / 640;
      x2 = x2 * originalWidth / 640;
      y2 = y2 * originalHeight / 640;

      detections.add(
        Detection(
          classId: bestClass,
          className: classNames[bestClass],
          confidence: bestConfidence,
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
        ),
      );
    }

    return _nms(detections);
  }

  double _value(
      List<dynamic> output,
      int row,
      int column,
      int candidates,
      ) {
    return (output[row * candidates + column] as num)
        .toDouble();
  }

  List<Detection> _nms(List<Detection> detections) {
    detections.sort(
          (a, b) => b.confidence.compareTo(a.confidence),
    );

    final selected = <Detection>[];

    for (final detection in detections) {
      var keep = true;

      for (final existing in selected) {
        if (detection.classId != existing.classId) {
          continue;
        }

        if (_iou(detection, existing) > 0.45) {
          keep = false;
          break;
        }
      }

      if (keep) {
        selected.add(detection);
      }
    }

    return selected;
  }

  double _iou(Detection a, Detection b) {
    final left = math.max(a.x1, b.x1);
    final top = math.max(a.y1, b.y1);
    final right = math.min(a.x2, b.x2);
    final bottom = math.min(a.y2, b.y2);

    final width = math.max(0.0, right - left);
    final height = math.max(0.0, bottom - top);

    final intersection = width * height;

    final areaA =
        math.max(0.0, a.x2 - a.x1) *
            math.max(0.0, a.y2 - a.y1);

    final areaB =
        math.max(0.0, b.x2 - b.x1) *
            math.max(0.0, b.y2 - b.y1);

    final union = areaA + areaB - intersection;

    if (union <= 0) return 0;

    return intersection / union;
  }
}