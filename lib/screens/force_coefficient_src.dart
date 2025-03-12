import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/mast_bloc.dart';
import '../blocs/mast_event.dart';
import '../blocs/mast_state.dart';
import 'moment_calculation_src.dart';

class ForceCoefficientScreen extends StatefulWidget {
  @override
  _ForceCoefficientScreenState createState() => _ForceCoefficientScreenState();
}

class _ForceCoefficientScreenState extends State<ForceCoefficientScreen> {
  final _formKey = GlobalKey<FormState>();
  double windSpeed = 0;
  double diameter = 0;
  int numSides = 8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Force Coefficient Calculation")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: "Wind Speed (m/s)"),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? "Enter wind speed" : null,
                onSaved: (value) => windSpeed = double.parse(value!),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Diameter (mm)"),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Enter diameter" : null,
                onSaved: (value) => diameter = double.parse(value!),
              ),
              DropdownButton<int>(
                value: numSides,
                items: [8, 12, 16, 20].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text("$value sides"),
                  );
                }).toList(),
                onChanged: (value) => setState(() => numSides = value!),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    BlocProvider.of<MastBloc>(context).add(
                      CalculateForceCoefficient(
                        windSpeed: windSpeed,
                        diameter: diameter,
                        numSides: numSides,
                      ),
                    );
                  }
                },
                child: Text("Calculate"),
              ),
              BlocBuilder<MastBloc, MastState>(
                builder: (context, state) {
                  if (state is ForceCoefficientCalculated) {
                    return Column(
                      children: [
                        Text(
                            "Force Coefficient: ${state.forceCoefficient.toStringAsFixed(2)}"),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MomentCalculationScreen(
                                        forceCoefficient:
                                            state.forceCoefficient,
                                        diameter: diameter,
                                      )),
                            );
                          },
                          child: Text("Next"),
                        ),
                      ],
                    );
                  }
                  return Container();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
