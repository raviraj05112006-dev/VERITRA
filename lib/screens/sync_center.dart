import 'package:flutter/material.dart';

class SyncCenterScreen extends StatefulWidget {
  const SyncCenterScreen({super.key});

  @override
  State<SyncCenterScreen> createState() => _SyncCenterScreenState();
}

class _SyncCenterScreenState extends State<SyncCenterScreen> {
  bool _isOnline = true;
  bool _isSyncing = false;

  int _queuedRecords = 1;
  String _lastSync = 'Just now';

  final List<SyncRecord> _records = [
    SyncRecord(
      testId: 'VER-T-001',
      caseId: 'VER-C-001',
      sampleId: 'S-001',
      status: 'Synced',
      integrity: 'Integrity hash available',
    ),
  ];

  Future<void> _syncNow() async {
    if (!_isOnline) {
      _showMessage(
        'You are offline. Records will remain safely queued.',
      );
      return;
    }

    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    // Simulated synchronization delay.
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isSyncing = false;
      _queuedRecords = 0;
      _lastSync = 'Just now';

      for (final record in _records) {
        record.status = 'Synced';
      }
    });

    _showMessage('All pending records synchronized successfully.');
  }

  void _toggleOffline() {
    setState(() {
      _isOnline = !_isOnline;

      if (!_isOnline) {
        _queuedRecords = _records
            .where((record) => record.status != 'Synced')
            .length;
      }
    });
  }

  void _simulatePendingRecord() {
    setState(() {
      _records.insert(
        0,
        SyncRecord(
          testId: 'VER-T-${(_records.length + 1).toString().padLeft(3, '0')}',
          caseId: 'VER-C-${(_records.length + 1).toString().padLeft(3, '0')}',
          sampleId: 'S-${(_records.length + 1).toString().padLeft(3, '0')}',
          status: 'Pending',
          integrity: 'Integrity check available',
        ),
      );

      _queuedRecords++;
    });

    _showMessage('Test record added to sync queue.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF123B43),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1200,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(),
                  const SizedBox(height: 22),
                  _buildConnectionCard(),
                  const SizedBox(height: 18),
                  _buildStats(),
                  const SizedBox(height: 22),
                  _buildSyncQueue(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OFFLINE-FIRST OPERATIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: Color(0xFF718096),
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Sync Center',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF17212B),
                ),
              ),
            ],
          ),
        ),
        _connectionBadge(),
      ],
    );
  }

  Widget _connectionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _isOnline
            ? const Color(0xFFE8F7F1)
            : const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isOnline
              ? const Color(0xFFC9EBDD)
              : const Color(0xFFF2C9C5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _isOnline
                  ? const Color(0xFF22A06B)
                  : const Color(0xFFD64545),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            _isOnline ? 'Connected' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _isOnline
                  ? const Color(0xFF18794E)
                  : const Color(0xFFC0392B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(27),
      decoration: BoxDecoration(
        color: const Color(0xFF101923),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 650;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CONNECTION STATE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: Color(0xFF70A9B2),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isOnline
                    ? 'Secure connection available'
                    : 'Working offline',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isOnline
                    ? 'Records can be synchronized with the central service.'
                    : 'New records will remain locally stored until connection is restored.',
                style: const TextStyle(
                  color: Color(0xFF9BAAB6),
                  fontSize: 12,
                ),
              ),
            ],
          );

          final button = OutlinedButton.icon(
            onPressed: _toggleOffline,
            icon: Icon(
              _isOnline
                  ? Icons.cloud_off_outlined
                  : Icons.cloud_outlined,
              size: 17,
            ),
            label: Text(
              _isOnline ? 'Simulate offline' : 'Restore connection',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(
                color: Color(0xFF344451),
              ),
              backgroundColor: const Color(0xFF17232E),
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 18),
                button,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 20),
              button,
            ],
          );
        },
      ),
    );
  }

  Widget _buildStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _statCard(
            title: 'Queued records',
            value: '$_queuedRecords',
            subtitle: _queuedRecords == 0
                ? 'Queue clear'
                : 'Waiting for sync',
            icon: Icons.layers_outlined,
          ),
          _statCard(
            title: 'Local storage',
            value: '2.4 MB',
            subtitle: 'App data stored locally',
            icon: Icons.storage_outlined,
          ),
          _statCard(
            title: 'Last sync',
            value: _lastSync,
            subtitle: 'This device',
            icon: Icons.sync_outlined,
          ),
          _statCard(
            title: 'Integrity',
            value: 'Ready',
            subtitle: 'Local integrity checks',
            icon: Icons.verified_user_outlined,
          ),
        ];

        if (constraints.maxWidth < 700) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: card,
              ),
            )
                .toList(),
          );
        }

        return Row(
          children: cards.map(
                (card) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: card,
                ),
              );
            },
          ).toList(),
        );
      },
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE2E8EF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                icon,
                size: 18,
                color: const Color(0xFF159A8C),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF17212B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF9AA5B1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncQueue() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8EF),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 600;

                final title = const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SYNC QUEUE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: Color(0xFF8996A3),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Record synchronization',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF26333E),
                      ),
                    ),
                  ],
                );

                final buttons = Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _simulatePendingRecord,
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                      ),
                      label: const Text('Add pending'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF159A8C),
                        side: const BorderSide(
                          color: Color(0xFFD5E5E3),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed:
                      _isSyncing ? null : _syncNow,
                      icon: _isSyncing
                          ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons.sync,
                        size: 17,
                      ),
                      label: Text(
                        _isSyncing ? 'Syncing...' : 'Sync Now',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xFF1769D2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 13,
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  ],
                );

                if (narrow) {
                  return Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: 15),
                      buttons,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: title),
                    buttons,
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            if (_records.isEmpty)
              _emptyQueue()
            else
              ..._records.map(_syncRecordTile),
          ],
        ),
      ),
    );
  }

  Widget _emptyQueue() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 45),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.cloud_done_outlined,
            size: 40,
            color: Color(0xFF159A8C),
          ),
          SizedBox(height: 10),
          Text(
            'No records waiting for synchronization',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5865),
            ),
          ),
        ],
      ),
    );
  }

  Widget _syncRecordTile(SyncRecord record) {
    final isSynced = record.status == 'Synced';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE6EBEF),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.layers_outlined,
              size: 19,
              color: Color(0xFF3978A9),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  record.testId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF26333E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.caseId} • ${record.sampleId} • Evidence record',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8A96A2),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment:
                  WrapCrossAlignment.center,
                  children: [
                    _statusBadge(record.status),
                    if (isSynced)
                      Text(
                        record.integrity,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF8996A3),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final synced = status == 'Synced';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: synced
            ? const Color(0xFFE8F7F1)
            : const Color(0xFFFFF4DF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: synced
              ? const Color(0xFF18794E)
              : const Color(0xFFB7791F),
        ),
      ),
    );
  }
}

class SyncRecord {
  final String testId;
  final String caseId;
  final String sampleId;
  String status;
  final String integrity;

  SyncRecord({
    required this.testId,
    required this.caseId,
    required this.sampleId,
    required this.status,
    required this.integrity,
  });
}