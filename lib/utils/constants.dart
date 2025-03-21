//Constants
import 'dart:ffi';
import 'dart:math';

double KINEMATIC_VISCOSITY = 1.46e-5;
double SAFETY_FACTOR_LOAD_ULTIMATE = 1.25;
double SAFETY_FACTOR_MATERIAL_STEEL = 1.15;
double YOUNGS_MODULUS = 210000;
double STEEL_DENSITY = 7850;
double GRAVITY = 9.81;

class MastSection {
  double height;
  double baseDia;
  double thickness;
  double baseHeight;
  double center;
  double ulsLoad = 0.0;
  double slsLoad = 0.0;
  double ulsMoment = 0.0;
  double slsMoment = 0.0;
  double Mp = 0.0;
  double deflection = 0.0;
  double totalAxial = 0.0;
  double totalShear = 0.0;
  double peak_static_pressure = 0.0;
  double wind_force = 0.0;
  double cf = 0.0;

  MastSection({
    required this.height,
    required this.baseDia,
    required this.thickness,
    required this.baseHeight,
  }) : center = baseHeight + height / 2;
}

double uls_load = 0.0;
double sls_load = 0.0;
double uls_moment = 0.0;
double sls_moment = 0.0;
double Mp = 0.0;
double deflection = 0.0;
double total_axial = 0.0;
double total_shear = 0.0;
double peak_static_pressure = 0.0;
double wind_force = 0.0;

double calculateDesignWindSpeed(double vb, int mastType) {
  return mastType == 2 ? 22.0 : vb * 0.96;
}

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

double calculateWindLoadCF(double V, D_m, height, beta, N) {
  double q = 0.613 * V * pow(V, 2);
  double Re = (D_m * V) / KINEMATIC_VISCOSITY;
  double Cf = getForceCoefficient(N, Re);
  double delta = 1 - 0.1 * log(height);

  peak_static_pressure = beta * delta * q;
  wind_force = Cf * peak_static_pressure * height * D_m;

  return Cf;
  //Calculate and return peak equivalent static pressure and wind force separately
}

double calculateWindLoadWF(double V, D_m, height, beta, N) {
  double q = 0.613 * V * pow(V, 2);
  double Re = (D_m * V) / KINEMATIC_VISCOSITY;
  double Cf = getForceCoefficient(N, Re);
  double delta = 1 - 0.1 * log(height);

  peak_static_pressure = beta * delta * q;
  wind_force = Cf * peak_static_pressure * height * D_m;

  return wind_force;
  //Calculate and return peak equivalent static pressure and wind force separately
}

double calculateWindLoadPressure(double V, D_m, height, beta, N) {
  double q = 0.613 * V * pow(V, 2);
  double Re = (D_m * V) / KINEMATIC_VISCOSITY;
  double Cf = getForceCoefficient(N, Re);
  double delta = 1 - 0.1 * log(height);

  peak_static_pressure = beta * delta * q;
  wind_force = Cf * peak_static_pressure * height * D_m;

  return peak_static_pressure;
  //Calculate and return peak equivalent static pressure and wind force separately
}

List<MastSection> createTaperedSections(double totalHeight, double topDia,
    double bottomDia, List<double> thicknesses) {
  List<MastSection> sections = [];
  int numSections = thicknesses.length;
  double sectionHeight = totalHeight / numSections;

  for (int i = 0; i < numSections; i++) {
    double ratioTop = i / numSections;
    double ratioBottom = (i + 1) / numSections;
    double sectionTopDia = topDia - (topDia - bottomDia) * ratioTop;
    double sectionBottomDia = topDia - (topDia - bottomDia) * ratioBottom;
    double baseHeight = totalHeight - (i + 1) * sectionHeight;

    sections.add(MastSection(
      height: sectionHeight,
      baseDia: sectionBottomDia,
      thickness: thicknesses[i],
      baseHeight: baseHeight,
    ));
  }
  return sections;
}

// Function to calculate deflection
double calculateDeflection(
    double moment, double height, double D_mm, double t_mm) {
  double I = (pi / 64) * (pow(D_mm, 4) - pow(D_mm - 2 * t_mm, 4));
  return (moment * 1e6 * pow(height, 2)) / (3 * YOUNGS_MODULUS * I);
}

// Function to calculate section weight
double calculateSectionWeight(MastSection section) {
  double volume = (pi / 4) *
      ((pow(section.baseDia, 2) -
              pow(section.baseDia - 2 * section.thickness, 2)) /
          1e6) *
      section.height;
  return volume * STEEL_DENSITY * GRAVITY / 1000;
}

void execution() {
  // Example Input Data
  double totalHeight = 30.0;
  double topDia = 200.0;
  double bottomDia = 500.0;
  int N = 12;
  double fy = 355.0;
  double Vb = 25.0;
  double beta = 1.0;
  int mastType = 1;
  List<double> thicknesses = [10.0, 12.0, 15.0];
  int numLuminaries = 2;
  double luminaryWidth = 600.0;
  double luminaryHeight = 800.0;
  double luminaryProjectedArea =
      numLuminaries * (luminaryWidth / 1000) * (luminaryHeight / 1000);

  List<MastSection> sections =
      createTaperedSections(totalHeight, topDia, bottomDia, thicknesses);

//wind loads
  double V_uls = calculateDesignWindSpeed(Vb, 1);
  double V_sls =
      calculateDesignWindSpeed(Vb, mastType) * (mastType == 1 ? 0.2 : 1.0);
  double deltaLum = 1 - 0.1 * log(totalHeight);
  double qLumUls = 0.613 * pow(V_uls, 2);
  double qLumSls = 0.613 * pow(V_sls, 2);
  double peakStaticPressure = beta * deltaLum * qLumUls;
  double luminaryLoadSls =
      1.0 * beta * deltaLum * qLumUls * luminaryProjectedArea;
  double luminaryLoadUls = 1.0 * peakStaticPressure * luminaryProjectedArea;

//calculate section wind loads and mp
  for (var section in sections) {
    double D_m = section.baseDia / 1000;
    double windForceUls =
        calculateWindLoadWF(V_uls, D_m, section.height, beta, N);
    double peakStaticPressureUls =
        calculateWindLoadPressure(V_uls, D_m, section.height, beta, N);
    double cfUls = calculateWindLoadCF(V_uls, D_m, section.height, beta, N);

    double windForceSls =
        calculateWindLoadWF(V_sls, D_m, section.height, beta, N);
    double peakStaticPressureSls =
        calculateWindLoadPressure(V_sls, D_m, section.height, beta, N);
    double cfSls = calculateWindLoadCF(V_sls, D_m, section.height, beta, N);

    section.ulsLoad = windForceUls;
    section.slsLoad = windForceSls;

    section.peak_static_pressure = peakStaticPressureUls;
    section.wind_force = windForceUls;
    section.cf = cfUls;

    section.Mp = (fy *
            (pow(section.baseDia, 3) -
                pow(section.baseDia - 2 * section.thickness, 3))) /
        6e6;
  }

  //FOUNDATION MOMENT!!!!
  double foundationUlsMoment = sections.isNotEmpty ? sections[1].ulsMoment : 0;

  //axial and sheer forces

  double totalWeight = 0.0;
  double totalShearUls = luminaryLoadUls / 1000;
  for (var section in sections.reversed) {
    double sectionWeight = calculateSectionWeight(section);
    totalWeight += sectionWeight;
    section.totalAxial = totalWeight;
    totalShearUls += section.ulsLoad / 1000;
    section.totalShear = totalShearUls;
  }

  //deflections
  for (var section in sections) {
    section.deflection = calculateDeflection(
      section.slsMoment * 1000,
      section.height,
      section.baseDia,
      section.thickness,
    );
  }

  print("\n=== Mast Section Properties ===");
  print("\n=== Detailed Section Properties ===");
  for (int i = 0; i < sections.length; i++) {
    var section = sections[i];
    print("\nSection ${i + 1}:");
    print("  Height:                 ${section.height.toStringAsFixed(1)}m");
    print("  Base Diameter:          ${section.baseDia.toStringAsFixed(1)}mm");
    print(
        "  Thickness:              ${section.thickness.toStringAsFixed(1)}mm");
    print(
        "  Total Axial:            ${section.totalAxial.toStringAsFixed(1)}kN");
    print(
        "  Total Shear:            ${section.totalShear.toStringAsFixed(1)}kN");
    print(
        "  ULS Moment:             ${section.ulsMoment.toStringAsFixed(1)}kNm");
    print("  Moment Capacity:        ${section.Mp.toStringAsFixed(1)}kNm");
    print(
        "  Deflection:             ${section.deflection.toStringAsFixed(2)}mm");
    print(
        "  Peak Eq. Static Pressure: ${section.peak_static_pressure.toStringAsFixed(1)}N/m²");
    print(
        "  Wind Force:             ${section.wind_force.toStringAsFixed(1)}N");
    print("  Force Coefficient:      ${section.cf.toStringAsFixed(2)}");
  }

  print("\n=== Ultimate Limit State (ULS) Checks ===");
  for (int i = 0; i < sections.length; i++) {
    var section = sections[i];
    String result = (section.ulsMoment <= section.Mp) ? "PASS" : "FAIL";
    print(
        "Section ${i + 1}: ${section.ulsMoment.toStringAsFixed(1)}kNm ≤ ${section.Mp.toStringAsFixed(1)}kNm - $result");
  }

  print("\n=== Foundation Loads ===");
  print("Ultimate Moment: ${foundationUlsMoment.toStringAsFixed(1)}kNm");
  print("Ultimate Axial: ${sections[0].totalAxial.toStringAsFixed(1)}kN");
  print("Ultimate Shear: ${sections[0].totalShear.toStringAsFixed(1)}kN");

  // Natural frequency calculation
  double totalMass =
      sections.map((s) => calculateSectionWeight(s)).reduce((a, b) => a + b);
  double stiffness =
      sections.map((s) => s.Mp / s.deflection).reduce((a, b) => a + b);
  double n0 = 1 / (2 * pi) * sqrt(stiffness / totalMass);

  print(
      "\nNatural Frequency (n₀) of the Structure: ${n0.toStringAsFixed(2)} Hz");
  if (n0 < 1) {
    print(
        "Warning: Natural frequency is below the minimum requirement of 1 Hz");
  } else {
    print("PASS: Natural frequency meets the minimum requirement of 1 Hz");
  }
}

//
// def print_TR7_formula_summary():
// """Prints a summary of key formulas from the TR7 guidelines"""
// summary = """
//     ========== The Institution of Lighting Engineers
//                 Technical Report Number 7 Summary ==========
//
//     1. Design Wind Speed Calculation:
//        V = V_b × S_d × S_a × S_p
//        Where:
//        - V_b = Basic wind speed (m/s) from BS 6399-2
//        - S_d = Direction factor = 1.0
//        - S_a = Altitude factor = 1.0
//        - S_p = Probability factor = 0.96 (25-year return period)
//
//     2. Reference Pressure:
//        q_He = 0.613 × V² (N/m²)
//
//     3. Peak Equivalent Static Pressure:
//        E_qHe = β × δ × q_He
//        Where:
//        - β = Response factor ≈ (1 + 2g_m√(πS/(4ζ)))/(1 + 7I_v)
//        - δ = Size reduction factor = 1 - 0.1·ln(h) (10m ≤ h ≤ 60m)
//
//     4. Force Coefficient (C_f):
//        For Circular Masts:
//        ⎧ 1.2                      Re ≤ 2×10⁵
//        ⎪ 1.9 - 0.35·(Re×10⁻⁵)     2×10⁵ < Re ≤ 4×10⁵
//        C_f = ⎨ 0.433 + 0.0167·(Re×10⁻⁵)  4×10⁵ < Re ≤ 22×10⁵
//        ⎩ 0.8                      Re > 22×10⁵
//
//     5. Wind Force Calculation:
//        F_w = C_f × E_qHe × A
//        Where A = Projected area (height × diameter)
//
//     6. Ultimate Limit State (ULS):
//        - Design Load: F_design = F_w × γ_Q (γ_Q = 1.25)
//        - Material Strength: σ_design = σ_y/γ_m (γ_m = 1.15)
//
//     7. Moment Capacity Requirements:
//        For D/t ≤ (N·E)/(180σ_y):
//            M* = M_p/γ_m
//        For (N·E)/(180σ_y) < D/t ≤ 200:
//            M* = [M_p(0.9241·(90γ_mD/(N·E·t))⁻⁰·²²⁵⁸ - 0.1266)]/γ_m
//
//     8. Serviceability Limit State (SLS):
//        - Lighting Masts: Δ_max = h/40 @ 20% design wind speed
//        - CCTV Masts:
//          • Torsional rotation ≤ 0.0073 rad
//          • Linear deflection ≤ 150mm @ 22m/s
//
//     9. Natural Frequency Requirement:
//        n₀ = 1/(2π) × √(k/m) > 1 Hz
//        Where:
//        - k = Mast stiffness
//        - m = Distributed mass
//     ============================================================
