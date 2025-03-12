class MastData {
  final double forceCoefficient;
  final double moment;
  final double mastDesignResult;

  MastData({
    required this.forceCoefficient,
    required this.moment,
    required this.mastDesignResult,
  });

  MastData copyWith({
    double? forceCoefficient,
    double? moment,
    double? mastDesignResult,
  }) {
    return MastData(
      forceCoefficient: forceCoefficient ?? this.forceCoefficient,
      moment: moment ?? this.moment,
      mastDesignResult: mastDesignResult ?? this.mastDesignResult,
    );
  }
}
