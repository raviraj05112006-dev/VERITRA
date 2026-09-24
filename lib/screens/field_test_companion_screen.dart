import 'package:flutter/material.dart';
import 'camera_screen.dart';

// ---------------------------------------------------------
// OPTIONS
// Add the actual options here later.
// ---------------------------------------------------------

final List<String> physicalFeatures = [
  'Granular','Crystalline','Plant Material','Leafy / Flowering Material','Resinous','Sticky / Gum-Like','Soft Solid','Hard Solid','Brittle','Compressed / Pressed','Block / Chunk','Tablet / Pill','Capsule','Liquid','Viscous Liquid','Oil','Semi-Solid / Semi-Liquid','Syrup / Liquid preparation','Unknown',
  'Others',
];

final List<String> surfaceTextureFeatures = [
  'Fine','Coarse','Smooth','Rough','Fibrous','Granular','Crystalline','Resinous','Powedery','Flaky','Leafy','Irregular','Unknown',
  'Others',
];

final List<String> structureAppearanceFeatures = [
  'Homogenous','Heterogeneous','Transparent','Opaque','Shiny / Reflective','Dull / Matte','Visible crystals','Visible Particles','Visible Fibres','Irrgular Pieces','Unknown',
  'Others',
];

class FieldTestCompanionScreen extends StatefulWidget {
  const FieldTestCompanionScreen({super.key});

  @override
  State<FieldTestCompanionScreen> createState() =>
      _FieldTestCompanionScreenState();
}

class _FieldTestCompanionScreenState
    extends State<FieldTestCompanionScreen> {

  // ---------------------------------------------------------
  // SELECTED OPTIONS
  // ---------------------------------------------------------

  List<String> _selectedPhysicalFeatures = [];
  List<String> _selectedSurfaceTextureFeatures = [];
  List<String> _selectedStructureAppearanceFeatures = [];

  // ---------------------------------------------------------
  // TEXT CONTROLLERS
  // ---------------------------------------------------------

  final TextEditingController _physicalOtherController =
  TextEditingController();

  final TextEditingController _surfaceTextureOtherController =
  TextEditingController();

  final TextEditingController _structureAppearanceOtherController =
  TextEditingController();

  final TextEditingController _moreDetailsController =
  TextEditingController();

  final TextEditingController _suspicionController =
  TextEditingController();

  // ---------------------------------------------------------
  // CHECK WHETHER REQUIRED FIELDS ARE COMPLETE
  // ---------------------------------------------------------

  bool get _formCompleted {

    final physicalCompleted =
        _selectedPhysicalFeatures.isNotEmpty &&
            (!_selectedPhysicalFeatures.contains('Others') ||
                _physicalOtherController.text.trim().isNotEmpty);

    final surfaceTextureCompleted =
        _selectedSurfaceTextureFeatures.isNotEmpty &&
            (!_selectedSurfaceTextureFeatures.contains('Others') ||
                _surfaceTextureOtherController.text.trim().isNotEmpty);

    final structureAppearanceCompleted =
        _selectedStructureAppearanceFeatures.isNotEmpty &&
            (!_selectedStructureAppearanceFeatures.contains('Others') ||
                _structureAppearanceOtherController.text.trim().isNotEmpty);

    final suspicionCompleted =
        _suspicionController.text.trim().isNotEmpty;

    return physicalCompleted &&
        surfaceTextureCompleted &&
        structureAppearanceCompleted &&
        suspicionCompleted;
  }

  // ---------------------------------------------------------
  // DISPOSE CONTROLLERS
  // ---------------------------------------------------------

  @override
  void dispose() {
    _physicalOtherController.dispose();
    _surfaceTextureOtherController.dispose();
    _structureAppearanceOtherController.dispose();
    _moreDetailsController.dispose();
    _suspicionController.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------
  // MULTI-SELECT DROPDOWN
  // ---------------------------------------------------------

  Future<void> _showMultiSelectDialog({
    required String title,
    required List<String> options,
    required List<String> selectedValues,
    required Function(List<String>) onChanged,
  }) async {

    List<String> temporarySelection =
    List<String>.from(selectedValues);

    await showDialog(
      context: context,
      builder: (context) {

        return StatefulBuilder(
          builder: (context, setDialogState) {

            return AlertDialog(
              title: Text(title),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map((option) {

                    return CheckboxListTile(
                      title: Text(option),

                      value: temporarySelection.contains(option),

                      onChanged: (checked) {

                        setDialogState(() {

                          if (checked == true) {
                            temporarySelection.add(option);
                          } else {
                            temporarySelection.remove(option);
                          }

                        });
                      },

                      controlAffinity:
                      ListTileControlAffinity.leading,
                    );

                  }).toList(),
                ),
              ),

              actions: [

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('CANCEL'),
                ),

                ElevatedButton(
                  onPressed: () {

                    onChanged(
                      List<String>.from(temporarySelection),
                    );

                    Navigator.pop(context);
                  },
                  child: const Text('DONE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------
  // DISPLAY TEXT FOR SELECTED OPTIONS
  // ---------------------------------------------------------

  String _displaySelected(List<String> selected) {

    if (selected.isEmpty) {
      return 'Select features';
    }

    return selected.join(', ');
  }

  // ---------------------------------------------------------
  // DROPDOWN STYLE BOX
  // ---------------------------------------------------------

  Widget _multiSelectField({
    required String hint,
    required List<String> selectedValues,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedValues.isEmpty
                    ? hint
                    : selectedValues.join(', '),
                style: TextStyle(
                  fontSize: 15,
                  color: selectedValues.isEmpty
                      ? Colors.grey
                      : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const Icon(
              Icons.arrow_drop_down,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // BUILD UI
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF123B5D),
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'FIELD TEST COMPANION',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              'Field Observation',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF123B5D),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Enter the observed features before capturing the drug image.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            // =================================================
            // PHYSICAL FEATURES
            // =================================================

            const Text(
              'Physical Features',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            _multiSelectField(
              hint: 'Select physical features',
              selectedValues: _selectedPhysicalFeatures,

              onTap: () {

                _showMultiSelectDialog(
                  title: 'Physical Features',
                  options: physicalFeatures,
                  selectedValues: _selectedPhysicalFeatures,

                  onChanged: (values) {

                    setState(() {
                      _selectedPhysicalFeatures = values;
                    });
                  },
                );
              },
            ),

            if (_selectedPhysicalFeatures.contains('Others')) ...[

              const SizedBox(height: 12),

              TextField(
                controller: _physicalOtherController,

                onChanged: (_) {
                  setState(() {});
                },

                decoration: InputDecoration(
                  hintText: 'Enter other physical feature',
                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // =================================================
            // VISUAL FEATURES
            // =================================================

            const Text(
              'Visual Features',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 18),

            // -------------------------------------------------
            // SURFACE / TEXTURE
            // -------------------------------------------------

            const Text(
              'Surface / Texture',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            _multiSelectField(
              hint: 'Select surface / texture',
              selectedValues:
              _selectedSurfaceTextureFeatures,

              onTap: () {

                _showMultiSelectDialog(
                  title: 'Surface / Texture',
                  options: surfaceTextureFeatures,
                  selectedValues:
                  _selectedSurfaceTextureFeatures,

                  onChanged: (values) {

                    setState(() {
                      _selectedSurfaceTextureFeatures =
                          values;
                    });
                  },
                );
              },
            ),

            if (_selectedSurfaceTextureFeatures
                .contains('Others')) ...[

              const SizedBox(height: 12),

              TextField(
                controller:
                _surfaceTextureOtherController,

                onChanged: (_) {
                  setState(() {});
                },

                decoration: InputDecoration(
                  hintText:
                  'Enter other surface / texture',
                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // -------------------------------------------------
            // STRUCTURE / APPEARANCE
            // -------------------------------------------------

            const Text(
              'Structure / Appearance',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            _multiSelectField(
              hint: 'Select structure / appearance',
              selectedValues:
              _selectedStructureAppearanceFeatures,

              onTap: () {

                _showMultiSelectDialog(
                  title: 'Structure / Appearance',
                  options:
                  structureAppearanceFeatures,

                  selectedValues:
                  _selectedStructureAppearanceFeatures,

                  onChanged: (values) {

                    setState(() {

                      _selectedStructureAppearanceFeatures =
                          values;
                    });
                  },
                );
              },
            ),

            if (_selectedStructureAppearanceFeatures
                .contains('Others')) ...[

              const SizedBox(height: 12),

              TextField(
                controller:
                _structureAppearanceOtherController,

                onChanged: (_) {
                  setState(() {});
                },

                decoration: InputDecoration(
                  hintText:
                  'Enter other structure / appearance',
                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // =================================================
            // MORE DETAILS
            // =================================================

            const Text(
              'More Details (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _moreDetailsController,

              maxLines: 4,

              decoration: InputDecoration(
                hintText:
                'Enter any additional details',

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // =================================================
            // OFFICER'S SUSPICION
            // =================================================

            const Text(
              'Officer\'s Suspicion',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _suspicionController,

              onChanged: (_) {
                setState(() {});
              },

              maxLines: 4,

              decoration: InputDecoration(
                hintText:
                'What is your suspicion?',

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // =================================================
            // CAMERA
            // =================================================

            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                BorderRadius.circular(15),
              ),

              child: Column(
                children: [

                  Icon(
                    Icons.camera_alt,
                    size: 45,

                    color: _formCompleted
                        ? const Color(0xFF123B5D)
                        : Colors.grey,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _formCompleted
                        ? 'Camera Ready'
                        : 'Complete the required fields to activate camera',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,

                      color: _formCompleted
                          ? const Color(0xFF123B5D)
                          : Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton.icon(

                      onPressed: _formCompleted
                          ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CameraScreen(),
                          ),
                        );

                      }
                          : null,

                      icon: const Icon(
                        Icons.camera_alt,
                      ),

                      label: const Text(
                        'CAPTURE DRUG IMAGE',
                      ),

                      style: ElevatedButton.styleFrom(

                        backgroundColor:
                        const Color(0xFF123B5D),

                        foregroundColor:
                        Colors.white,

                        padding:
                        const EdgeInsets.symmetric(
                          vertical: 15,
                        ),

                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}