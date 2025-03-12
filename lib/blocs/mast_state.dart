abstract class MastState {}

class MastInitial extends MastState {}

class ForceCoefficientCalculated extends MastState {
  final double forceCoefficient;

  ForceCoefficientCalculated(this.forceCoefficient);
}

class MomentCalculated extends MastState {
  final double moment;

  MomentCalculated(this.moment);

  @override
  List<Object?> get props => [moment];
}

// class MomentCalculated extends MastState {
//   final double moment;
//
//   MomentCalculated(this.moment);
// }
class MastDesignCalculated extends MastState {
  final double totalWeight;
  final double totalShear;
  final double deflection;

  MastDesignCalculated({
    required this.totalWeight,
    required this.totalShear,
    required this.deflection,
  });

  @override
  List<Object?> get props => [totalWeight, totalShear, deflection];
}
// class MastDesignCalculated extends MastState {
//   final double mastDesignResult;
//
//   MastDesignCalculated(this.mastDesignResult);
// }

class MastCalculationError extends MastState {
  final String error;

  MastCalculationError(this.error);
}
