// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'mast_event.dart';
// import 'mast_state.dart';
// import 'dart:math';
//
// class MastBloc extends Bloc<MastEvent, MastState> {
//   MastBloc() : super(MastInitial());
//
//   @override
//   Stream<MastState> mapEventToState(MastEvent event) async* {
//     try {
//       if (event is CalculateForceCoefficient) {
//         double Re = (event.diameter * event.windSpeed) / 1.46e-5;
//         double forceCoefficient = _getForceCoefficient(event.numSides, Re);
//         yield ForceCoefficientCalculated(forceCoefficient);
//       } else if (event is CalculateMoment) {
//         double moment = event.forceCoefficient *
//             0.613 *
//             pow(event.windSpeed, 2) *
//             event.height *
//             event.beta;
//         yield MomentCalculated(moment);
//       } else if (event is CalculateMastDesign) {
//         double mastDesignResult =
//             (event.moment * 1e6 * pow(event.thickness, 2)) / (3 * 210000);
//         yield MastDesignCalculated(mastDesignResult);
//       }
//     } catch (e) {
//       yield MastCalculationError(e.toString());
//     }
//   }
//
//   double _getForceCoefficient(int N, double Re) {
//     if (N >= 20) return 1.2;
//     if (N == 16) return 1.3;
//     if (N == 12) return 1.4;
//     if (N == 8) return 1.6;
//     return 2.0;
//   }
// }
//

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'mast_event.dart';
import 'mast_state.dart';

// Implement BLoC
class MastBloc extends Bloc<MastEvent, MastState> {
  MastBloc() : super(MastInitial()) {
    on<CalculateForceCoefficient>((event, emit) {
      double Re = (event.diameter * event.windSpeed) / 1.46e-5;
      double forceCoefficient = getForceCoefficient(event.numSides, Re);
      //double forceCoefficient = getForceCoefficient(event.numberOfSides, event.reynoldsNumber);
      emit(ForceCoefficientCalculated(forceCoefficient));
    });

    on<CalculateMoment>((event, emit) {
      double moment = calculateMoment(
          event.forceCoefficient, event.diameter, event.height, event.beta);
      emit(MomentCalculated(moment));
    });

    on<CalculateMastDesign>((event, emit) {
      double totalWeight = event.weight;
      double totalShear = event.shearForce;
      double deflection = event.deflection;
      emit(MastDesignCalculated(
        totalWeight: totalWeight,
        totalShear: totalShear,
        deflection: deflection,
      ));
    });
  }

  // Force coefficient logic
  double getForceCoefficient(int N, double Re) {
    if (N >= 20)
      return 1.2;
    else if (N == 16)
      return 1.3;
    else if (N == 12)
      return 1.4;
    else if (N == 8)
      return 1.6;
    else
      return 2.0;
  }

  double calculateMoment(
      double forceCoefficient, double diameter, double height, double beta) {
    // Example logic for calculating moment. Adjust it as per your original formula
    double q = 0.613 * height * height; // Example wind pressure formula
    return forceCoefficient * q * diameter * height * beta;
  }
}
