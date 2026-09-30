import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const Color _navy = Color(0xFF0B2A4A);

  List<File> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);

    try {
      final directory = await getApplicationDocumentsDirectory();

      final files = directory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) {
        final name = file.path.toLowerCase();

        return name.endsWith('.pdf') &&
            (name.contains('narcox_report') ||
                name.contains('report'));
      })
          .toList();

      files.sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      if (!mounted) return;

      setState(() {
        _reports = files;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _reports = [];
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load reports: $e'),
        ),
      );
    }
  }

  String _fileName(File file) {
    return file.path.split(Platform.pathSeparator).last;
  }

  String _reportTitle(File file) {
    final name = _fileName(file);

    if (name.startsWith('NarcoX_Report_')) {
      return name
          .replaceFirst('NarcoX_Report_', '')
          .replaceAll('.pdf', '');
    }

    return name.replaceAll('.pdf', '');
  }

  String _dateText(File file) {
    final date = file.lastModifiedSync();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year • $hour:$minute $period';
  }

  Future<void> _viewReport(File file) async {
    if (!await file.exists()) return;

    final bytes = await file.readAsBytes();

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PdfViewerScreen(
          bytes: bytes,
          fileName: _fileName(file),
        ),
      ),
    );
  }

  Future<void> _shareReport(File file) async {
    if (!await file.exists()) return;

    final bytes = await file.readAsBytes();

    await Printing.sharePdf(
      bytes: bytes,
      filename: _fileName(file),
    );
  }

  Future<void> _deleteReport(File file) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Report?'),
          content: const Text(
            'This PDF will be permanently removed from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await file.delete();
      await _loadReports();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report deleted'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete report: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadReports,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh reports',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReports,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_reports.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 90),
          Icon(
            Icons.description_outlined,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 18),
          const Text(
            'No Reports Yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generated field test reports will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton.icon(
              onPressed: _loadReports,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(),
        const SizedBox(height: 14),
        ..._reports.map(_buildReportCard),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.folder_copy_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Generated Reports',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_reports.length} report${_reports.length == 1 ? '' : 's'} available',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(File file) {
    final title = _reportTitle(file);
    final date = _dateText(file);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: _navy,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Field Test Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewReport(file),
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 18,
                    ),
                    label: const Text('View'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareReport(file),
                    icon: const Icon(
                      Icons.share_outlined,
                      size: 18,
                    ),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _deleteReport(file),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  tooltip: 'Delete report',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfViewerScreen extends StatelessWidget {
  final Uint8List bytes;
  final String fileName;

  const _PdfViewerScreen({
    required this.bytes,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          fileName,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
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