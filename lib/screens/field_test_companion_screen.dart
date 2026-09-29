import 'package:flutter/material.dart';
import 'camera_screen.dart';

// ---------------------------------------------------------
// PHYSICAL FEATURES
// ---------------------------------------------------------

final List<String> physicalFeatures = [
  'Granular',
  'Crystalline',
  'Plant Material',
  'Leafy / Flowering Material',
  'Resinous',
  'Sticky / Gum-Like',
  'Soft Solid',
  'Hard Solid',
  'Brittle',
  'Compressed / Pressed',
  'Block / Chunk',
  'Tablet / Pill',
  'Capsule',
  'Liquid',
  'Viscous Liquid',
  'Oil',
  'Semi-Solid / Semi-Liquid',
  'Syrup / Liquid preparation',
  'Unknown',
  'Others',
];

// ---------------------------------------------------------
// SURFACE / TEXTURE
// ---------------------------------------------------------

final List<String> surfaceTextureFeatures = [
  'Fine',
  'Coarse',
  'Smooth',
  'Rough',
  'Fibrous',
  'Granular',
  'Crystalline',
  'Resinous',
  'Powedery',
  'Flaky',
  'Leafy',
  'Irregular',
  'Unknown',
  'Others',
];

// ---------------------------------------------------------
// STRUCTURE / APPEARANCE
// ---------------------------------------------------------

final List<String> structureAppearanceFeatures = [
  'Homogenous',
  'Heterogeneous',
  'Transparent',
  'Opaque',
  'Shiny / Reflective',
  'Dull / Matte',
  'Visible crystals',
  'Visible Particles',
  'Visible Fibres',
  'Irrgular Pieces',
  'Unknown',
  'Others',
];

// ---------------------------------------------------------
// SUSPECTED DRUGS AND CHEMICAL FLOW
// ---------------------------------------------------------

final Map<String, String> drugToFirstReagent = {
  // TEST A
  'Opium': 'A1',
  'Morphine': 'A1',
  'Codeine': 'A1',
  'Heroin': 'A1',
  'Amphetamines': 'A1',
  'Mescaline': 'A1',

  // TEST B
  'Marijuana': 'B1',
  'Hashish': 'B1',
  'Hashish oil': 'B1',

  // TEST E
  'Cocaine': 'E1',
  'Methaqualone': 'E1',
};

final Map<String, List<String>> drugListByTest = {
  'A1': [
    'Opium',
    'Morphine',
    'Codeine',
    'Heroin',
    'Amphetamines',
    'Mescaline',
  ],

  'B1': [
    'Marijuana',
    'Hashish',
    'Hashish oil',
  ],

  'E1': [
    'Cocaine',
    'Methaqualone',
  ],
};

// Next reagent after the first chemical.
final Map<String, String> secondReagentMap = {
  'A1': 'A2',
  'B1': 'B2',
  'E1': 'E3',
};

// Third reagent where required.
final Map<String, String> thirdReagentMap = {
  'B1': 'B3',
  'E1': 'E4',
};

// ---------------------------------------------------------
// SCREEN
// ---------------------------------------------------------

class FieldTestCompanionScreen extends StatefulWidget {
  final String? testId;
  final String? testKit;
  final double? latitude;
  final double? longitude;
  final double? gpsAccuracy;
  final DateTime? testDateTime;

  const FieldTestCompanionScreen({
    super.key,
    this.testId,
    this.testKit,
    this.latitude,
    this.longitude,
    this.gpsAccuracy,
    this.testDateTime,
  });

  @override
  State<FieldTestCompanionScreen> createState() =>
      _FieldTestCompanionScreenState();
}

class _FieldTestCompanionScreenState
    extends State<FieldTestCompanionScreen> {

  // ---------------------------------------------------------
  // SELECTED FEATURES
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

  // ---------------------------------------------------------
  // CHEMICAL TESTING STATE
  // ---------------------------------------------------------

  String? _selectedSuspectedDrug;

  String? _selectedFirstReagent;

  String? _selectedSecondReagent;

  String? _selectedThirdReagent;

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

    final chemicalCompleted =
        _selectedSuspectedDrug != null &&
            _selectedFirstReagent != null &&
            _selectedSecondReagent != null &&
            (_selectedFirstReagent == 'A1' ||
                _selectedThirdReagent != null);

    return physicalCompleted &&
        surfaceTextureCompleted &&
        structureAppearanceCompleted &&
        chemicalCompleted;
  }

  // ---------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------

  @override
  void dispose() {

    _physicalOtherController.dispose();

    _surfaceTextureOtherController.dispose();

    _structureAppearanceOtherController.dispose();

    _moreDetailsController.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------
  // MULTI-SELECT DIALOG
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

                      value:
                      temporarySelection.contains(option),

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
                      List<String>.from(
                        temporarySelection,
                      ),
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
  // MULTI-SELECT FIELD
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

          contentPadding:
          const EdgeInsets.symmetric(
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

                overflow:
                TextOverflow.ellipsis,
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
  // NORMAL DROPDOWN FIELD
  // ---------------------------------------------------------

  Widget _dropdownField({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(12),
      ),

      child: DropdownButtonFormField<String>(
        value: value,

        isExpanded: true,

        decoration: InputDecoration(
          hintText: hint,

          filled: true,

          fillColor: Colors.white,

          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(12),

            borderSide:
            BorderSide.none,
          ),

          contentPadding:
          const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
        ),

        items: items.map((item) {

          return DropdownMenuItem<String>(
            value: item,

            child: Text(
              item,

              overflow:
              TextOverflow.ellipsis,
            ),
          );

        }).toList(),

        onChanged: onChanged,
      ),
    );
  }

  // ---------------------------------------------------------
  // SUSPECTED DRUG SELECTION
  // ---------------------------------------------------------

  void _selectSuspectedDrug(String? drug) {

    setState(() {

      _selectedSuspectedDrug = drug;

      _selectedFirstReagent =
      drug == null
          ? null
          : drugToFirstReagent[drug];

      _selectedSecondReagent = null;

      _selectedThirdReagent = null;
    });
  }

  // ---------------------------------------------------------
  // FIRST REAGENT
  // ---------------------------------------------------------

  void _selectFirstReagent(String? reagent) {

    setState(() {

      _selectedFirstReagent = reagent;

      _selectedSecondReagent =
      reagent == null
          ? null
          : secondReagentMap[reagent];

      _selectedThirdReagent = null;
    });
  }

  // ---------------------------------------------------------
  // SECOND REAGENT
  // ---------------------------------------------------------

  void _selectSecondReagent(String? reagent) {

    setState(() {

      _selectedSecondReagent = reagent;

      if (reagent == null ||
          _selectedFirstReagent == 'A1') {

        _selectedThirdReagent = null;
      }
    });
  }

  // ---------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor:
        const Color(0xFF123B5D),

        foregroundColor:
        Colors.white,

        elevation: 0,

        title: const Text(
          'FIELD TEST COMPANION',

          style: TextStyle(
            fontSize: 18,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(

        padding:
        const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            // =================================================
            // HEADER
            // =================================================

            const Text(
              'Field Observation',

              style: TextStyle(
                fontSize: 22,
                fontWeight:
                FontWeight.bold,
                color:
                Color(0xFF123B5D),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Enter the observed features and testing details before capturing the drug image.',

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
                fontWeight:
                FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            _multiSelectField(
              hint:
              'Select physical features',

              selectedValues:
              _selectedPhysicalFeatures,

              onTap: () {

                _showMultiSelectDialog(
                  title:
                  'Physical Features',

                  options:
                  physicalFeatures,

                  selectedValues:
                  _selectedPhysicalFeatures,

                  onChanged: (values) {

                    setState(() {

                      _selectedPhysicalFeatures =
                          values;
                    });
                  },
                );
              },
            ),

            if (_selectedPhysicalFeatures
                .contains('Others')) ...[

              const SizedBox(height: 12),

              TextField(
                controller:
                _physicalOtherController,

                onChanged: (_) {
                  setState(() {});
                },

                decoration:
                InputDecoration(
                  hintText:
                  'Enter other physical feature',

                  filled: true,

                  fillColor:
                  Colors.white,

                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                        12),

                    borderSide:
                    BorderSide.none,
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
                fontWeight:
                FontWeight.w600,
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
                fontWeight:
                FontWeight.w600,
                color:
                Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            _multiSelectField(
              hint:
              'Select surface / texture',

              selectedValues:
              _selectedSurfaceTextureFeatures,

              onTap: () {

                _showMultiSelectDialog(
                  title:
                  'Surface / Texture',

                  options:
                  surfaceTextureFeatures,

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

                decoration:
                InputDecoration(
                  hintText:
                  'Enter other surface / texture',

                  filled: true,

                  fillColor:
                  Colors.white,

                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                        12),

                    borderSide:
                    BorderSide.none,
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
                fontWeight:
                FontWeight.w600,
                color:
                Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            _multiSelectField(
              hint:
              'Select structure / appearance',

              selectedValues:
              _selectedStructureAppearanceFeatures,

              onTap: () {

                _showMultiSelectDialog(
                  title:
                  'Structure / Appearance',

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

                decoration:
                InputDecoration(
                  hintText:
                  'Enter other structure / appearance',

                  filled: true,

                  fillColor:
                  Colors.white,

                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                        12),

                    borderSide:
                    BorderSide.none,
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
                fontWeight:
                FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller:
              _moreDetailsController,

              maxLines: 4,

              decoration:
              InputDecoration(
                hintText:
                'Enter any additional details',

                filled: true,

                fillColor:
                Colors.white,

                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                      12),

                  borderSide:
                  BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // =================================================
            // CHEMICAL TESTING
            // =================================================

            const Text(
              'Chemical Testing',

              style: TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Select the suspected drug and follow the corresponding chemical testing sequence.',

              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 16),

            // -------------------------------------------------
            // SUSPECTED DRUG
            // -------------------------------------------------

            const Text(
              'Suspected Drug on Test',

              style: TextStyle(
                fontSize: 14,
                fontWeight:
                FontWeight.w600,
                color:
                Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            _dropdownField(
              hint:
              'Select suspected drug',

              value:
              _selectedSuspectedDrug,

              items:
              drugToFirstReagent.keys.toList(),

              onChanged:
              _selectSuspectedDrug,
            ),

            // -------------------------------------------------
            // FIRST CHEMICAL
            // -------------------------------------------------

            if (_selectedSuspectedDrug != null) ...[

              const SizedBox(height: 18),

              const Text(
                '1st Chemical Used',

                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              _dropdownField(
                hint:
                'Select first reagent',

                value:
                _selectedFirstReagent,

                items: [
                  drugToFirstReagent[
                  _selectedSuspectedDrug]!,
                ],

                onChanged:
                _selectFirstReagent,
              ),
            ],

            // -------------------------------------------------
            // SECOND CHEMICAL
            // -------------------------------------------------

            if (_selectedFirstReagent != null) ...[

              const SizedBox(height: 18),

              const Text(
                '2nd Chemical Used',

                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              _dropdownField(
                hint:
                'Select second reagent',

                value:
                _selectedSecondReagent,

                items: [
                  secondReagentMap[
                  _selectedFirstReagent]!,
                ],

                onChanged:
                _selectSecondReagent,
              ),
            ],

            // -------------------------------------------------
            // THIRD CHEMICAL
            // -------------------------------------------------

            if (_selectedFirstReagent == 'B1' ||
                _selectedFirstReagent == 'E1') ...[

              if (_selectedSecondReagent != null) ...[

                const SizedBox(height: 18),

                const Text(
                  '3rd Chemical Used',

                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                    FontWeight.w600,
                    color:
                    Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                _dropdownField(
                  hint:
                  'Select third reagent',

                  value:
                  _selectedThirdReagent,

                  items: [
                    thirdReagentMap[
                    _selectedFirstReagent]!,
                  ],

                  onChanged: (value) {

                    setState(() {

                      _selectedThirdReagent =
                          value;
                    });
                  },
                ),
              ],
            ],

            const SizedBox(height: 30),

            // =================================================
            // CAMERA
            // =================================================

            Container(
              width: double.infinity,

              padding:
              const EdgeInsets.all(20),

              decoration:
              BoxDecoration(
                color:
                Colors.white,

                borderRadius:
                BorderRadius.circular(
                    15),
              ),

              child: Column(
                children: [

                  Icon(
                    Icons.camera_alt,

                    size: 45,

                    color: _formCompleted
                        ? const Color(
                        0xFF123B5D)
                        : Colors.grey,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _formCompleted
                        ? 'Camera Ready'
                        : 'Complete the required fields to activate camera',

                    textAlign:
                    TextAlign.center,

                    style: TextStyle(
                      fontSize: 15,

                      fontWeight:
                      FontWeight.w600,

                      color: _formCompleted
                          ? const Color(
                          0xFF123B5D)
                          : Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,

                    child:
                    ElevatedButton.icon(

                      onPressed:
                      _formCompleted
                          ? () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CameraScreen(
                              testId: widget.testId,
                              testKit: widget.testKit,
                              latitude: widget.latitude,
                              longitude: widget.longitude,
                              gpsAccuracy: widget.gpsAccuracy,
                              testDateTime: widget.testDateTime,
                              suspectedSubstance: _selectedSuspectedDrug,
                              reagents: [
                                if (_selectedFirstReagent != null)
                                  _selectedFirstReagent!,
                                if (_selectedSecondReagent != null)
                                  _selectedSecondReagent!,
                                if (_selectedThirdReagent != null)
                                  _selectedThirdReagent!,
                              ],
                            ),
                          ),
                        );

                      }
                          : null,

                      icon:
                      const Icon(
                        Icons.camera_alt,
                      ),

                      label:
                      const Text(
                        'CAPTURE DRUG IMAGE',
                      ),

                      style:
                      ElevatedButton.styleFrom(

                        backgroundColor:
                        const Color(
                            0xFF123B5D),

                        foregroundColor:
                        Colors.white,

                        padding:
                        const EdgeInsets
                            .symmetric(
                          vertical: 15,
                        ),

                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(10),
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