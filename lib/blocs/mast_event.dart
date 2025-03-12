// Define Events
import 'package:equatable/equatable.dart';

abstract class MastEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// class CalculateForceCoefficient extends MastEvent {
//   final double reynoldsNumber;
//   final int numberOfSides;
//
//   CalculateForceCoefficient({required this.reynoldsNumber, required this.numberOfSides});
//
//   @override
//   List<Object?> get props => [reynoldsNumber, numberOfSides];
// }

class CalculateForceCoefficient extends MastEvent {
  final double windSpeed;
  final double diameter;
  final int numSides;

  CalculateForceCoefficient({
    required this.windSpeed,
    required this.diameter,
    required this.numSides,
  });
}

class CalculateMoment extends MastEvent {
  final double forceCoefficient;
  final double diameter;
  final double height;
  final double beta;

  CalculateMoment({
    required this.forceCoefficient,
    required this.diameter,
    required this.height,
    required this.beta,
  });

  @override
  List<Object?> get props => [forceCoefficient, diameter, height, beta];
}

// class CalculateMoment extends MastEvent {
//   final double forceCoefficient;
//   final double height;
//   final double beta;
//   final double windSpeed;
//
//   CalculateMoment(
//       {required this.forceCoefficient,
//       required this.height,
//       required this.beta,
//       required this.windSpeed});
// }

class CalculateMastDesign extends MastEvent {
  final double moment;
  final double weight;
  final double shearForce;
  final double deflection;

  CalculateMastDesign({
    required this.moment,
    required this.weight,
    required this.shearForce,
    required this.deflection,
  });

  @override
  List<Object?> get props => [moment, weight, shearForce, deflection];
}

// class CalculateMastDesign extends MastEvent {
//   final double moment;
//   final double thickness;
//
//   CalculateMastDesign({
//     required this.moment,
//     required this.thickness,
//   });
// }
