import 'dart:async';
import 'package:flutter/material.dart';
import 'new_test_screen.dart';
import 'test_log_screen.dart';
import 'cases_screen.dart';
import 'sync_center.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  static const navy = Color(0xFF16324F);
  static const navyDark = Color(0xFF10283F);
  static const teal = Color(0xFF2A9D8F);
  static const tealLight = Color(0xFFE5F5F2);
  static const bg = Color(0xFFF4F7FA);
  static const text = Color(0xFF172B3A);
  static const muted = Color(0xFF71808E);
  static const border = Color(0xFFDCE5EA);

  bool pinned = false;
  bool hover = false;
  bool notifications = false;

  DateTime now = DateTime.now();
  int tagline = 0;

  Timer? clock;
  Timer? taglineTimer;

  final lines = [
    "Don't just capture colour. Capture confidence.",
    "Every verified test starts with one careful scan.",
    "The colour tells the story. VERITRA makes it traceable.",
    "Good evidence begins with a good capture.",
    "Capture. Analyse. Verify.",
  ];

  @override
  void initState() {
    super.initState();

    clock = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (mounted) {
          setState(() {
            now = DateTime.now();
          });
        }
      },
    );

    taglineTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) {
        if (mounted) {
          setState(() {
            tagline = (tagline + 1) % lines.length;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    clock?.cancel();
    taglineTimer?.cancel();
    super.dispose();
  }

  String get greeting {
    if (now.hour >= 5 && now.hour < 12) {
      return 'Good morning, Officer';
    }

    if (now.hour < 17) {
      return 'Good afternoon, Officer';
    }

    if (now.hour < 21) {
      return 'Good evening, Officer';
    }

    return 'Good night, Officer';
  }

  String get dateText {
    const d = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    const m = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return '${d[now.weekday - 1]}, '
        '${now.day} '
        '${m[now.month - 1]} '
        '${now.year}';
  }

  String get timeText {
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;

    final min = now.minute.toString().padLeft(2, '0');
    final sec = now.second.toString().padLeft(2, '0');

    return '$h:$min:$sec ${now.hour >= 12 ? 'PM' : 'AM'}';
  }

  bool get expanded => pinned || hover;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: LayoutBuilder(
        builder: (_, c) {
          return c.maxWidth < 800 ? _mobile() : _desktop();
        },
      ),
    );
  }

  Widget _desktop() {
    return Row(
      children: [
        MouseRegion(
          onEnter: (_) {
            setState(() {
              hover = true;
            });
          },
          onExit: (_) {
            if (!pinned) {
              setState(() {
                hover = false;
              });
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: expanded ? 245 : 72,
            child: _sidebar(),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Column(
                children: [
                  _topBar(),
                  Expanded(
                    child: _content(),
                  ),
                ],
              ),
              if (notifications)
                Positioned(
                  top: 74,
                  right: 28,
                  child: _notificationPanel(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mobile() {
    return Stack(
      children: [
        Column(
          children: [
            _mobileBar(),
            Expanded(
              child: _content(),
            ),
          ],
        ),
        if (notifications)
          Positioned(
            top: 68,
            right: 15,
            child: _notificationPanel(),
          ),
      ],
    );
  }

  Widget _sidebar() {
    return Material(
      color: navyDark,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: expanded ? 18 : 12,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        pinned = !pinned;
                        hover = pinned;
                      });
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Image.asset(
                        'assets/images/veritra_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) {
                          return const Icon(
                            Icons.shield_outlined,
                            color: navy,
                          );
                        },
                      ),
                    ),
                  ),
                  if (expanded) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VERITRA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'COLOUR · ANALYSE · VERIFY',
                            style: TextStyle(
                              color: Color(0xFF9EB3C5),
                              fontSize: 7,
                              letterSpacing: .8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 10),
                children: [
                  _nav(
                    Icons.dashboard_outlined,
                    Icons.dashboard_rounded,
                    'Home',
                    selected: true,
                  ),
                  _nav(
                    Icons.add_circle_outline,
                    Icons.add_circle_rounded,
                    'New Test',
                    onTap: _newTest,
                  ),
                  const SizedBox(height: 7),
                  _nav(
                    Icons.folder_open_outlined,
                    Icons.folder_rounded,
                    'Cases',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CasesScreen(),
                        ),
                      );
                    },
                  ),
                  _nav(
                    Icons.assignment_outlined,
                    Icons.assignment_rounded,
                    'Test Log',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TestLogScreen(),
                        ),
                      );
                    },
                  ),
                  _nav(
                    Icons.description_outlined,
                    Icons.description_rounded,
                    'Reports',
                    onTap: () => _soon('Reports'),
                  ),
                  _nav(
                    Icons.sync_rounded,
                    Icons.sync_rounded,
                    'Sync Center',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const SyncCenterScreen(),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: expanded ? 18 : 12,
                      vertical: 14,
                    ),
                    child: const Divider(
                      color: Color(0x221FFFFFF),
                    ),
                  ),
                  _nav(
                    Icons.settings_outlined,
                    Icons.settings_rounded,
                    'Settings',
                    onTap: () => _soon('Settings'),
                  ),
                  _nav(
                    Icons.help_outline_rounded,
                    Icons.help_rounded,
                    'Help',
                    onTap: () => _soon('Help'),
                  ),
                ],
              ),
            ),
            if (expanded)
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Text(
                  'FIELD EVIDENCE SYSTEM',
                  style: TextStyle(
                    color: Color(0xFF8FA5B6),
                    fontSize: 8,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _nav(
      IconData icon,
      IconData selectedIcon,
      String title, {
        bool selected = false,
        VoidCallback? onTap,
      }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? 10 : 8,
        vertical: 2,
      ),
      child: Material(
        color: selected
            ? teal.withOpacity(.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: SizedBox(
            height: 46,
            child: Row(
              mainAxisAlignment: expanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: expanded ? 12 : 0,
                  ),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    color: selected
                        ? teal
                        : const Color(0xFF9EB3C5),
                    size: 21,
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFFB7C5D1),
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
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

  Widget _topBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: border),
        ),
      ),
      child: Row(
        children: [
          const Flexible(
            child: Text(
              'FIELD EVIDENCE SYSTEM',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
              ),
            ),
          ),
          const Spacer(),
          _bell(),
          const SizedBox(width: 18),
          Container(
            width: 1,
            height: 34,
            color: border,
          ),
          const SizedBox(width: 18),
          const CircleAvatar(
            radius: 17,
            backgroundColor: tealLight,
            child: Icon(
              Icons.person_outline_rounded,
              color: teal,
              size: 20,
            ),
          ),
          const SizedBox(width: 9),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Officer',
                style: TextStyle(
                  color: text,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Field Operator',
                style: TextStyle(
                  color: muted,
                  fontSize: 8,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: muted,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _mobileBar() {
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: border),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _drawer,
            icon: const Icon(
              Icons.menu_rounded,
              color: navy,
            ),
          ),
          const Text(
            'VERITRA',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          _bell(),
        ],
      ),
    );
  }

  Widget _bell() {
    return GestureDetector(
      onTap: () {
        setState(() {
          notifications = !notifications;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: navy,
              size: 21,
            ),
          ),
          Positioned(
            right: 3,
            top: 3,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: teal,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationPanel() {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: text,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 15),
            _notice(
              Icons.check_circle_outline_rounded,
              'Test completed',
              'VER-T-024 • 2 min ago',
            ),
            _notice(
              Icons.description_outlined,
              'Report ready',
              'Case VER-004 • 18 min ago',
            ),
            _notice(
              Icons.sync_problem_outlined,
              'Pending sync',
              '2 records waiting',
            ),
            const Divider(color: border),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    notifications = false;
                  });
                },
                child: const Text(
                  'View all notifications',
                  style: TextStyle(
                    color: teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notice(
      IconData icon,
      String title,
      String sub,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tealLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: teal,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: text,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sub,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _greeting(),
              const SizedBox(height: 25),
              _newTestCard(),
              const SizedBox(height: 28),
              _title('QUICK ACCESS'),
              const SizedBox(height: 12),
              _quickAccess(),
              const SizedBox(height: 28),
              _title('FIELD OVERVIEW'),
              const SizedBox(height: 12),
              _overview(),
              const SizedBox(height: 28),
              _timeline(),
              const SizedBox(height: 28),
              _presumptive(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _greeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            color: text,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              dateText,
              style: const TextStyle(
                color: muted,
                fontSize: 11,
              ),
            ),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: teal,
                shape: BoxShape.circle,
              ),
            ),
            Text(
              timeText,
              style: const TextStyle(
                color: navy,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          child: Text(
            lines[tagline],
            key: ValueKey(tagline),
            style: const TextStyle(
              color: teal,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _newTestCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            navy,
            Color(0xFF214B69),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (_, c) {
          final small = c.maxWidth < 600;

          final textPart = const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FIELD WORKSPACE',
                style: TextStyle(
                  color: Color(0xFF8CE0D4),
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'New Field Test',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Capture, analyse and document a presumptive field-test result with evidence context.',
                style: TextStyle(
                  color: Color(0xFFB9C9D6),
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          );

          if (small) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textPart,
                const SizedBox(height: 22),
                _startButton(),
              ],
            );
          }

          return Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FIELD WORKSPACE',
                      style: TextStyle(
                        color: Color(0xFF8CE0D4),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'New Field Test',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Capture, analyse and document a presumptive field-test result with evidence context.',
                      style: TextStyle(
                        color: Color(0xFFB9C9D6),
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              _startButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _startButton() {
    return SizedBox(
      width: 190,
      child: ElevatedButton.icon(
        onPressed: _newTest,
        icon: const Icon(
          Icons.add_rounded,
          size: 19,
        ),
        label: const Text(
          'START NEW TEST',
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _quickAccess() {
    final items = [
      _Q(
        Icons.folder_open_outlined,
        'Cases',
        'Manage cases',
            () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CasesScreen(),
            ),
          );
        },
      ),
      _Q(
        Icons.assignment_outlined,
        'Test Log',
        'View tests',
            () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TestLogScreen(),
            ),
          );
        },
      ),
      _Q(
        Icons.description_outlined,
        'Reports',
        'Field reports',
            () => _soon('Reports'),
      ),
      _Q(
        Icons.sync_rounded,
        'Sync Center',
        'Sync records',
            () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SyncCenterScreen(),
            ),
          );
        },
      ),
    ];

    return LayoutBuilder(
      builder: (_, c) {
        final n = c.maxWidth >= 950
            ? 4
            : c.maxWidth >= 650
            ? 2
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: n,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: n == 2 ? 2.0 : 1.75,
          ),
          itemBuilder: (_, i) => items[i],
        );
      },
    );
  }

  Widget _overview() {
    final cards = [
      _O(
        '04',
        'Active Cases',
        Icons.folder_open_outlined,
      ),
      _O(
        '08',
        'Tests Today',
        Icons.science_outlined,
      ),
      _O(
        '02',
        'Pending Sync',
        Icons.sync_problem_outlined,
      ),
      _O(
        '06',
        'Reports',
        Icons.description_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (_, c) {
        final n = c.maxWidth >= 900
            ? 4
            : c.maxWidth >= 600
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: n,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemBuilder: (_, i) => cards[i],
        );
      },
    );
  }

  Widget _timeline() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RECENT TIMELINE',
                      style: TextStyle(
                        color: text,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Latest field activity',
                      style: TextStyle(
                        color: muted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () =>
                    _soon('Full Timeline'),
                child: const Text(
                  'VIEW ALL →',
                  style: TextStyle(
                    color: teal,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          _event(
            Icons.check_circle_outline,
            'Test completed',
            'VER-T-024 • Presumptive result recorded',
            '10:42 AM',
          ),
          _event(
            Icons.photo_camera_outlined,
            'Evidence captured',
            'Sample S-018 • Original image secured',
            '10:21 AM',
          ),
          _event(
            Icons.verified_outlined,
            'Reference verified',
            'VER-T-024 • Reference card detected',
            '10:19 AM',
          ),
          _event(
            Icons.folder_open_outlined,
            'Case updated',
            'Case VER-004 • Sample registered',
            '09:56 AM',
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _event(
      IconData icon,
      String title,
      String sub,
      String time, {
        bool last = false,
      }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 25,
                  height: 25,
                  decoration: const BoxDecoration(
                    color: tealLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: teal,
                    size: 14,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: text,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          sub,
                          style: const TextStyle(
                            color: muted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _presumptive() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: navy,
            size: 22,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'PRESUMPTIVE RESULT',
                  style: TextStyle(
                    color: navy,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'VERITRA field-test results are presumptive and should be confirmed through appropriate laboratory analysis.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 9,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String s) {
    return Text(
      s,
      style: const TextStyle(
        color: muted,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }

  void _newTest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NewTestScreen(),
      ),
    );
  }

  void _soon(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$name module will be connected here.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _drawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'VERITRA Navigation',
      barrierColor: Colors.black.withOpacity(.35),
      transitionDuration:
      const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: navyDark,
            child: SizedBox(
              width: 270,
              height: double.infinity,
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'VERITRA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 25),
                    _drawerItem(
                      'Home',
                      Icons.dashboard_rounded,
                      true,
                          () => Navigator.pop(context),
                    ),
                    _drawerItem(
                      'New Test',
                      Icons.add_circle_rounded,
                      false,
                          () {
                        Navigator.pop(context);
                        _newTest();
                      },
                    ),
                    _drawerItem(
                      'Cases',
                      Icons.folder_rounded,
                      false,
                          () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const CasesScreen(),
                          ),
                        );
                      },
                    ),
                    _drawerItem(
                      'Test Log',
                      Icons.assignment_rounded,
                      false,
                          () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const TestLogScreen(),
                          ),
                        );
                      },
                    ),
                    _drawerItem(
                      'Reports',
                      Icons.description_rounded,
                      false,
                          () {
                        Navigator.pop(context);
                        _soon('Reports');
                      },
                    ),
                    _drawerItem(
                      'Sync Center',
                      Icons.sync_rounded,
                      false,
                          () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const SyncCenterScreen(),
                          ),
                        );
                      },
                    ),
                    _drawerItem(
                      'Settings',
                      Icons.settings_rounded,
                      false,
                          () {
                        Navigator.pop(context);
                        _soon('Settings');
                      },
                    ),
                    _drawerItem(
                      'Help',
                      Icons.help_rounded,
                      false,
                          () {
                        Navigator.pop(context);
                        _soon('Help');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _drawerItem(
      String title,
      IconData icon,
      bool selected,
      VoidCallback tap,
      ) {
    return ListTile(
      onTap: tap,
      leading: Icon(
        icon,
        color: selected
            ? teal
            : const Color(0xFF9EB3C5),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected
              ? Colors.white
              : const Color(0xFFB7C5D1),
          fontSize: 12,
          fontWeight: selected
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    );
  }
}

class _Q extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback tap;

  const _Q(
      this.icon,
      this.title,
      this.sub,
      this.tap,
      );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _DashboardState.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _DashboardState.tealLight,
                  borderRadius:
                  BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: _DashboardState.teal,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        color:
                        _DashboardState.text,
                        fontSize: 10.5,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        color:
                        _DashboardState.muted,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _DashboardState.muted,
                size: 11,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _O extends StatelessWidget {
  final String value;
  final String title;
  final IconData icon;

  const _O(
      this.value,
      this.title,
      this.icon,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _DashboardState.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _DashboardState.tealLight,
              borderRadius:
              BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: _DashboardState.teal,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: _DashboardState.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: _DashboardState.muted,
                  fontSize: 8.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NewTestPlaceholder extends StatelessWidget {
  const NewTestPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DashboardState.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'New Field Test',
          style: TextStyle(
            color: _DashboardState.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(
          color: _DashboardState.navy,
        ),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(25),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _DashboardState.border,
            ),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.science_outlined,
                color: _DashboardState.teal,
                size: 45,
              ),
              SizedBox(height: 15),
              Text(
                'SmartScan will start here.',
                style: TextStyle(
                  color: _DashboardState.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This is the entry point for the Case → Sample → Test → Evidence workflow.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _DashboardState.muted,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends Dashboard {
  const HomeScreen({super.key});
}