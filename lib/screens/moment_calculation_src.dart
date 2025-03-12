import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/mast_bloc.dart';
import '../blocs/mast_event.dart';
import '../blocs/mast_state.dart';
import 'mast_design_src.dart';

class MomentCalculationScreen extends StatefulWidget {
  final double forceCoefficient;
  final double diameter;

  MomentCalculationScreen(
      {required this.forceCoefficient, required this.diameter});

  @override
  _MomentCalculationScreenState createState() =>
      _MomentCalculationScreenState();
}

class _MomentCalculationScreenState extends State<MomentCalculationScreen> {
  final _formKey = GlobalKey<FormState>();
  double height = 0;
  double beta = 1.0; // Default correction factor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Moment Calculation")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                  "Force Coefficient: ${widget.forceCoefficient.toStringAsFixed(2)}"),
              TextFormField(
                decoration: InputDecoration(labelText: "Height (m)"),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Enter height" : null,
                onSaved: (value) => height = double.parse(value!),
              ),
              TextFormField(
                decoration:
                    InputDecoration(labelText: "Beta Correction Factor"),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? "Enter beta factor" : null,
                onSaved: (value) => beta = double.parse(value!),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    BlocProvider.of<MastBloc>(context).add(
                      CalculateMoment(
                        forceCoefficient: widget.forceCoefficient,
                        height: height,
                        beta: beta,
                        diameter: 1.0,
                      ),
                    );
                  }
                },
                child: Text("Calculate"),
              ),
              BlocBuilder<MastBloc, MastState>(
                builder: (context, state) {
                  if (state is MomentCalculated) {
                    return Column(
                      children: [
                        Text("Moment: ${state.moment.toStringAsFixed(2)} Nm"),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      MastDesignScreen(moment: state.moment)),
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
