import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mast_calculator/screens/force_coefficient_src.dart';
import 'blocs/mast_bloc.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MastBloc(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mast Calculation',
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: ForceCoefficientScreen(),
      ),
    );
  }
}
