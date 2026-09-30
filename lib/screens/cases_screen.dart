import 'package:flutter/material.dart';

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  static const navy = Color(0xFF16324F);
  static const navyDark = Color(0xFF10283F);
  static const teal = Color(0xFF2A9D8F);
  static const tealLight = Color(0xFFE5F5F2);
  static const bg = Color(0xFFF4F7FA);
  static const text = Color(0xFF172B3A);
  static const muted = Color(0xFF71808E);
  static const border = Color(0xFFDCE5EA);

  final TextEditingController _searchController =
  TextEditingController();

  String _search = '';

  final List<Map<String, dynamic>> _cases = [
    {
      'id': 'CASE-260928-01',
      'title': 'Field Investigation — Sample 01',
      'status': 'ACTIVE',
      'tests': 2,
      'date': '28 Sep 2026',
      'operator': 'OFF-001',
      'location': 'Dehradun',
    },
    {
      'id': 'CASE-260927-04',
      'title': 'Suspected Substance Examination',
      'status': 'ACTIVE',
      'tests': 1,
      'date': '27 Sep 2026',
      'operator': 'OFF-001',
      'location': 'Dehradun',
    },
    {
      'id': 'CASE-260927-02',
      'title': 'Field Sample Examination',
      'status': 'PENDING',
      'tests': 1,
      'date': '27 Sep 2026',
      'operator': 'OFF-002',
      'location': 'Haridwar',
    },
    {
      'id': 'CASE-260926-03',
      'title': 'NDDK Field Examination',
      'status': 'CLOSED',
      'tests': 1,
      'date': '26 Sep 2026',
      'operator': 'OFF-003',
      'location': 'Rishikesh',
    },
  ];

  final List<Map<String, dynamic>> _tests = [
    {
      'id': 'VT-26092801',
      'caseId': 'CASE-260928-01',
      'result': 'POSITIVE',
      'kit': 'NDDK',
      'date': '28 Sep 2026',
      'time': '12:42 PM',
      'operator': 'OFF-001',
      'location': 'Dehradun',
    },
    {
      'id': 'VT-26092802',
      'caseId': 'CASE-260928-01',
      'result': 'NEGATIVE',
      'kit': 'NDDK',
      'date': '28 Sep 2026',
      'time': '11:18 AM',
      'operator': 'OFF-001',
      'location': 'Dehradun',
    },
    {
      'id': 'VT-26092708',
      'caseId': 'CASE-260927-04',
      'result': 'INCONCLUSIVE',
      'kit': 'NDDK',
      'date': '27 Sep 2026',
      'time': '04:36 PM',
      'operator': 'OFF-001',
      'location': 'Dehradun',
    },
    {
      'id': 'VT-26092705',
      'caseId': 'CASE-260927-02',
      'result': 'NEGATIVE',
      'kit': 'NDDK',
      'date': '27 Sep 2026',
      'time': '01:22 PM',
      'operator': 'OFF-002',
      'location': 'Haridwar',
    },
    {
      'id': 'VT-26092611',
      'caseId': 'CASE-260926-03',
      'result': 'POSITIVE',
      'kit': 'NDDK',
      'date': '26 Sep 2026',
      'time': '05:04 PM',
      'operator': 'OFF-003',
      'location': 'Rishikesh',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredCases {
    if (_search.trim().isEmpty) {
      return _cases;
    }

    final query = _search.toLowerCase();

    return _cases.where((item) {
      return item['id'].toString().toLowerCase().contains(query) ||
          item['title'].toString().toLowerCase().contains(query) ||
          item['status'].toString().toLowerCase().contains(query) ||
          item['operator'].toString().toLowerCase().contains(query) ||
          item['location'].toString().toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: navy),
        title: const Text(
          'Cases',
          style: TextStyle(
            color: text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          _header(),
          Expanded(
            child: _filteredCases.isEmpty
                ? _emptyState()
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                30,
              ),
              itemCount: _filteredCases.length,
              itemBuilder: (context, index) {
                return _caseCard(
                  _filteredCases[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        16,
        5,
        16,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FIELD INVESTIGATIONS',
            style: TextStyle(
              color: muted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Cases containing one or more field tests',
            style: TextStyle(
              color: muted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _search = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search Case ID, title, location...',
              hintStyle: const TextStyle(
                color: muted,
                fontSize: 11,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: muted,
                size: 20,
              ),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _search = '';
                  });
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: muted,
                  size: 18,
                ),
              )
                  : null,
              filled: true,
              fillColor: bg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: border,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: teal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _caseCard(Map<String, dynamic> item) {
    final caseId = item['id'] as String;

    final caseTests = _tests.where(
          (test) => test['caseId'] == caseId,
    ).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            _showCaseDetails(item);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: border,
              ),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: tealLight,
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.folder_rounded,
                        color: teal,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            caseId,
                            style: const TextStyle(
                              color: text,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['title'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: muted,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _statusBadge(item['status']),
                  ],
                ),

                const SizedBox(height: 15),

                Container(
                  height: 1,
                  color: border,
                ),

                const SizedBox(height: 13),

                Row(
                  children: [
                    _info(
                      Icons.science_outlined,
                      '${caseTests.length} test${caseTests.length == 1 ? '' : 's'}',
                    ),
                    const SizedBox(width: 15),
                    _info(
                      Icons.calendar_today_outlined,
                      item['date'],
                    ),
                  ],
                ),

                const SizedBox(height: 11),

                Row(
                  children: [
                    _info(
                      Icons.person_outline_rounded,
                      item['operator'],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _info(
                        Icons.location_on_outlined,
                        item['location'],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: muted,
                      size: 12,
                    ),
                  ],
                ),

                if (caseTests.isNotEmpty) ...[
                  const SizedBox(height: 13),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFB),
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.link_rounded,
                          color: teal,
                          size: 15,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Linked tests: ${caseTests.map((e) => e['id']).join('  •  ')}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: muted,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _info(
      IconData icon,
      String value,
      ) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: muted,
            size: 14,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: muted,
                fontSize: 8.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color background;
    Color foreground;

    if (status == 'ACTIVE') {
      background = tealLight;
      foreground = teal;
    } else if (status == 'CLOSED') {
      background = const Color(0xFFEFF1F3);
      foreground = muted;
    } else {
      background = const Color(0xFFFFF3DD);
      foreground = const Color(0xFF9A6700);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: foreground,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: tealLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.folder_off_outlined,
                color: teal,
                size: 28,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'No cases found',
              style: TextStyle(
                color: text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try another Case ID, title or search term.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCaseDetails(
      Map<String, dynamic> caseData,
      ) {
    final caseId = caseData['id'] as String;

    final caseTests = _tests.where(
          (test) => test['caseId'] == caseId,
    ).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          constraints: const BoxConstraints(
            maxHeight: 700,
          ),
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            25,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: border,
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Case Details',
                          style: TextStyle(
                            color: text,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _statusBadge(
                        caseData['status'],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _detail(
                    'Case ID',
                    caseData['id'],
                    Icons.folder_open_outlined,
                  ),
                  _detail(
                    'Case Title',
                    caseData['title'],
                    Icons.description_outlined,
                  ),
                  _detail(
                    'Created',
                    caseData['date'],
                    Icons.calendar_today_outlined,
                  ),
                  _detail(
                    'Operator',
                    caseData['operator'],
                    Icons.person_outline_rounded,
                  ),
                  _detail(
                    'Location',
                    caseData['location'],
                    Icons.location_on_outlined,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'TESTS IN THIS CASE',
                    style: TextStyle(
                      color: muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (caseTests.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius:
                        BorderRadius.circular(12),
                        border: Border.all(
                          color: border,
                        ),
                      ),
                      child: const Text(
                        'No tests are linked to this case yet.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 10,
                        ),
                      ),
                    )
                  else
                    ...caseTests.map(
                          (test) => _linkedTest(
                        test,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _linkedTest(
      Map<String, dynamic> test,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: const Color(0xFFF7FAFB),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            _showTestDetails(test);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: tealLight,
                    borderRadius:
                    BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.science_outlined,
                    color: teal,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        test['id'],
                        style: const TextStyle(
                          color: text,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${test['date']} • ${test['time']}',
                        style: const TextStyle(
                          color: muted,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                _testResultSmall(
                  test['result'],
                ),
                const SizedBox(width: 7),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: muted,
                  size: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _testResultSmall(String result) {
    Color background;
    Color foreground;

    if (result == 'POSITIVE') {
      background = const Color(0xFFFFE9E9);
      foreground = const Color(0xFFB42318);
    } else if (result == 'NEGATIVE') {
      background = const Color(0xFFE8F6EE);
      foreground = const Color(0xFF16794A);
    } else {
      background = const Color(0xFFFFF3DD);
      foreground = const Color(0xFF9A6700);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        result,
        style: TextStyle(
          color: foreground,
          fontSize: 7,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _showTestDetails(
      Map<String, dynamic> test,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            25,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: border,
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Test Details',
                          style: TextStyle(
                            color: text,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _testResultSmall(
                        test['result'],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _detail(
                    'Test ID',
                    test['id'],
                    Icons.science_outlined,
                  ),
                  _detail(
                    'Case ID',
                    test['caseId'],
                    Icons.folder_open_outlined,
                  ),
                  _detail(
                    'Result',
                    test['result'],
                    Icons.check_circle_outline_rounded,
                  ),
                  _detail(
                    'Test Kit',
                    test['kit'],
                    Icons.inventory_2_outlined,
                  ),
                  _detail(
                    'Date / Time',
                    '${test['date']} • ${test['time']}',
                    Icons.access_time_rounded,
                  ),
                  _detail(
                    'Operator',
                    test['operator'],
                    Icons.person_outline_rounded,
                  ),
                  _detail(
                    'Location',
                    test['location'],
                    Icons.location_on_outlined,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detail(
      String title,
      String value,
      IconData icon,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tealLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: teal,
              size: 17,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: text,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}