import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dartcv4/dartcv.dart' as cv;
import 'package:image/image.dart' as img;

class CvDrugTestResult {
  final String status;
  final String message;
  final String? suspectedDrug;
  final double labL;
  final double labA;
  final double labB;
  final double distance;
  final int confidence;
  final bool qualityPassed;
  final bool cardDetected;

  const CvDrugTestResult({
    required this.status,
    required this.message,
    required this.suspectedDrug,
    required this.labL,
    required this.labA,
    required this.labB,
    required this.distance,
    required this.confidence,
    required this.qualityPassed,
    required this.cardDetected,
  });

  bool get isPositive => status == 'POSITIVE';
  bool get isNegative => status == 'NEGATIVE';
  bool get isInconclusive => status == 'INCONCLUSIVE';
}

class CvDrugTestService {
  static const int cardSize = 500;

  static const double matchThreshold = 25.0;
  static const double inconclusiveThreshold = 37.5;

  static const Map<String, List<double>> referenceProfiles = {
    'Opium': [55.0, 25.0, 25.0],
    'Morphine': [55.0, 35.0, 5.0],
    'Codeine': [60.0, 30.0, 10.0],
    'Heroin': [60.0, 25.0, 5.0],
    'Amphetamines': [65.0, 15.0, 35.0],
    'Mescaline': [55.0, 30.0, 35.0],
    'Marijuana': [55.0, -35.0, 35.0],
    'Hashish': [50.0, -25.0, 30.0],
    'Hashish oil': [45.0, -10.0, 35.0],
    'Cocaine': [60.0, -25.0, 10.0],
    'Methaqualone': [70.0, -5.0, 35.0],
  };

  static const Map<String, List<double>> referencePatchRatios = {
    'Test_A_Opium': [0.15, 0.15, 0.36, 0.19],

    'Test_A_Amphetamines_Start': [0.16, 0.26, 0.28, 0.30],
    'Test_A_Amphetamines_End': [0.35, 0.26, 0.47, 0.30],

    'Test_A_Mescaline_Start': [0.16, 0.32, 0.28, 0.36],
    'Test_A_Mescaline_End': [0.35, 0.32, 0.47, 0.36],

    'Test_E_Cocaine_Start': [0.16, 0.47, 0.29, 0.51],
    'Test_E_Cocaine_End': [0.38, 0.47, 0.52, 0.51],

    'Test_E_Methaqualone_Start': [0.16, 0.53, 0.29, 0.57],
    'Test_E_Methaqualone_End': [0.38, 0.53, 0.52, 0.57],

    'Test_Morphine_Start': [0.16, 0.64, 0.29, 0.68],
    'Test_Morphine_End': [0.37, 0.64, 0.51, 0.68],

    'Test_Codeine_Start': [0.16, 0.69, 0.29, 0.73],
    'Test_Codeine_End': [0.37, 0.69, 0.51, 0.73],

    'Test_Heroin_Start': [0.16, 0.75, 0.29, 0.79],
    'Test_Heroin_End': [0.37, 0.75, 0.51, 0.79],

    'Test_B_Marijuana_Start': [0.16, 0.90, 0.31, 0.95],
    'Test_B_Marijuana_End': [0.39, 0.90, 0.57, 0.95],
  };

  static const double whiteX1 = 0.05;
  static const double whiteY1 = 0.05;
  static const double whiteX2 = 0.15;
  static const double whiteY2 = 0.15;

  // Sample ROI, in units of card width/height, in the canonical frame where
  // the card occupies x,y in [0, 1]. x > 1.0 means "to the right of the card".
  static const double sampleX1 = 1.10;
  static const double sampleY1 = 0.30;
  static const double sampleX2 = 1.90;
  static const double sampleY2 = 0.80;

  /// Minimum fraction of the sample ROI that must actually be inside the
  /// camera frame after the perspective warp. Anything outside the frame is
  /// filled with black by warpPerspective and must never be analysed.
  static const double minRoiCoverage = 0.98;

  // ---------------------------------------------------------------------------
  // SAMPLE-PRESENCE GATE TUNING
  //
  // All measurements are made on the WHITE-BALANCED sample ROI in OpenCV 8-bit
  // Lab (a/b centred on 0 after subtracting 128), on a coarse grid of
  // presenceCell x presenceCell pixel cells.
  // ---------------------------------------------------------------------------

  static const int presenceCell = 4;

  /// A cell is "coloured" only if it is chromatic in absolute terms...
  static const double presenceMinChroma = 16.0;

  /// ...AND differs in colour (a/b plane) from the ROI's own border ring
  /// (the local background: table, paper, plate, etc.).
  static const double presenceMinContrast = 12.0;

  /// Ignore near-black (shadow / dark noise) and near-white (glare) cells.
  static const double presenceMinLightness = 25.0;
  static const double presenceMaxLightness = 95.0;

  /// Largest connected coloured blob, as a fraction of the ROI area.
  static const double presenceMinAreaFraction = 0.005;
  static const double presenceMaxAreaFraction = 0.80;

  /// Blob must be compact: reject thin lines/edges/printed strokes.
  static const int presenceMinBBoxCells = 6;
  static const double presenceMinFillRatio = 0.25;

  /// Blob median chroma must be clearly coloured.
  static const double presenceMinBlobChroma = 18.0;

  /// Blob must be one colour (not multi-coloured texture/print/noise).
  static const double presenceCoherenceRadius = 12.0;
  static const double presenceMinCoherence = 0.55;

  /// Width of the border band (fraction of ROI) used to estimate background.
  static const double presenceBorderFraction = 0.12;

  Future<CvDrugTestResult> analyzeImage(
      String imagePath, {
        String? selectedTest,
      }) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        return _error(
          'Unable to decode captured image.',
          cardDetected: false,
        );
      }

      final original = decoded;
      final quality = _qualityGate(original);

      if (!quality.passed) {
        return CvDrugTestResult(
          status: 'INCONCLUSIVE',
          message: quality.message,
          suspectedDrug: selectedTest,
          labL: 0,
          labA: 0,
          labB: 0,
          distance: 999,
          confidence: 0,
          qualityPassed: false,
          cardDetected: false,
        );
      }

      final resized = img.copyResize(
        original,
        width: 1000,
        height: ((original.height / original.width) * 1000).round(),
        interpolation: img.Interpolation.linear,
      );

      final bgr = _imageToBgr(resized);

      _WarpedResult? warped;
      try {
        warped = _detectAndWarpCard(bgr);
      } finally {
        bgr.dispose();
      }

      if (warped == null) {
        return _inconclusive(
          'Reference colour card not detected. Ensure all four ArUco markers are visible.',
          selectedTest,
          qualityPassed: true,
          cardDetected: false,
        );
      }

      // The sample zone lies outside the card. If the camera frame does not
      // cover it, the warped ROI contains black fill, not the scene.
      if (!warped.sampleInFrame) {
        return _inconclusive(
          'The sample area is outside the camera view. Move the camera back so the card and the sample area are both fully visible.',
          selectedTest,
          qualityPassed: true,
          cardDetected: true,
        );
      }

      final cardBgr = warped.card;
      final sampleBgr = warped.sample;

      // Calibrate first: the presence gate must judge colour AFTER white
      // balance so that a neutral background is actually neutral.
      final calibration = _calibrate(cardBgr, sampleBgr);

      final calibratedCard = calibration.card;
      final calibratedSample = calibration.sample;

      // ---- SAMPLE-PRESENCE GATE: classification must NOT run if it fails ----
      final presence = _analyzeSamplePresence(calibratedSample);

      if (!presence.passed || presence.mask == null) {
        assert(() {
          // ignore: avoid_print
          print('[CvDrugTest] sample presence FAILED: ${presence.reason}');
          return true;
        }());

        return _inconclusive(
          'No sample detected in the designated target zone. Reposition the test sample.',
          selectedTest,
          qualityPassed: true,
          cardDetected: true,
        );
      }

      final liveCardColors = _extractLiveCardLab(calibratedCard);

      final sampleLab = _extractSampleLab(
        calibratedSample,
        presence.mask!,
      );

      if (sampleLab == null ||
          _chroma(sampleLab.a, sampleLab.b) < presenceMinChroma) {
        return _inconclusive(
          'Reaction colour could not be reliably extracted. Retake the image.',
          selectedTest,
          qualityPassed: true,
          cardDetected: true,
        );
      }

      final classification = _classify(
        sampleLab,
        liveCardColors,
        selectedTest,
      );

      return CvDrugTestResult(
        status: classification.status,
        message: classification.message,
        suspectedDrug: classification.drug,
        labL: sampleLab.l,
        labA: sampleLab.a,
        labB: sampleLab.b,
        distance: classification.distance,
        confidence: classification.confidence,
        qualityPassed: true,
        cardDetected: true,
      );
    } catch (e) {
      return _error(
        'Offline colour analysis failed: $e',
        cardDetected: false,
      );
    }
  }

  CvDrugTestResult _inconclusive(
      String message,
      String? selectedTest, {
        required bool qualityPassed,
        required bool cardDetected,
      }) {
    return CvDrugTestResult(
      status: 'INCONCLUSIVE',
      message: message,
      suspectedDrug: selectedTest,
      labL: 0,
      labA: 0,
      labB: 0,
      distance: 999,
      confidence: 0,
      qualityPassed: qualityPassed,
      cardDetected: cardDetected,
    );
  }

  // ---------------------------------------------------------------------------
  // ARUCO + PERSPECTIVE
  // ---------------------------------------------------------------------------

  _WarpedResult? _detectAndWarpCard(cv.Mat image) {
    final toDispose = <dynamic>[];

    try {
      final gray = cv.cvtColor(image, cv.COLOR_BGR2GRAY);
      toDispose.add(gray);

      final dictionary = cv.ArucoDictionary.predefined(
        cv.PredefinedDictionaryType.DICT_4X4_50,
      );

      final parameters = cv.ArucoDetectorParameters.empty();

      final detector = cv.ArucoDetector.create(
        dictionary,
        parameters,
      );

      final detection = detector.detectMarkers(gray);
      final corners = detection.$1;
      final ids = detection.$2;

      if (ids.length < 4) {
        return null;
      }

      final cornerCenters = <int, cv.Point2f>{};

      for (int i = 0; i < ids.length; i++) {
        final id = ids[i];

        if (id < 0 || id > 49 || i >= corners.length) {
          continue;
        }

        final marker = corners[i];

        if (marker.length < 4) {
          continue;
        }

        double sx = 0.0;
        double sy = 0.0;

        for (final p in marker) {
          sx += p.x;
          sy += p.y;
        }

        cornerCenters[id] = cv.Point2f(
          sx / marker.length,
          sy / marker.length,
        );
      }

      if (!cornerCenters.containsKey(0) ||
          !cornerCenters.containsKey(1) ||
          !cornerCenters.containsKey(2) ||
          !cornerCenters.containsKey(3)) {
        return null;
      }

      final last = (cardSize - 1).toDouble();

      final src = cv.VecPoint2f.fromList([
        cornerCenters[0]!,
        cornerCenters[1]!,
        cornerCenters[2]!,
        cornerCenters[3]!,
      ]);
      toDispose.add(src);

      final dst = cv.VecPoint2f.fromList([
        cv.Point2f(0, 0),
        cv.Point2f(last, 0),
        cv.Point2f(last, last),
        cv.Point2f(0, last),
      ]);
      toDispose.add(dst);

      final matrix = cv.getPerspectiveTransform2f(src, dst);
      toDispose.add(matrix);

      final card = cv.warpPerspective(
        image,
        matrix,
        (cardSize, cardSize),
      );
      toDispose.add(card);

      // -----------------------------------------------------------------------
      // Canonical frame (after warp):
      //   card              : x in [0, 499],   y in [0, 499]
      //   ArUco 0,1,2,3     : marker centres at the four card corners
      //   sample ROI        : x in [550, 950), y in [150, 400)
      //
      // The ROI is entirely to the RIGHT of the card (550 > 499) and inside
      // the 1000x500 canvas vertically, so it is outside the reference card
      // and cannot contain any card patch.
      // -----------------------------------------------------------------------

      final roiX1 = (cardSize * sampleX1).round();
      final roiY1 = (cardSize * sampleY1).round();
      final roiX2 = (cardSize * sampleX2).round();
      final roiY2 = (cardSize * sampleY2).round();

      assert(
      roiX1 > cardSize - 1,
      'Sample ROI must lie completely outside the reference card.',
      );

      final expanded = cv.warpPerspective(
        image,
        matrix,
        (cardSize * 2, cardSize),
      );
      toDispose.add(expanded);

      if (roiX1 <= cardSize - 1 ||
          roiY1 < 0 ||
          roiX2 > expanded.cols ||
          roiY2 > expanded.rows ||
          roiX2 <= roiX1 ||
          roiY2 <= roiY1) {
        return null;
      }

      final roiRect = cv.Rect(
        roiX1,
        roiY1,
        roiX2 - roiX1,
        roiY2 - roiY1,
      );

      // Validity mask: warp an all-ones image with the same homography.
      // Pixels that fall outside the camera frame come out as 0.
      final ones = cv.Mat.ones(
        image.rows,
        image.cols,
        cv.MatType.CV_8UC1,
      );
      toDispose.add(ones);

      final validWarp = cv.warpPerspective(
        ones,
        matrix,
        (cardSize * 2, cardSize),
      );
      toDispose.add(validWarp);

      final validRoi = cv.Mat.fromMat(
        validWarp,
        copy: true,
        roi: roiRect,
      );
      toDispose.add(validRoi);

      final coverage = cv.countNonZero(validRoi) /
          ((roiX2 - roiX1) * (roiY2 - roiY1));

      final sampleCrop = cv.Mat.fromMat(
        expanded,
        copy: true,
        roi: roiRect,
      );
      toDispose.add(sampleCrop);

      final sample = cv.resize(
        sampleCrop,
        (cardSize, cardSize),
      );
      toDispose.add(sample);

      return _WarpedResult(
        card: _matToBgrImage(card),
        sample: _matToBgrImage(sample),
        sampleCoverage: coverage.toDouble(),
      );
    } finally {
      for (final o in toDispose) {
        try {
          o.dispose();
        } catch (_) {}
      }
    }
  }

  // ---------------------------------------------------------------------------
  // CALIBRATION
  // ---------------------------------------------------------------------------

  _CalibrationResult _calibrate(
      img.Image card,
      img.Image sample,
      ) {
    final live = _extractRawPatches(card);

    final white = _meanPatch(
      card,
      whiteX1,
      whiteY1,
      whiteX2,
      whiteY2,
    );

    final calibratedCard = _whiteBalance(card, white);
    final calibratedSample = _whiteBalance(sample, white);

    return _CalibrationResult(
      card: calibratedCard,
      sample: calibratedSample,
      livePatches: live,
    );
  }

  Map<String, List<double>> _extractRawPatches(img.Image image) {
    final result = <String, List<double>>{};

    for (final entry in referencePatchRatios.entries) {
      final r = entry.value;

      final x1 = (image.width * r[0]).round();
      final y1 = (image.height * r[1]).round();
      final x2 = (image.width * r[2]).round();
      final y2 = (image.height * r[3]).round();

      if (x2 <= x1 || y2 <= y1) {
        continue;
      }

      final valuesR = <double>[];
      final valuesG = <double>[];
      final valuesB = <double>[];

      for (int y = y1; y < y2 && y < image.height; y++) {
        for (int x = x1; x < x2 && x < image.width; x++) {
          final p = image.getPixel(x, y);

          valuesR.add(p.r.toDouble());
          valuesG.add(p.g.toDouble());
          valuesB.add(p.b.toDouble());
        }
      }

      if (valuesR.isEmpty) {
        continue;
      }

      result[entry.key] = [
        _median(valuesB),
        _median(valuesG),
        _median(valuesR),
      ];
    }

    return result;
  }

  img.Image _whiteBalance(
      img.Image image,
      List<double> white,
      ) {
    final out = img.Image.from(image);

    final scaleR = 245.0 / (white[0] + 1e-5);
    final scaleG = 245.0 / (white[1] + 1e-5);
    final scaleB = 245.0 / (white[2] + 1e-5);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);

        final r = _clamp255(p.r * scaleR);
        final g = _clamp255(p.g * scaleG);
        final b = _clamp255(p.b * scaleB);

        out.setPixelRgb(x, y, r, g, b);
      }
    }

    return out;
  }

  List<double> _meanPatch(
      img.Image image,
      double x1,
      double y1,
      double x2,
      double y2,
      ) {
    final sx = (image.width * x1).round();
    final sy = (image.height * y1).round();
    final ex = (image.width * x2).round();
    final ey = (image.height * y2).round();

    double r = 0;
    double g = 0;
    double b = 0;
    int count = 0;

    for (int y = sy; y < ey && y < image.height; y++) {
      for (int x = sx; x < ex && x < image.width; x++) {
        final p = image.getPixel(x, y);

        r += p.r;
        g += p.g;
        b += p.b;
        count++;
      }
    }

    if (count == 0) {
      return [245.0, 245.0, 245.0];
    }

    return [
      r / count,
      g / count,
      b / count,
    ];
  }

  // ---------------------------------------------------------------------------
  // SAMPLE PRESENCE
  //
  // Decides whether the (white-balanced) sample ROI contains a discrete,
  // genuinely coloured region that differs from its own surroundings.
  //
  // A region is accepted only if ALL of the following hold:
  //   1. A connected blob of cells that are chromatic (chroma >= min) AND
  //      differ in a/b from the ROI border ring (the local background).
  //   2. The blob is big enough, not the whole field, and compact
  //      (not a thin line / edge).
  //   3. The blob median chroma is clearly coloured.
  //   4. The blob is a single coherent colour.
  //
  // Consequences:
  //   - white / grey / neutral background        -> no chromatic cells -> FAIL
  //   - uniform coloured background (e.g. table) -> zero contrast to the
  //     border ring -> FAIL
  //   - lighting gradient / noise / texture      -> low contrast, incoherent,
  //     or tiny blobs -> FAIL
  //   - coloured spot on a plain surface         -> PASS
  // ---------------------------------------------------------------------------

  _PresenceResult _analyzeSamplePresence(img.Image calibratedSample) {
    final bgr = _imageToBgr(calibratedSample);
    final labMat = cv.cvtColor(bgr, cv.COLOR_BGR2Lab);
    bgr.dispose();

    final data = Uint8List.fromList(labMat.data);
    final width = labMat.cols;
    final height = labMat.rows;
    labMat.dispose();

    final gw = width ~/ presenceCell;
    final gh = height ~/ presenceCell;

    if (gw < 10 || gh < 10) {
      return const _PresenceResult(false, 'ROI too small', null);
    }

    final cells = gw * gh;

    // Per-cell mean Lab (L: 0..100, a/b: centred on 0).
    final cl = List<double>.filled(cells, 0);
    final ca = List<double>.filled(cells, 0);
    final cb = List<double>.filled(cells, 0);

    for (int gy = 0; gy < gh; gy++) {
      for (int gx = 0; gx < gw; gx++) {
        double sl = 0, sa = 0, sb = 0;

        for (int dy = 0; dy < presenceCell; dy++) {
          for (int dx = 0; dx < presenceCell; dx++) {
            final x = gx * presenceCell + dx;
            final y = gy * presenceCell + dy;
            final i = (y * width + x) * 3;

            sl += data[i];
            sa += data[i + 1];
            sb += data[i + 2];
          }
        }

        final n = (presenceCell * presenceCell).toDouble();
        final idx = gy * gw + gx;

        cl[idx] = (sl / n / 255.0) * 100.0;
        ca[idx] = sa / n - 128.0;
        cb[idx] = sb / n - 128.0;
      }
    }

    // Background estimate = median colour of the border ring of the ROI.
    final bx = math.max(1, (gw * presenceBorderFraction).round());
    final by = math.max(1, (gh * presenceBorderFraction).round());

    final ringA = <double>[];
    final ringB = <double>[];

    for (int gy = 0; gy < gh; gy++) {
      for (int gx = 0; gx < gw; gx++) {
        if (gx < bx || gx >= gw - bx || gy < by || gy >= gh - by) {
          final idx = gy * gw + gx;
          ringA.add(ca[idx]);
          ringB.add(cb[idx]);
        }
      }
    }

    final bgA = _median(ringA);
    final bgB = _median(ringB);

    // Candidate "coloured" cells.
    final candidate = Uint8List(cells);
    int candidateCount = 0;

    for (int i = 0; i < cells; i++) {
      final l = cl[i];

      if (l < presenceMinLightness || l > presenceMaxLightness) {
        continue;
      }

      final chroma = _chroma(ca[i], cb[i]);
      final contrast = _chroma(ca[i] - bgA, cb[i] - bgB);

      if (chroma >= presenceMinChroma && contrast >= presenceMinContrast) {
        candidate[i] = 1;
        candidateCount++;
      }
    }

    if (candidateCount / cells < presenceMinAreaFraction) {
      return const _PresenceResult(
        false,
        'no chromatic region distinct from background',
        null,
      );
    }

    // Largest 4-connected component.
    final labels = Int32List(cells);
    final queue = Int32List(cells);

    int bestLabel = 0;
    int bestSize = 0;
    int nextLabel = 1;

    for (int start = 0; start < cells; start++) {
      if (candidate[start] == 0 || labels[start] != 0) {
        continue;
      }

      int head = 0;
      int tail = 0;

      queue[tail++] = start;
      labels[start] = nextLabel;

      while (head < tail) {
        final cur = queue[head++];
        final cx = cur % gw;
        final cy = cur ~/ gw;

        if (cx > 0) {
          final n = cur - 1;
          if (candidate[n] == 1 && labels[n] == 0) {
            labels[n] = nextLabel;
            queue[tail++] = n;
          }
        }
        if (cx < gw - 1) {
          final n = cur + 1;
          if (candidate[n] == 1 && labels[n] == 0) {
            labels[n] = nextLabel;
            queue[tail++] = n;
          }
        }
        if (cy > 0) {
          final n = cur - gw;
          if (candidate[n] == 1 && labels[n] == 0) {
            labels[n] = nextLabel;
            queue[tail++] = n;
          }
        }
        if (cy < gh - 1) {
          final n = cur + gw;
          if (candidate[n] == 1 && labels[n] == 0) {
            labels[n] = nextLabel;
            queue[tail++] = n;
          }
        }
      }

      if (tail > bestSize) {
        bestSize = tail;
        bestLabel = nextLabel;
      }

      nextLabel++;
    }

    final areaFraction = bestSize / cells;

    if (areaFraction < presenceMinAreaFraction) {
      return _PresenceResult(
        false,
        'largest coloured blob too small ($areaFraction)',
        null,
      );
    }

    if (areaFraction > presenceMaxAreaFraction) {
      return _PresenceResult(
        false,
        'coloured region covers the whole ROI ($areaFraction)',
        null,
      );
    }

    // Blob statistics.
    int minX = gw, minY = gh, maxX = -1, maxY = -1;
    final blobA = <double>[];
    final blobB = <double>[];
    final blobIdx = <int>[];

    for (int i = 0; i < cells; i++) {
      if (labels[i] != bestLabel) {
        continue;
      }

      final gx = i % gw;
      final gy = i ~/ gw;

      if (gx < minX) minX = gx;
      if (gx > maxX) maxX = gx;
      if (gy < minY) minY = gy;
      if (gy > maxY) maxY = gy;

      blobA.add(ca[i]);
      blobB.add(cb[i]);
      blobIdx.add(i);
    }

    final bboxW = maxX - minX + 1;
    final bboxH = maxY - minY + 1;

    if (bboxW < presenceMinBBoxCells || bboxH < presenceMinBBoxCells) {
      return const _PresenceResult(false, 'blob too thin (line/edge)', null);
    }

    final fill = bestSize / (bboxW * bboxH);

    if (fill < presenceMinFillRatio) {
      return const _PresenceResult(false, 'blob not compact', null);
    }

    final medA = _median(blobA);
    final medB = _median(blobB);

    if (_chroma(medA, medB) < presenceMinBlobChroma) {
      return const _PresenceResult(false, 'blob chroma too low', null);
    }

    int coherent = 0;
    for (int i = 0; i < blobA.length; i++) {
      if (_chroma(blobA[i] - medA, blobB[i] - medB) <=
          presenceCoherenceRadius) {
        coherent++;
      }
    }

    if (coherent / blobA.length < presenceMinCoherence) {
      return const _PresenceResult(false, 'blob colour not coherent', null);
    }

    // Pixel-level mask of the accepted blob, for colour extraction.
    final mask = Uint8List(width * height);

    for (final idx in blobIdx) {
      final gx = idx % gw;
      final gy = idx ~/ gw;

      for (int dy = 0; dy < presenceCell; dy++) {
        for (int dx = 0; dx < presenceCell; dx++) {
          final x = gx * presenceCell + dx;
          final y = gy * presenceCell + dy;
          mask[y * width + x] = 1;
        }
      }
    }

    return _PresenceResult(true, 'ok', mask);
  }

  // ---------------------------------------------------------------------------
  // LAB EXTRACTION
  // ---------------------------------------------------------------------------

  Map<String, List<double>> _extractLiveCardLab(
      img.Image calibratedCard,
      ) {
    final bgr = _imageToBgr(calibratedCard);

    final labMat = cv.cvtColor(
      bgr,
      cv.COLOR_BGR2Lab,
    );
    bgr.dispose();

    final data = Uint8List.fromList(labMat.data);
    labMat.dispose();

    final result = <String, List<double>>{};

    for (final entry in referencePatchRatios.entries) {
      final r = entry.value;

      final x1 = (cardSize * r[0]).round();
      final y1 = (cardSize * r[1]).round();
      final x2 = (cardSize * r[2]).round();
      final y2 = (cardSize * r[3]).round();

      final ls = <double>[];
      final aVals = <double>[];
      final bVals = <double>[];

      for (int y = y1; y < y2 && y < cardSize; y++) {
        for (int x = x1; x < x2 && x < cardSize; x++) {
          final i = (y * cardSize + x) * 3;

          if (i + 2 >= data.length) {
            continue;
          }

          ls.add(data[i].toDouble());
          aVals.add(data[i + 1].toDouble());
          bVals.add(data[i + 2].toDouble());
        }
      }

      if (ls.isEmpty) {
        continue;
      }

      result[entry.key] = [
        (_median(ls) / 255.0) * 100.0,
        _median(aVals) - 128.0,
        _median(bVals) - 128.0,
      ];
    }

    return result;
  }

  /// Extracts the reaction colour ONLY from pixels inside [mask], the blob
  /// accepted by the presence gate. There is deliberately no fallback to a
  /// "centre median" colour: if no chromatic pixels are found the result is
  /// null (inconclusive), never a neutral/background colour.
  _LabSample? _extractSampleLab(
      img.Image sample,
      Uint8List mask,
      ) {
    final bgr = _imageToBgr(sample);

    final labMat = cv.cvtColor(
      bgr,
      cv.COLOR_BGR2Lab,
    );
    bgr.dispose();

    final data = Uint8List.fromList(labMat.data);
    final rows = labMat.rows;
    final cols = labMat.cols;
    labMat.dispose();

    final selectedL = <double>[];
    final selectedA = <double>[];
    final selectedB = <double>[];

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final p = y * cols + x;

        if (p >= mask.length || mask[p] == 0) {
          continue;
        }

        final i = p * 3;

        if (i + 2 >= data.length) {
          continue;
        }

        final l = data[i].toDouble();
        final a = data[i + 1].toDouble();
        final b = data[i + 2].toDouble();

        final chroma = _chroma(a - 128.0, b - 128.0);

        if (chroma >= 12.0) {
          selectedL.add(l);
          selectedA.add(a);
          selectedB.add(b);
        }
      }
    }

    if (selectedL.isEmpty) {
      return null;
    }

    final bins = <String, int>{};

    for (int i = 0; i < selectedA.length; i++) {
      final aa = (selectedA[i] / 4).floor();
      final bb = (selectedB[i] / 4).floor();

      final key = '$aa:$bb';

      bins[key] = (bins[key] ?? 0) + 1;
    }

    if (bins.isEmpty) {
      return null;
    }

    final dominant = bins.entries.reduce(
          (p, q) => p.value >= q.value ? p : q,
    );

    final parts = dominant.key.split(':');

    final centerA = int.parse(parts[0]) * 4 + 2;
    final centerB = int.parse(parts[1]) * 4 + 2;

    final clusterL = <double>[];
    final clusterA = <double>[];
    final clusterB = <double>[];

    for (int i = 0; i < selectedA.length; i++) {
      final da = selectedA[i] - centerA;
      final db = selectedB[i] - centerB;

      if (math.sqrt(da * da + db * db) <= 10.0) {
        clusterL.add(selectedL[i]);
        clusterA.add(selectedA[i]);
        clusterB.add(selectedB[i]);
      }
    }

    if (clusterL.isEmpty) {
      return null;
    }

    return _LabSample(
      l: (_median(clusterL) / 255.0) * 100.0,
      a: _median(clusterA) - 128.0,
      b: _median(clusterB) - 128.0,
    );
  }

  // ---------------------------------------------------------------------------
  // CLASSIFICATION
  // ---------------------------------------------------------------------------

  _Classification _classify(
      _LabSample sample,
      Map<String, List<double>> liveCard,
      String? selectedTest,
      ) {
    final candidates = selectedTest != null &&
        referenceProfiles.containsKey(selectedTest)
        ? <String>[selectedTest]
        : referenceProfiles.keys.toList();

    String? bestDrug;
    double bestDistance = double.infinity;

    for (final drug in candidates) {
      final distance = _referenceDistance(
        sample,
        drug,
        liveCard,
      );

      if (distance < bestDistance) {
        bestDistance = distance;
        bestDrug = drug;
      }
    }

    if (bestDrug == null) {
      return const _Classification(
        status: 'INCONCLUSIVE',
        message: 'No usable reference colour profile is available.',
        confidence: 0,
        distance: 999,
        drug: null,
      );
    }

    if (bestDistance <= matchThreshold) {
      final confidence = ((1.0 -
          bestDistance / matchThreshold) *
          100)
          .round()
          .clamp(0, 100);

      return _Classification(
        status: 'POSITIVE',
        message:
        'Presumptive result: $bestDrug — colour reaction consistent with the reference profile. Laboratory confirmation required.',
        confidence: confidence,
        distance: bestDistance,
        drug: bestDrug,
      );
    }

    if (bestDistance <= inconclusiveThreshold) {
      return _Classification(
        status: 'INCONCLUSIVE',
        message:
        'Colour reaction is not sufficiently close to the $bestDrug reference profile. Retake the image under controlled lighting.',
        confidence: 40,
        distance: bestDistance,
        drug: bestDrug,
      );
    }

    return _Classification(
      status: 'NEGATIVE',
      message:
      'No sufficiently close match found with the reference colour profile. Laboratory confirmation required.',
      confidence: 95,
      distance: bestDistance,
      drug: bestDrug,
    );
  }

  double _referenceDistance(
      _LabSample sample,
      String drug,
      Map<String, List<double>> liveCard,
      ) {
    final profile = referenceProfiles[drug]!;

    final range = _findRangeForDrug(
      drug,
      liveCard,
    );

    if (range != null) {
      final dStart = _distance(
        sample,
        range.$1,
      );

      final dEnd = _distance(
        sample,
        range.$2,
      );

      final segment = _segmentDistance(
        sample,
        range.$1,
        range.$2,
      );

      return math.min(
        math.min(dStart, dEnd),
        segment,
      );
    }

    return _distance(
      sample,
      _LabSample(
        l: profile[0],
        a: profile[1],
        b: profile[2],
      ),
    );
  }

  (_LabSample, _LabSample)? _findRangeForDrug(
      String drug,
      Map<String, List<double>> liveCard,
      ) {
    String? start;
    String? end;

    switch (drug) {
      case 'Amphetamines':
        start = 'Test_A_Amphetamines_Start';
        end = 'Test_A_Amphetamines_End';
        break;

      case 'Mescaline':
        start = 'Test_A_Mescaline_Start';
        end = 'Test_A_Mescaline_End';
        break;

      case 'Cocaine':
        start = 'Test_E_Cocaine_Start';
        end = 'Test_E_Cocaine_End';
        break;

      case 'Methaqualone':
        start = 'Test_E_Methaqualone_Start';
        end = 'Test_E_Methaqualone_End';
        break;

      case 'Morphine':
        start = 'Test_Morphine_Start';
        end = 'Test_Morphine_End';
        break;

      case 'Codeine':
        start = 'Test_Codeine_Start';
        end = 'Test_Codeine_End';
        break;

      case 'Heroin':
        start = 'Test_Heroin_Start';
        end = 'Test_Heroin_End';
        break;

      case 'Marijuana':
        start = 'Test_B_Marijuana_Start';
        end = 'Test_B_Marijuana_End';
        break;

      default:
        return null;
    }

    final a = liveCard[start];
    final b = liveCard[end];

    if (a == null || b == null) {
      return null;
    }

    return (
    _LabSample(
      l: a[0],
      a: a[1],
      b: a[2],
    ),
    _LabSample(
      l: b[0],
      a: b[1],
      b: b[2],
    ),
    );
  }

  double _segmentDistance(
      _LabSample p,
      _LabSample a,
      _LabSample b,
      ) {
    final abL = b.l - a.l;
    final abA = b.a - a.a;
    final abB = b.b - a.b;

    final apL = p.l - a.l;
    final apA = p.a - a.a;
    final apB = p.b - a.b;

    final denom =
        abL * abL +
            abA * abA +
            abB * abB;

    if (denom <= 1e-9) {
      return _distance(p, a);
    }

    final t = ((apL * abL) +
        (apA * abA) +
        (apB * abB)) /
        denom;

    final clamped = t < 0.0 ? 0.0 : (t > 1.0 ? 1.0 : t);

    final closest = _LabSample(
      l: a.l + clamped * abL,
      a: a.a + clamped * abA,
      b: a.b + clamped * abB,
    );

    return _distance(
      p,
      closest,
    );
  }

  double _distance(
      _LabSample a,
      _LabSample b,
      ) {
    final dl = a.l - b.l;
    final da = a.a - b.a;
    final db = a.b - b.b;

    return math.sqrt(
      dl * dl +
          da * da +
          db * db,
    );
  }

  // ---------------------------------------------------------------------------
  // IMAGE / QUALITY
  // ---------------------------------------------------------------------------

  cv.Mat _imageToBgr(img.Image image) {
    final data = Uint8List(image.width * image.height * 3);
    int k = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);

        data[k++] = p.b.toInt();
        data[k++] = p.g.toInt();
        data[k++] = p.r.toInt();
      }
    }

    return cv.Mat.fromList(
      image.height,
      image.width,
      cv.MatType.CV_8UC3,
      data,
    );
  }

  img.Image _matToBgrImage(cv.Mat mat) {
    final out = img.Image(
      width: mat.cols,
      height: mat.rows,
    );

    final data = mat.data;

    for (int y = 0; y < mat.rows; y++) {
      for (int x = 0; x < mat.cols; x++) {
        final i = (y * mat.cols + x) * 3;

        if (i + 2 >= data.length) {
          continue;
        }

        out.setPixelRgb(
          x,
          y,
          data[i + 2],
          data[i + 1],
          data[i],
        );
      }
    }

    return out;
  }

  _QualityResult _qualityGate(img.Image image) {
    if (image.width < 300 || image.height < 300) {
      return const _QualityResult(
        false,
        'Image resolution is too low. Retake the image.',
      );
    }

    double brightness = 0;
    int count = 0;

    for (int y = 0; y < image.height; y += 4) {
      for (int x = 0; x < image.width; x += 4) {
        final p = image.getPixel(x, y);

        brightness +=
            0.114 * p.b +
                0.587 * p.g +
                0.299 * p.r;

        count++;
      }
    }

    if (count == 0) {
      return const _QualityResult(
        false,
        'Image quality could not be evaluated.',
      );
    }

    brightness /= count;

    if (brightness < 50) {
      return const _QualityResult(
        false,
        'Image is too dark. Improve lighting and retake.',
      );
    }

    if (brightness > 220) {
      return const _QualityResult(
        false,
        'Image is overexposed. Reduce glare and retake.',
      );
    }

    return const _QualityResult(
      true,
      'Image quality acceptable.',
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  double _chroma(double a, double b) => math.sqrt(a * a + b * b);

  double _median(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }

    final sorted = List<double>.from(values)..sort();

    final middle = sorted.length ~/ 2;

    if (sorted.length.isOdd) {
      return sorted[middle];
    }

    return (sorted[middle - 1] + sorted[middle]) / 2.0;
  }

  int _clamp255(double value) {
    final v = value.round();
    return v < 0 ? 0 : (v > 255 ? 255 : v);
  }

  CvDrugTestResult _error(
      String message, {
        required bool cardDetected,
      }) {
    return CvDrugTestResult(
      status: 'INCONCLUSIVE',
      message: message,
      suspectedDrug: null,
      labL: 0,
      labA: 0,
      labB: 0,
      distance: 999,
      confidence: 0,
      qualityPassed: false,
      cardDetected: cardDetected,
    );
  }
}

// -----------------------------------------------------------------------------
// INTERNAL TYPES
// -----------------------------------------------------------------------------

class _WarpedResult {
  final img.Image card;
  final img.Image sample;

  /// Fraction (0..1) of the sample ROI that lies inside the camera frame.
  final double sampleCoverage;

  const _WarpedResult({
    required this.card,
    required this.sample,
    required this.sampleCoverage,
  });

  bool get sampleInFrame =>
      sampleCoverage >= CvDrugTestService.minRoiCoverage;
}

class _CalibrationResult {
  final img.Image card;
  final img.Image sample;
  final Map<String, List<double>> livePatches;

  const _CalibrationResult({
    required this.card,
    required this.sample,
    required this.livePatches,
  });
}

class _PresenceResult {
  final bool passed;
  final String reason;

  /// cardSize*cardSize mask (1 = accepted sample pixel). Null when failed.
  final Uint8List? mask;

  const _PresenceResult(this.passed, this.reason, this.mask);
}

class _LabSample {
  final double l;
  final double a;
  final double b;

  const _LabSample({
    required this.l,
    required this.a,
    required this.b,
  });
}

class _Classification {
  final String status;
  final String message;
  final int confidence;
  final double distance;
  final String? drug;

  const _Classification({
    required this.status,
    required this.message,
    required this.confidence,
    required this.distance,
    required this.drug,
  });
}

class _QualityResult {
  final bool passed;
  final String message;

  const _QualityResult(
      this.passed,
      this.message,
      );
}