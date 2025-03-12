import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/mast_bloc.dart';
import '../blocs/mast_event.dart';
import '../blocs/mast_state.dart';
import '../utils/pdf_generator.dart';

class MastDesignScreen extends StatefulWidget {
  final double moment;

  MastDesignScreen({required this.moment});

  @override
  _MastDesignScreenState createState() => _MastDesignScreenState();
}

class _MastDesignScreenState extends State<MastDesignScreen> {
  final _formKey = GlobalKey<FormState>();
  double thickness = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mast Design Calculation")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("Moment: ${widget.moment.toStringAsFixed(2)} Nm"),
              TextFormField(
                decoration: InputDecoration(labelText: "Thickness (mm)"),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Enter thickness" : null,
                onSaved: (value) => thickness = double.parse(value!),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    BlocProvider.of<MastBloc>(context).add(CalculateMastDesign(
                      moment: widget.moment,
                      weight: totalWeight,
                      shearForce: totalShear,
                      deflection: deflection,
                    ));

                    // BlocProvider.of<MastBloc>(context).add(
                    //
                    //   CalculateMastDesign(
                    //       moment: widget.moment, thickness: thickness),
                    // );
                  }
                },
                child: Text("Calculate"),
              ),
              BlocBuilder<MastBloc, MastState>(
                builder: (context, state) {
                  if (state is MastDesignCalculated) {
                    return Column(
                      children: [
                        Text(
                            "Mast Strength: ${state.mastDesignResult.toStringAsFixed(2)}"),
                        ElevatedButton(
                          onPressed: () async {
                            await generatePDF(widget.moment, thickness,
                                state.mastDesignResult);
                          },
                          child: Text("Generate PDF"),
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
