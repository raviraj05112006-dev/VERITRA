import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'new_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();

  String _locationStatus = 'CHECK';
  bool _checkingLocation = false;

  Future<void> _checkLocation() async {
    setState(() {
      _checkingLocation = true;
      _locationStatus = 'Checking...';
    });

    final position = await _locationService.getCurrentLocation();

    if (!mounted) return;

    setState(() {
      _checkingLocation = false;

      if (position != null) {
        _locationStatus = 'GPS Ready';
      } else {
        _locationStatus = 'Unavailable';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      // ---------------- TOP BAR ----------------
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HII, RAVI',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF123B5D),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'NarcoX',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              'Field Drug Testing & Evidence Management',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
              color: Color(0xFF123B5D),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Color(0xFF123B5D),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ---------------- BODY ----------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------- NEW FIELD TEST --------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF123B5D),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.science_outlined,
                    color: Colors.white,
                    size: 35,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Start New Field Test',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Begin a new field drug screening and create a secure digital record.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NewTestScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF123B5D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add),
                          SizedBox(width: 6),
                          Text(
                            'NEW FIELD TEST',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // -------- QUICK ACCESS --------
            const Text(
              'QUICK ACCESS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.science_outlined,
                    title: 'New Test',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewTestScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.history,
                    title: 'Test History',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.location_on_outlined,
                    title: 'Locations',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.lock_outline,
                    title: 'Secure Records',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // -------- SYSTEM STATUS --------
            const Text(
              'SYSTEM STATUS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  // LOCATION
                  _statusRow(
                    icon: Icons.location_on_outlined,
                    title: 'Location',
                    status: _locationStatus,
                    onTap: _checkingLocation ? null : _checkLocation,
                    isChecking: _checkingLocation,
                  ),

                  const Divider(height: 24),

                  // EVIDENCE SECURITY
                  _statusRow(
                    icon: Icons.lock_outline,
                    title: 'Evidence Security',
                    status: 'Secure',
                  ),

                  const Divider(height: 24),

                  // CONNECTIVITY
                  _statusRow(
                    icon: Icons.cloud_outlined,
                    title: 'Connectivity',
                    status: 'Offline Mode Available',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ---------------- BOTTOM NAVIGATION ----------------
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF123B5D),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.science_outlined),
            label: 'Tests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            label: 'Records',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACTION CARD
  // ============================================================

  Widget _quickActionCard({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 115,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: const Color(0xFF123B5D),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SYSTEM STATUS ROW
  // ============================================================

  Widget _statusRow({
    required IconData icon,
    required String title,
    required String status,
    VoidCallback? onTap,
    bool isChecking = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF1F6),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF123B5D),
            size: 22,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        if (isChecking)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF123B5D),
            ),
          )
        else
          GestureDetector(
            onTap: onTap,
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: onTap != null
                    ? const Color(0xFF123B5D)
                    : Colors.green,
              ),
            ),
          ),
      ],
    );
  }
}