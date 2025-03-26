import 'package:flutter/material.dart';
import 'package:mast_calculator/utils/constant2.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mast Calculation',
        theme: ThemeData(
          primaryColor: Colors.blueGrey,
          primarySwatch: Colors.blueGrey,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: MastCalculatorApp()
        //ForceCoefficientScreen(),
        );
  }
}

class MastCalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MastCalculatorScreen(),
    );
  }
}

class MastCalculatorScreen extends StatefulWidget {
  @override
  _MastCalculatorScreenState createState() => _MastCalculatorScreenState();
}

class _MastCalculatorScreenState extends State<MastCalculatorScreen> {
  Test2 ne = Test2();
  // Controllers for input fields
  final TextEditingController totalHeightController = TextEditingController();
  final TextEditingController topDiaController = TextEditingController();
  final TextEditingController bottomDiaController = TextEditingController();
  final TextEditingController thicknessController = TextEditingController();
  final TextEditingController fyController = TextEditingController();
  final TextEditingController VbController = TextEditingController();
  final TextEditingController betaController = TextEditingController();
  final TextEditingController numLuminariesController = TextEditingController();
  final TextEditingController luminaryWidthController = TextEditingController();
  final TextEditingController luminaryHeightController =
      TextEditingController();
  final TextEditingController noSidesController = TextEditingController();
  final TextEditingController materialController = TextEditingController();
  final TextEditingController equipController = TextEditingController();

  final TextEditingController exposureController = TextEditingController();

  final TextEditingController terrainController = TextEditingController();
  final TextEditingController mastController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  int selectedMastType = 1;
  int selectedExposure = 1; // Default selection
  int selectedTerrainType = 1; // Default selection
  int selectedMaterialType = 1; // Default selection

  // Default selection
  String outputMessage = "";
  String selectMessage = ""; // Store output

  void resetFields() {
    // Reset all TextEditingControllers
    totalHeightController.clear();
    topDiaController.clear();
    bottomDiaController.clear();
    thicknessController.clear();
    fyController.clear();
    VbController.clear();
    betaController.clear();
    numLuminariesController.clear();
    luminaryWidthController.clear();
    luminaryHeightController.clear();
    noSidesController.clear();
    materialController.clear();
    equipController.clear();
    exposureController.clear();
    terrainController.clear();

    // Reset dropdown selections (Set default values)
    selectedMaterialType = 1; // Default to Steel
    selectedTerrainType = 1; // Default to Urban
    selectedExposure = 1; // Default to Isolated
    selectedMastType = 1; // Default to Lighting Mast
    // selectedNoSides = 8; // Default to 8-sided mast

    // Refresh UI
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Text("Mast Calculation"),
        centerTitle: true,
        actions: [
          IconButton(onPressed: resetFields, icon: Icon(Icons.refresh))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildInputField(
                  "Total Height (m){10-60}m", totalHeightController),
              buildInputField("Top Diameter (mm)", topDiaController),
              buildInputField("Bottom Diameter (mm)", bottomDiaController),
              buildInputField(
                  "Thicknesses (comma-separated)", thicknessController),
              buildInputField("Yield Strength (fy)", fyController),
              buildInputField("Basic Wind Speed (Vb)", VbController),
              buildInputField("Beta Factor", betaController),
              buildInputField("Number of Luminaries", numLuminariesController),
              buildInputField("Luminary Width (mm)", luminaryWidthController),
              buildInputField("Luminary Height (mm)", luminaryHeightController),
              buildInputField("No of Sides (N)", noSidesController),
              //  buildInputField("Beta Factor", betaController),
              buildInputField("Equipment Weight(kg)", equipController),
              buildInputField2("Enter location", locationController),
              DropdownButtonFormField<int>(
                value: selectedMastType,
                decoration: InputDecoration(labelText: "Select Mast Type"),
                items: [
                  DropdownMenuItem(value: 1, child: Text("Lighting")),
                  DropdownMenuItem(value: 2, child: Text("CCTV")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedMastType = value!;
                    mastController.text = value.toString();
                  });
                },
                validator: (value) =>
                    value == null ? "Please select a Mast Type" : null,
              ),
              // buildInputField(
              //     "Enter Material(steel or concrete) ", materialController),
              DropdownButtonFormField<int>(
                value: selectedMaterialType,
                decoration: InputDecoration(labelText: "Select Material Type"),
                items: [
                  DropdownMenuItem(value: 1, child: Text("Steel")),
                  DropdownMenuItem(value: 2, child: Text("Concrete")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedMaterialType = value!;
                    materialController.text = value.toString();
                  });
                },
                validator: (value) =>
                    value == null ? "Please select a Mast Type" : null,
              ),
              // buildInputField("Enter exposure", exposureController),
              DropdownButtonFormField<int>(
                value: selectedExposure,
                decoration:
                    InputDecoration(labelText: "Select Exposure Category"),
                items: [
                  DropdownMenuItem(value: 1, child: Text("Isolated")),
                  DropdownMenuItem(value: 2, child: Text("Clustered")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedExposure = value!;
                    exposureController.text = value.toString();
                  });
                },
                validator: (value) =>
                    value == null ? "Please select an Exposure Category" : null,
              ),
              // buildInputField("Enter terrain ", terrainController),
              DropdownButtonFormField<int>(
                value: selectedTerrainType,
                decoration:
                    InputDecoration(labelText: "Select Terrain Category"),
                items: [
                  DropdownMenuItem(value: 1, child: Text("Urban")),
                  DropdownMenuItem(value: 2, child: Text("Suburban")),
                  DropdownMenuItem(value: 3, child: Text("Open")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedTerrainType = value!;
                    terrainController.text = value.toString();
                  });
                },
                validator: (value) =>
                    value == null ? "Please select a Terrain Category" : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Check for empty fields
                  if (totalHeightController.text.isEmpty) {
                    Fluttertoast.showToast(msg: "Total Height is required!");
                    return;
                  }
                  if (topDiaController.text.isEmpty) {
                    Fluttertoast.showToast(msg: "Top Diameter is required!");
                    return;
                  }
                  if (bottomDiaController.text.isEmpty) {
                    Fluttertoast.showToast(msg: "Bottom Diameter is required!");
                    return;
                  }
                  if (thicknessController.text.isEmpty) {
                    Fluttertoast.showToast(msg: "Thickness is required!");
                    return;
                  }
                  if (fyController.text.isEmpty) {
                    Fluttertoast.showToast(
                        msg: "Material Yield Strength (Fy) is required!");
                    return;
                  }
                  if (VbController.text.isEmpty) {
                    Fluttertoast.showToast(
                        msg: "Basic Wind Speed (Vb) is required!");
                    return;
                  }
                  if (betaController.text.isEmpty) {
                    Fluttertoast.showToast(msg: "Beta factor is required!");
                    return;
                  }
                  if (numLuminariesController.text.isEmpty) {
                    Fluttertoast.showToast(
                        msg: "Number of Luminaries is required!");
                    return;
                  }
                  if (luminaryWidthController.text.isEmpty) {
                    Fluttertoast.showToast(msg: "Luminary Width is required!");
                    return;
                  }
                  if (luminaryHeightController.text.isEmpty) {
                    Fluttertoast.showToast(msg: "Luminary Height is required!");
                    return;
                  }
                  if (noSidesController.text.isEmpty) {
                    Fluttertoast.showToast(msg: "Number of Sides is required!");
                    return;
                  }
                  if (materialController.text.isEmpty) {
                    Fluttertoast.showToast(msg: "Material is required!");
                    return;
                  }
                  if (equipController.text.isEmpty) {
                    Fluttertoast.showToast(
                        msg: "Equipment Weight is required!");
                    return;
                  }
                  if (exposureController.text.isEmpty) {
                    Fluttertoast.showToast(
                        msg: "Exposure Category is required!");
                    return;
                  }
                  if (terrainController.text.isEmpty) {
                    Fluttertoast.showToast(
                        msg: "Terrain Category is required!");
                    return;
                  }
                  if (locationController.text.isEmpty) {
                    Fluttertoast.showToast(msg: "Location is required!");
                    return;
                  }
                  if (selectedMastType == null) {
                    Fluttertoast.showToast(msg: "Please select a Mast Type");
                    return;
                  }
                  if (selectedExposure == null) {
                    Fluttertoast.showToast(
                        msg: "Please select an Exposure Category");
                    return;
                  }
                  if (selectedTerrainType == null) {
                    Fluttertoast.showToast(
                        msg: "Please select a Terrain Category");
                    return;
                  }

                  // Convert inputs to appropriate data types
                  double totalHeight = double.parse(totalHeightController.text);
                  double topDiameter = double.parse(topDiaController.text);
                  double bottomDiameter =
                      double.parse(bottomDiaController.text);
                  List<double> thickness = thicknessController.text
                      .split(",") // Split by commas
                      .map((e) => e.trim()) // Remove extra spaces
                      .where((e) => e.isNotEmpty) // Remove empty values
                      .map((e) =>
                          double.tryParse(e) ??
                          0.0) // Convert to double, default to 0.0 if invalid
                      .toList();
                  double fy = double.parse(fyController.text);
                  double vb = double.parse(VbController.text);
                  double beta = double.parse(betaController.text);
                  int noLuminaries = int.parse(numLuminariesController.text);
                  String location = locationController.text;

                  double luminaryWidth =
                      double.parse(luminaryWidthController.text);
                  double luminaryHeight =
                      double.parse(luminaryHeightController.text);
                  int sidesNumber = int.parse(noSidesController.text);
                  String material = materialController.text;
                  String terrain = terrainController.text;
                  String exposure = exposureController.text;
                  double equipmentWeight = double.parse(equipController.text);

                  // Execute method after validation
                  ne.main(
                      vb2: vb,
                      totalHeight2: totalHeight,
                      topDiameter2: topDiameter,
                      bottomDiameter2: bottomDiameter,
                      sidesNumber2: sidesNumber,
                      fy2: fy,
                      mastType2: selectedMastType,
                      thicknesses2: thickness,
                      noLuminaries2: noLuminaries,
                      luminaryWidth2: luminaryWidth,
                      luminaryHeight2: luminaryHeight,
                      material2: selectedMaterialType,
                      terrain2: selectedTerrainType,
                      exposure2: selectedExposure,
                      equipmentweight2: equipmentWeight,
                      beta2: beta,
                      location2: location);
                },
                child: Text("Calculate"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for input fields
  Widget buildInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget buildInputField2(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.text,
      ),
    );
  }
}
