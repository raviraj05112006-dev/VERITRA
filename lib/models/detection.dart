class Detection {
  final int classId;
  final String className;
  final double confidence;
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  const Detection({
    required this.classId,
    required this.className,
    required this.confidence,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });
}