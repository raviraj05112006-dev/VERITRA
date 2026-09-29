import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'field_test_companion_screen.dart';

class NewTestScreen extends StatefulWidget {
  const NewTestScreen({super.key});

  @override
  State<NewTestScreen> createState() => _NewTestScreenState();
}

class _NewTestScreenState extends State<NewTestScreen> {
  final LocationService _locationService = LocationService();

  String? _selectedKit;
  final TextEditingController _otherKitController =
  TextEditingController();

  double? _latitude;
  double? _longitude;
  double? _accuracy;
  DateTime? _locationTimestamp;

  bool _gettingLocation = false;

  Future<void> _getLocation() async {
    setState(() {
      _gettingLocation = true;
    });

    final position = await _locationService.getCurrentLocation();

    if (!mounted) return;

    setState(() {
      _gettingLocation = false;

      if (position != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _accuracy = position.accuracy;
        _locationTimestamp = DateTime.now();
      }
    });
  }

  bool get _canStart {
    if (_latitude == null ||
        _longitude == null ||
        _selectedKit == null) {
      return false;
    }

    if (_selectedKit == 'Others' &&
        _otherKitController.text.trim().isEmpty) {
      return false;
    }

    return true;
  }

  void _confirmAndStart() {
    if (!_canStart) return;

    final testId =
        'NX-${DateTime.now().millisecondsSinceEpoch}';

    final testKit = _selectedKit == 'Others'
        ? _otherKitController.text.trim()
        : _selectedKit;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FieldTestCompanionScreen(
          testId: testId,
          testKit: testKit,
          latitude: _latitude,
          longitude: _longitude,
          gpsAccuracy: _accuracy,
          testDateTime: DateTime.now(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otherKitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        title: const Text(
          'New Field Test',
          style: TextStyle(
            color: Color(0xFF123B5D),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF123B5D),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'TEST INITIALIZATION',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Capture the test location and select the test kit to begin.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            // LOCATION
            _sectionTitle(
              icon: Icons.location_on_outlined,
              title: 'Test Location',
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),

              child: Column(
                children: [

                  SizedBox(
                    width: double.infinity,
                    height: 45,

                    child: ElevatedButton(
                      onPressed:
                      _gettingLocation ? null : _getLocation,

                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xFF123B5D),

                        foregroundColor: Colors.white,

                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                      ),

                      child: _gettingLocation
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.my_location,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'GET CURRENT LOCATION',
                            style: TextStyle(
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_latitude != null) ...[
                    const SizedBox(height: 18),

                    _locationRow(
                      'Latitude',
                      _latitude!.toStringAsFixed(6),
                    ),

                    const SizedBox(height: 8),

                    _locationRow(
                      'Longitude',
                      _longitude!.toStringAsFixed(6),
                    ),

                    const SizedBox(height: 8),

                    _locationRow(
                      'Accuracy',
                      '±${_accuracy!.toStringAsFixed(1)} m',
                    ),

                    const SizedBox(height: 8),
                    
                    _locationRow('Timestamp', _locationTimestamp!.toString(),),

                    const SizedBox(height: 12),

                    Row(
                      children: const [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Colors.green,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Location captured',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),

            // TEST KIT
            _sectionTitle(
              icon: Icons.science_outlined,
              title: 'Test Kit',
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,

              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),

              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedKit,

                  isExpanded: true,

                  hint: const Text(
                    'Select Test Kit',
                  ),

                  items: const [
                    DropdownMenuItem(
                      value: 'NDDK',
                      child: Text('NDDK'),
                    ),
                    DropdownMenuItem(
                      value: 'Others',
                      child: Text('Others'),
                    ),
                  ],

                  onChanged: (value) {
                    setState(() {
                      _selectedKit = value;

                      if (value != 'Others') {
                        _otherKitController.clear();
                      }
                    });
                  },
                ),
              ),
            ),

            if (_selectedKit == 'Others') ...[
              const SizedBox(height: 12),

              TextField(
                controller: _otherKitController,

                onChanged: (_) {
                  setState(() {});
                },

                decoration: InputDecoration(
                  hintText: 'Enter test kit name',

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 45),

            // CONFIRM
            SizedBox(
              width: double.infinity,
              height: 52,

              child: ElevatedButton(
                onPressed:
                _canStart ? _confirmAndStart : null,

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF123B5D),

                  disabledBackgroundColor:
                  Colors.grey.shade300,

                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                ),

                child: const Text(
                  'CONFIRM & START',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF123B5D),
        ),

        const SizedBox(width: 8),

        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF123B5D),
          ),
        ),
      ],
    );
  }

  Widget _locationRow(
      String label,
      String value,
      ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}