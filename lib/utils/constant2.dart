import 'dart:math';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

import 'package:pdf/widgets.dart';

double KINEMATIC_VISCOSITY = 1.46e-5;
double SAFETY_FACTOR_LOAD_ULTIMATE = 1.25;
double SAFETY_FACTOR_MATERIAL_STEEL = 1.15;
double YOUNGS_MODULUS = 210000;
double STEEL_DENSITY = 7850;
double GRAVITY = 9.81;
var mess = new Runes('\u{21d2}');
var doubleArrow = new String.fromCharCodes(mess);
var mess2 = new Runes('\u{2192}');
var singleArrow = new String.fromCharCodes(mess);

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

class Test2 {
  Map<String, dynamic> getForceCoefficient(double Re, int N) {
    double Re_scaled = Re / 1e5; // Convert Re to units of 10⁵
    double Cf;
    String message;

    String cfReport = """
=========================================
            Drag Coefficient (C_f) Report            
=========================================

For Circular Masts:
0        < Re ≤ 2 × 10⁵               C_f = 1.2  
2 × 10⁵ < Re ≤ 4 × 10⁵               C_f = 1.9 - 0.35 × (Re × 10-⁵)  
4 × 10⁵ < Re ≤ 22 × 10⁵              C_f = 0.433 + 0.0167 × (Re × 10-⁵)  
22 × 10⁵ < Re                          C_f = 0.8  

For Octagonal Masts (8-sided):
0        < Re ≤ 2.3 × 10⁵             C_f = 1.45  
2.3 × 10⁵ < Re ≤ 3.0 × 10⁵           C_f = 1.943 - 0.2143 × (Re × 10-⁵)  
3.0 × 10⁵ < Re                        C_f = 1.3  

For Dodecagonal Masts (12-sided):
0        < Re ≤ 2 × 10⁵               C_f = 1.3  
2 × 10⁵ < Re ≤ 7 × 10⁵               C_f = 1.38 - 0.04 × (Re × 10-⁵)  
7 × 10⁵ < Re                          C_f = 1.1  

For Hexadecagonal Masts (16-sided):
0        < Re ≤ 2 × 10⁵               C_f = 1.25  
2 × 10⁵ < Re ≤ 6 × 10⁵               C_f = 1.475 - 0.1125 × (Re × 10-⁵)  
6 × 10⁵ < Re ≤ 14 × 10⁵              C_f = 0.725 + 0.0125 × (Re × 10-⁵)  
14 × 10⁵ < Re                         C_f = 0.9  

=========================================
""";

    if (N == 12) {
      // Dodecagonal (12-sided)
      if (Re <= 2e5) {
        Cf = 1.3;
        message = "Dodecagonal: Re ≤ 2×10⁵ = > C_f = 1.3";
      } else if (Re > 2e5 && Re <= 7e5) {
        Cf = 1.38 - 0.04 * Re_scaled;
        message =
            "Dodecagonal: 2×10⁵ < Re ≤7×10⁵ = > C_f = 1.38 - 0.04×${Re_scaled.toStringAsFixed(1)} = ${Cf.toStringAsFixed(2)}";
      } else {
        Cf = 1.1;
        message = "Dodecagonal: Re >7×10⁵ = > C_f = 1.1";
      }
    } else if (N == 16) {
      // Hexadecagonal (16-sided)
      if (Re <= 2e5) {
        Cf = 1.25;
        message = "Hexadecagonal: Re ≤2×10⁵ = > C_f = 1.25";
      } else if (Re > 2e5 && Re <= 6e5) {
        Cf = 1.475 - 0.1125 * Re_scaled;
        message =
            "Hexadecagonal: 2×10⁵ < Re ≤6×10⁵ = > C_f = 1.475 - 0.1125×${Re_scaled.toStringAsFixed(1)} = ${Cf.toStringAsFixed(2)}";
      } else if (Re > 6e5 && Re <= 14e5) {
        Cf = 0.725 + 0.0125 * Re_scaled;
        message =
            "Hexadecagonal: 6×10⁵ < Re ≤14×10⁵ = > C_f = 0.725 + 0.0125×${Re_scaled.toStringAsFixed(1)} = ${Cf.toStringAsFixed(2)}";
      } else {
        Cf = 0.9;
        message = "Hexadecagonal: Re >14×10⁵ = > C_f = 0.9";
      }
    } else if (N == 8) {
      // Octagonal (8-sided)
      if (Re <= 2.3e5) {
        Cf = 1.45;
        message = "Octagonal: Re ≤2.3×10⁵ = > C_f = 1.45";
      } else if (Re > 2.3e5 && Re <= 3e5) {
        Cf = 1.943 - 0.2143 * Re_scaled;
        message =
            "Octagonal: 2.3×10⁵ < Re ≤3×10⁵ = > C_f = 1.943 - 0.2143×${Re_scaled.toStringAsFixed(1)} = ${Cf.toStringAsFixed(2)}";
      } else {
        Cf = 1.3;
        message = "Octagonal: Re >3×10⁵ = > C_f = 1.3";
      }
    } else {
      // Circular (default case)
      if (Re <= 2e5) {
        Cf = 1.2;
        message = "Circular: Re ≤2×10⁵ = > C_f = 1.2";
      } else if (Re > 2e5 && Re <= 4e5) {
        //  Cf = 1.9 - 0.35 * (Re_scaled - 2);
        Cf = 1.9 - 0.35 * (Re_scaled);

        message =
            "Circular: 2×10⁵ < Re ≤4×10⁵ = > C_f = 1.9 - 0.35×(Re/10⁵ - 2) = ${Cf.toStringAsFixed(2)}";
      } else if (Re > 4e5 && Re <= 22e5) {
        Cf = 0.433 + 0.0167 * Re_scaled;
        message =
            "Circular: 4×10⁵ < Re ≤22×10⁵ = > C_f = 0.433 + 0.0167×${Re_scaled.toStringAsFixed(1)} = ${Cf.toStringAsFixed(2)}";
      } else {
        Cf = 0.8;
        message = "Circular: Re >22×10⁵ = > C_f = 0.8";
      }
    }

    return {'Cf': Cf, 'message': message};
  }

  Map<String, dynamic> calculateDelta(double height) {
    double delta = 1 - 0.1 * log(height);
    String message =
        "δ = 1 - 0.1·ln(h) = 1 - 0.1·ln(${height.toStringAsFixed(1)}) = ${delta.toStringAsFixed(3)}";

    return {'delta': delta, 'message': message};
  }

  double calculateResponseFactor(double totalHeight, int materialChoice,
      int terrainChoice, double basicWindSpeed) {
    // Define gust factors, B values, and damping constants based on terrain and material choice
    double gustFactor = {1: 1.85, 2: 1.7, 3: 1.6}[terrainChoice] ?? 1.7;
    double B = {1: 0.3, 2: 0.2, 3: 0.15}[terrainChoice] ?? 0.2;
    double zeta = {1: 0.01, 2: 0.03}[materialChoice] ?? 0.02;

    // Natural frequency calculation
    double fn = 46 / totalHeight;

    // Response factor (beta) calculation
    double beta = sqrt(1 + (2 * zeta / pi) * (B / fn) * log(3600 / B));

    // Print the calculation report
    print("\n===== RESPONSE FACTOR CALCULATION =====");
    print(
        "Natural Frequency n₀ = 46/h = 46/$totalHeight = ${fn.toStringAsFixed(2)}Hz");
    print("Turbulence Intensity I_v = $B");
    print("Structural Damping ζ = $zeta");
    print("β = √[1 + (2ζ/π)(I_v/n₀)ln(3600/I_v)]");
    print("   = √[1 + (2×$zeta/π)(${B}/${fn.toStringAsFixed(2)})ln(3600/$B)]");
    print("   = ${beta.toStringAsFixed(3)}");
    print("=" * 40);

    return beta;
  }

  double calculateDesignWindSpeed(double vb, int mastType) {
    return mastType == 2 ? 22.0 : vb * 0.96;
  }

  Map<String, dynamic> calculateSectionProperties(
      MastSection section, double fy, int N, int sectionNum) {
    double D = section.baseDia;
    double t = section.thickness;

    List<String> calcReport = [
      "\n===== SECTION $sectionNum PROPERTIES =====",
      "Location: ${section.baseHeight.toStringAsFixed(1)}m - ${(section.baseHeight + section.height).toStringAsFixed(1)}m",
      "Diameter: ${D}mm, Thickness: ${t}mm"
    ];

    // Cross-sectional Area
    double A = (pi / 4) * (pow(D, 2) - pow(D - 2 * t, 2));
    calcReport.add(
        "Cross-sectional Area = π/4×(${D}² - ${(D - 2 * t).toStringAsFixed(0)}²) = ${A.toStringAsFixed(1)} mm²");

    // Moment of Inertia
    double I = (pi / 64) * (pow(D, 4) - pow(D - 2 * t, 4));
    calcReport.add(
        "Moment of Inertia = π/64×(${D}⁴ - ${(D - 2 * t).toStringAsFixed(0)}⁴) = ${I.toStringAsFixed(2)} mm⁴");

    // Plastic Modulus
    double Zp = (pow(D, 3) - pow(D - 2 * t, 3)) / 6;
    calcReport.add(
        "Plastic Modulus = (D³ - (D-2t)³)/6 = ${Zp.toStringAsFixed(1)} mm³");

    calcReport.add("=" * 40);

    // Print the report
    print(calcReport.join("\n"));

    // Return the properties
    return {
      "A": A,
      "I": I,
      "Zp": Zp,
    };
  }

  Map<String, dynamic> calculateWindLoad(
      double V,
      double D_m,
      double sectionHeight,
      double totalHeight,
      double beta,
      int N,
      int sectionNum) {
    double q = 0.613 * pow(V, 2);
    double Re = (D_m * V) / KINEMATIC_VISCOSITY;
    print("getting coefficient");
    var forceCoeffResult = getForceCoefficient(Re, N);
    double Cf = forceCoeffResult['Cf'];
    String cfDesc = forceCoeffResult['message'];
    print("cf " + Cf.toString());
    print("cf desc" + cfDesc.toString());

    print("getting delta");

    var deltaResult = calculateDelta(totalHeight);
    double delta = deltaResult['delta'];
    String deltaDesc = deltaResult['message'];

    print("delta " + delta.toString());
    print("delta desc" + deltaDesc.toString());

    double peakStaticPressure = beta * delta * q;
    double windForce = Cf * peakStaticPressure * sectionHeight * D_m;

    String calcReport = """
\n===== SECTION $sectionNum WIND LOAD CALCULATION =====
1. Reynolds Number: Re = (D·V)/ν = (${D_m.toStringAsFixed(3)}m × ${V.toStringAsFixed(1)}m/s)/$KINEMATIC_VISCOSITY = ${Re.toStringAsFixed(1)}
   $cfDesc
2. Size Reduction: $deltaDesc
3. Reference Pressure: q = 0.613V² = 0.613×${V.toStringAsFixed(1)}² = ${q.toStringAsFixed(1)} N/m²
4. Peak Pressure: E_qHe = β·δ·q = ${beta.toStringAsFixed(3)}×${delta.toStringAsFixed(3)}×${q.toStringAsFixed(1)} = ${peakStaticPressure.toStringAsFixed(1)} N/m²
5. Wind Force: F_w = C_f·E_qHe·A = ${Cf.toStringAsFixed(2)}×${peakStaticPressure.toStringAsFixed(1)}×(${sectionHeight.toStringAsFixed(1)}m×${D_m.toStringAsFixed(3)}m) = ${windForce.toStringAsFixed(1)}N
========================================
""";

    print(calcReport);
    return {
      'windForce': windForce,
      'peakStaticPressure': peakStaticPressure,
      'Cf': Cf,
      'report': calcReport
    };
  }

  Map<String, dynamic> calculateMp(
      double fy, double D, double t, int N, int sectionNum) {
    double D_t = D / t;
    double threshold = (N * YOUNGS_MODULUS) / (180 * fy);

    List<String> calcSteps = [
      "\n===== SECTION $sectionNum MOMENT CAPACITY ANALYSIS =====",
      "Diameter: ${D.toStringAsFixed(1)}mm, Thickness: ${t.toStringAsFixed(1)}mm",
      "D/t = ${D.toStringAsFixed(1)}/${t.toStringAsFixed(1)} = ${D_t.toStringAsFixed(1)}",
      "Threshold = (N·E)/(180·σy) = ($N×$YOUNGS_MODULUS)/(180×${fy.toStringAsFixed(1)}) = ${threshold.toStringAsFixed(1)}"
    ];

    double Mp;
    if (D_t <= threshold) {
      Mp = (fy * (pow(D, 3) - pow(D - 2 * t, 3))) / 6e6;
      calcSteps.add("D/t ≤ threshold -> Full plastic moment capacity: "
          "Mp = σy·(D³ - (D-2t)³)/6e6 = ${fy.toStringAsFixed(1)}·(${D.toStringAsFixed(1)}³ - ${(D - 2 * t).toStringAsFixed(1)}³)/6e6 = ${Mp.toStringAsFixed(1)} kNm");
    } else {
      // double term = 0.9241 *
      //     pow(
      //         (90 * SAFETY_FACTOR_MATERIAL_STEEL * D) /
      //             (N * YOUNGS_MODULUS * t),
      //         -0.2258);
      double term =
          0.9241 * pow((90 * fy * D) / (N * YOUNGS_MODULUS * t), -0.2258);
      double reductionFactor = term - 0.1266;
      double MpFull = (fy * (pow(D, 3) - pow(D - 2 * t, 3))) / 6e6;
      Mp = (MpFull * reductionFactor) / SAFETY_FACTOR_MATERIAL_STEEL;
//If D/T > threshold ,use reduce moment capaaacity else full mp
//       calcSteps.addAll([
//         "D/t > threshold -> Reduced capacity:",
//         "Reduction Factor = 0.9241·(90γ_mD/(N·E·t))^−0.2258 - 0.1266",
//         "   = 0.9241·(90×$SAFETY_FACTOR_MATERIAL_STEEL×${D.toStringAsFixed(1)}/"
//             "($N×$YOUNGS_MODULUS×${t.toStringAsFixed(1)}))^−0.2258 - 0.1266 = ${reductionFactor.toStringAsFixed(3)}",
//         "Full Mp = ${MpFull.toStringAsFixed(1)} kNm",
//         "Reduced Mp = (${MpFull.toStringAsFixed(1)} × ${reductionFactor.toStringAsFixed(3)}) / $SAFETY_FACTOR_MATERIAL_STEEL = ${Mp.toStringAsFixed(1)} kNm"
//       ]);
      calcSteps.addAll([
        "D/t > threshold -> Reduced capacity:",
        "Reduction Factor = 0.9241·(90γ_mD/(N·E·t))^−0.2258 - 0.1266",
        "   = 0.9241·(90×$fy×${D.toStringAsFixed(1)}/"
            "($N×$YOUNGS_MODULUS×${t.toStringAsFixed(1)}))^−0.2258 - 0.1266 = ${reductionFactor.toStringAsFixed(3)}",
        "Full Mp = ${MpFull.toStringAsFixed(1)} kNm",
        "Reduced Mp = (${MpFull.toStringAsFixed(1)} × ${reductionFactor.toStringAsFixed(3)}) / $SAFETY_FACTOR_MATERIAL_STEEL = ${Mp.toStringAsFixed(1)} kNm"
      ]);
    }

    calcSteps.add("=" * 40);

    return {'Mp': Mp, 'report': calcSteps.join("\n")};
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

  Map<String, dynamic> calculateDeflection(double momentNmm, double heightM,
      double Dmm, double tMm, int sectionNum) {
    print("calculating deflections");
    double heightMm = heightM * 1000;
    print("height :$heightMm");
    double I = (pi / 64) * (pow(Dmm, 4) - pow(Dmm - 2 * tMm, 4));
    print("I :$I");
    double deflection =
        (momentNmm * pow(heightMm, 2)) / (3 * YOUNGS_MODULUS * I);
    print("deflection : $deflection");

    List<String> calcReport = [
      "\n===== SECTION $sectionNum DEFLECTION CALCULATION =====",
      "Moment = ${(momentNmm / 1e6).toStringAsFixed(1)} kNm",
      "Height = ${heightMm.toStringAsFixed(1)} mm",
      "Second Moment of Area I = π/64 × (D⁴ - (D-2t)⁴) = ${I.toStringAsExponential(2)} mm⁴",
      "Deflection = (M·h²) / (3·E·I) = "
          "(${momentNmm.toStringAsFixed(0)} × ${heightMm.toStringAsFixed(0)}²) / "
          "(3 × ${YOUNGS_MODULUS.toStringAsFixed(0)} × ${I.toStringAsExponential(2)}) "
          "= ${deflection.toStringAsFixed(2)} mm",
      "=" * 40
    ];

    return {"deflection": deflection, "report": calcReport.join("\n")};
  }

  Map<String, dynamic> calculateSectionWeight(
      MastSection section, int sectionNum) {
    double Dm = section.baseDia / 1000; // Convert to meters
    double tm = section.thickness / 1000; // Convert to meters
    double volume =
        (pi / 4) * (pow(Dm, 2) - pow(Dm - 2 * tm, 2)) * section.height;
    double weight = volume * STEEL_DENSITY * GRAVITY;

    List<String> calcReport = [
      "\n===== SECTION $sectionNum WEIGHT CALCULATION =====",
      "Volume = π/4 × (${Dm.toStringAsFixed(3)}² - ${(Dm - 2 * tm).toStringAsFixed(3)}²) × ${section.height}m = ${volume.toStringAsFixed(4)} m³",
      "Weight = ${volume.toStringAsFixed(4)} × $STEEL_DENSITY kg/m³ × $GRAVITY m/s² = ${(weight / 1000).toStringAsFixed(1)} kN",
      "=" * 40
    ];

    return {
      "weight": weight / 1000, // Convert weight to kN
      "report": calcReport.join("\n")
    };
  }

  double calculateSectionWeight2(MastSection section, int sectionNum) {
    double D_m = section.baseDia / 1000;
    double t_m = section.thickness / 1000;
    double volume =
        (pi / 4) * (pow(D_m, 2) - pow(D_m - 2 * t_m, 2)) * section.height;
    double weight = volume * STEEL_DENSITY * GRAVITY;

    return weight / 1000; // Return weight in kN
  }

  Map<String, dynamic> sectionAnalysis(List<MastSection> sections, double V_uls,
      double totalHeight, double beta, int N, double fy) {
    List<String> windReports = []; // Store all wind reports
    List<String> mpReports = []; // Store all Mp reports

    for (int sectionNum = 0; sectionNum < sections.length; sectionNum++) {
      MastSection section = sections[sectionNum];

      double D_m = section.baseDia / 1000;

      // Wind load calculation
      var windLoadResult = calculateWindLoad(
          V_uls, D_m, section.height, totalHeight, beta, N, sectionNum + 1);
      double windForceUls = windLoadResult["windForce"];
      String windReport = windLoadResult["report"] ?? "";
      print("test test windforce: $windForceUls");
      section.ulsLoad = windForceUls;
      windReports.add("Section ${sectionNum + 1}:\n$windReport\n");

      // Mp calculation
      var mpResult = calculateMp(
          fy, section.baseDia, section.thickness, N, sectionNum + 1);
      double Mp = mpResult["Mp"];
      String mpReport = mpResult["report"] ?? "";
      print("moment result here: $Mp");
      print(mpReport);

      section.Mp = Mp;
      mpReports.add("Section ${sectionNum + 1}:\n$mpReport\n");

      // Section properties calculation
      calculateSectionProperties(section, fy, N, sectionNum + 1);
    }

    // Returning combined reports
    return {
      "windreport": windReports.join("\n"), // Combine all wind reports
      "mpreport": mpReports.join("\n"), // Combine all Mp reports
    };
  }

  // Map<String, dynamic> sectionAnalysis(List<MastSection> sections, double V_uls,
  //     double totalHeight, double beta, int N, double fy) {
  //   var mpReport;
  //   var windReport;
  //   for (int sectionNum = 0; sectionNum < sections.length; sectionNum++) {
  //     MastSection section = sections[sectionNum];
  //
  //     double D_m = section.baseDia / 1000;
  //
  //     // Wind load calculation (assuming calculateWindLoad is defined)
  //     var windLoadResult = calculateWindLoad(
  //         V_uls, D_m, section.height, totalHeight, beta, N, sectionNum + 1);
  //     double windForceUls = windLoadResult["windForce"]; // Wind load ULS
  //     windReport = windLoadResult["report"] ?? ""; // Wind report text
  //
  //     print("wind load execute!!!");
  //     print("---reults----------  forceuls : $windForceUls ");
  //     print("---reults----------  report : $windReport ");
  //
  //     section.ulsLoad = windForceUls;
  //
  //     // Mp calculation (assuming calculateMp is defined)
  //     var mpResult = calculateMp(
  //         fy, section.baseDia, section.thickness, N, sectionNum + 1);
  //     double Mp = mpResult["Mp"]; // Moment capacity
  //     mpReport = mpResult["report"]; // Mp report text
  //     print("mp  report : $mpReport ");
  //     // Section properties calculation (assuming calculateSectionProperties is defined)
  //     calculateSectionProperties(section, fy, N, sectionNum + 1);
  //
  //     // Print the reports for wind load and moment capacity
  //     print("wind report");
  //     print(windReport);
  //     print("mp report");
  //     print(mpReport);
  //   }
  //   return {"mpreport": mpReport, "windreport": windReport};
  // }

  String ulsChecksSummary(List<MastSection> sections) {
    StringBuffer report = StringBuffer("\n===== ULS CHECKS SUMMARY =====\n");
    print("\n===== ULS CHECKS SUMMARY =====");

    for (int sectionNum = 0; sectionNum < sections.length; sectionNum++) {
      MastSection section = sections[sectionNum];

      // Check if ULS moment is within the capacity
      String status = section.ulsMoment <= section.Mp ? "PASS" : "FAIL";

      // Calculate utilization
      double utilization = (section.ulsMoment / section.Mp) * 100;
      report.writeln("Section ${sectionNum + 1}:");
      report.writeln(
          "Applied Moment: ${section.ulsMoment.toStringAsFixed(1)} kNm");
      report.writeln("Moment Capacity: ${section.Mp.toStringAsFixed(1)} kNm");
      report.writeln("Utilization: ${utilization.toStringAsFixed(1)}%");
      report.writeln("Status: $status");
      report.writeln("-" * 40);

      print("Section ${sectionNum + 1}:");
      print("Applied Moment: ${section.ulsMoment.toStringAsFixed(1)} kNm");
      print("Moment Capacity: ${section.Mp.toStringAsFixed(1)} kNm");
      print("Utilization: ${utilization.toStringAsFixed(1)}%");
      print("Status: $status");
      print("-" * 40);
    }
    return report.toString();
  }

  Map<String, dynamic> calculateSectionLoads3(
      List<MastSection> sections,
      double luminaryLoadUls,
      double luminaryLoadSls,
      double equipmentWeight,
      double totalHeight) {
    StringBuffer report = StringBuffer();

    report.writeln("\n===== LOAD CALCULATION PROCESS =====");
    // print("\n===== LOAD CALCULATION PROCESS =====");

    double totalShearUls = luminaryLoadUls / 1000;
    double totalShearSls = luminaryLoadSls / 1000;
    double totalWeight = 0.0;
    //for (int idx = 0; idx < sections.length; idx++) {
    for (int idx = sections.length - 1; idx >= 0; idx--) {
      //int sectionNum = sections.length - idx;
      int sectionNum = idx + 1;
      report.writeln("\n===== SECTION $sectionNum LOAD ANALYSIS =====");
      // print("\n===== SECTION $sectionNum LOAD ANALYSIS =====");

      // Axial Load
      double weight = calculateSectionWeight2(sections[idx], sectionNum);
      totalWeight += weight;

      if (idx == sections.length - 1) {
        // Top section
        double luminaryWeight = equipmentWeight * GRAVITY / 1000;
        totalWeight += luminaryWeight;
        report.writeln(
            "+ Luminary weight: ${luminaryWeight.toStringAsFixed(1)} kN");
        // print("+ Luminary weight: ${luminaryWeight.toStringAsFixed(1)} kN");
      }

      sections[idx].totalAxial = totalWeight;
      report.writeln("Weight report: ${weight.toStringAsFixed(1)} kN");
      //print("Weight report: ${weight.toStringAsFixed(1)} kN");

      // Shear Force
      double sectionShearUls = sections[idx].ulsLoad / 1000;
      totalShearUls += sectionShearUls;
      sections[idx].totalShear = totalShearUls;

      report.writeln("\n----- Shear Forces -----");
      report.writeln(
          "Section Wind Shear: ${sectionShearUls.toStringAsFixed(1)} kN");
      report
          .writeln("Cumulative Shear: ${totalShearUls.toStringAsFixed(1)} kN");

      // print("\n----- Shear Forces -----");
      // print("Section Wind Shear: ${sectionShearUls.toStringAsFixed(1)} kN");
      // print("Cumulative Shear: ${totalShearUls.toStringAsFixed(1)} kN");

      // Moment Calculation
      double ulsMoment =
          luminaryLoadUls * (totalHeight - sections[idx].baseHeight);
      double slsMoment =
          luminaryLoadSls * (totalHeight - sections[idx].baseHeight);

      // for (int j = 0; j < sections.length - idx; j++) {
      //   double leverArm = sections[j].baseHeight - sections[idx].baseHeight;
      //   ulsMoment += sections[j].ulsLoad * leverArm;
      //   slsMoment += sections[j].slsLoad * leverArm;
      //
      //   print("Lever Arm: $leverArm, Section ULS Load: ${sections[j].ulsLoad}");
      // }
      for (int j = idx; j < sections.length; j++) {
        // Fix: Loop from idx to last section
        double leverArm =
            sections[j].center - sections[idx].baseHeight; // Fix: Use center
        ulsMoment += sections[j].ulsLoad * leverArm;
        slsMoment += sections[j].slsLoad * leverArm;
      }

      sections[idx].ulsMoment = ulsMoment / 1000;
      sections[idx].slsMoment = slsMoment / 1000;

      // Corrected moment display
      double luminaryContribution =
          (luminaryLoadUls / 1000) * (totalHeight - sections[idx].baseHeight);
      // double windContribution = sections[idx].ulsMoment - luminaryContribution;
      double windContribution = (ulsMoment / 1000) - luminaryContribution;

      report.writeln("\n----- Moments -----");
      report.writeln(
          "Luminary Moment: (${(luminaryLoadUls / 1000).toStringAsFixed(1)} kN × ${(totalHeight - sections[idx].baseHeight).toStringAsFixed(1)} m) = ${luminaryContribution.toStringAsFixed(1)} kNm");
      report.writeln(
          "Wind Load Moments: ${windContribution.toStringAsFixed(1)} kNm");
      report.writeln(
          "Total Section Moment: ${sections[idx].ulsMoment.toStringAsFixed(1)} kNm");
      report.writeln("=" * 40);

      print("\n----- Moments -----");
      print(
          "Luminary Moment: (${luminaryLoadUls / 1000}kN × ${(totalHeight - sections[idx].baseHeight).toStringAsFixed(1)}m) = ${luminaryContribution.toStringAsFixed(1)}kNm");
      print("Wind Load Moments: ${windContribution.toStringAsFixed(1)}kNm");
      print(
          "Total Section Moment: ${sections[idx].ulsMoment.toStringAsFixed(1)}kNm");
      print("=" * 40);
    }

    // Foundation reactions
    double foundationUlsMoment = sections.last.ulsMoment;
    double foundationAxial = sections.last.totalAxial;
    double foundationShear = sections.last.totalShear;

    report.writeln("\n===== FINAL FOUNDATION REACTIONS =====");
    report.writeln("Moment: ${foundationUlsMoment.toStringAsFixed(1)} kNm");
    report.writeln("Axial:  ${foundationAxial.toStringAsFixed(1)} kN");
    report.writeln("Shear:  ${foundationShear.toStringAsFixed(1)} kN");
    report.writeln("=" * 40);

    // print("\n===== FINAL FOUNDATION REACTIONS =====");
    // print("Moment: ${foundationUlsMoment.toStringAsFixed(1)} kNm");
    // print("Axial:  ${foundationAxial.toStringAsFixed(1)} kN");
    // print("Shear:  ${foundationShear.toStringAsFixed(1)} kN");
    // print("=" * 40);

    print("section x repo: ----$report");
    print("finished!!!");

    return {
      "foundationUlsMoment": foundationUlsMoment,
      "foundationAxial": foundationAxial,
      "foundationShear": foundationShear,
      "report": report.toString(),
    };
  }

  Map<String, dynamic> calculateSectionLoads(
      List<MastSection> sections,
      double luminaryLoadUls,
      double luminaryLoadSls,
      double equipmentWeight,
      double totalHeight) {
    StringBuffer report = StringBuffer();

    report.writeln("\n===== LOAD CALCULATION PROCESS =====");

    double totalShearUls = luminaryLoadUls / 1000;
    double totalShearSls = luminaryLoadSls / 1000;
    double totalWeight = 0.0;

    for (int idx = sections.length - 1; idx >= 0; idx--) {
      int sectionNum = idx + 1;
      report.writeln("\n===== SECTION $sectionNum LOAD ANALYSIS =====");

      // Axial Load
      double weight = calculateSectionWeight2(sections[idx], sectionNum);
      print("calculated section weight $weight kgz");
      totalWeight += weight;
      print("total weight now $totalWeight kgz");
      if (idx == 0) {
        // Top section
        double luminaryWeight = equipmentWeight * GRAVITY / 1000;
        print("calculated luminary weight $luminaryWeight kgz");
        totalWeight += luminaryWeight;
        print("total weight now post luminary $totalWeight kgz");
        report.writeln(
            "+ Luminary weight: ${luminaryWeight.toStringAsFixed(1)} kN");
      }

      sections[idx].totalAxial = totalWeight;
      report.writeln("Weight report: ${weight.toStringAsFixed(1)} kN");

      // Shear Force
      double sectionShearUls = sections[idx].ulsLoad / 1000;
      totalShearUls += sectionShearUls;
      sections[idx].totalShear = totalShearUls;

      report.writeln("\n----- Shear Forces -----");
      report.writeln(
          "Section Wind Shear: ${sectionShearUls.toStringAsFixed(1)} kN");
      report
          .writeln("Cumulative Shear: ${totalShearUls.toStringAsFixed(1)} kN");

      print("\n----- Shear Forces -----");
      print("Section Wind Shear: ${sectionShearUls.toStringAsFixed(1)} kN");
      print("Cumulative Shear: ${totalShearUls.toStringAsFixed(1)} kN");

      // Moment Calculation
      double ulsMoment =
          luminaryLoadUls * (totalHeight - sections[idx].baseHeight);
      double slsMoment =
          luminaryLoadSls * (totalHeight - sections[idx].baseHeight);

      print("calculated ulsm: ${ulsMoment.toStringAsFixed(1)} ");
      print("calculated slsm: ${slsMoment.toStringAsFixed(1)} ");

      // for (int j = sections.length - 1; j >= idx; j--) {
      //   double leverArm = sections[j].baseHeight - sections[idx].baseHeight;
      //   ulsMoment += sections[j].ulsLoad * leverArm;
      //   slsMoment += sections[j].slsLoad * leverArm;
      // }
      // for (int j = 0; j < sections.length - idx; j++) {
      //   double leverArm = sections[j].center - sections[idx].baseHeight;
      //   print(
      //       "leverArm ${leverArm} = sections[j].center ${sections[j].center} - sections[idx].baseHeight ${sections[idx].baseHeight}");
      //   ulsMoment += sections[j].ulsLoad * leverArm;
      //   print(
      //       "uls moment $ulsMoment for j = $j from sections[j].ulsLoad ${sections[j].ulsLoad} * leverArm $leverArm;");
      //   slsMoment += sections[j].slsLoad * leverArm;
      //   print(
      //       "sls moment $slsMoment for j = $j from sections[j].slsLoad ${sections[j].slsLoad} * leverArm $leverArm;");
      // }

      for (int j = 0; j < sections.length - idx; j++) {
        double leverArm = sections[j].center;
        //- sections[idx].baseHeight;
        print(
            "leverArm ${leverArm} = sections[j].center ${sections[j].center} - sections[idx].baseHeight ${sections[idx].baseHeight}");

        ulsMoment += sections[j].ulsLoad * leverArm;
        print(
            "uls moment $ulsMoment for j = $j from sections[j].ulsLoad ${sections[j].ulsLoad} * leverArm $leverArm;");

        slsMoment += sections[j].slsLoad * leverArm;
        print(
            "sls moment $slsMoment for j = $j from sections[j].slsLoad ${sections[j].slsLoad} * leverArm $leverArm;");
      }

      sections[idx].ulsMoment = ulsMoment / 1000;
      sections[idx].slsMoment = slsMoment / 1000;

      // Corrected moment display
      double luminaryContribution =
          (luminaryLoadUls / 1000) * (totalHeight - sections[idx].baseHeight);
      print(
          "LumContr=${luminaryContribution}===>(luminaryLoadUls = $luminaryLoadUls / 1000)  * (totalHeight ($totalHeight)- sections[idx].baseHeight={${sections[idx].baseHeight})");
      double windContribution = sections[idx].ulsMoment - luminaryContribution;
      print(
          "windContribution= ${windContribution} = sections[idx].ulsMoment (${sections[idx].ulsMoment}) - luminaryContribution ($luminaryContribution);");
      report.writeln("\n----- Moments -----");
      report.writeln(
          "Luminary Moment: (${(luminaryLoadUls / 1000).toStringAsFixed(1)} kN × ${(totalHeight - sections[idx].baseHeight).toStringAsFixed(1)} m) = ${luminaryContribution.toStringAsFixed(1)} kNm");
      report.writeln(
          "Wind Load Moments: ${windContribution.toStringAsFixed(1)} kNm");
      report.writeln(
          "Total Section Moment: ${sections[idx].ulsMoment.toStringAsFixed(1)} kNm");
      report.writeln("=" * 40);
      print("\n----- Moments -----");
      print(
          "Luminary Moment: (${luminaryLoadUls / 1000}kN × ${(totalHeight - sections[idx].baseHeight).toStringAsFixed(1)}m) = ${luminaryContribution.toStringAsFixed(1)}kNm");
      print("Wind Load Moments: ${windContribution.toStringAsFixed(1)}kNm");
      print(
          "Total Section Moment: ${sections[idx].ulsMoment.toStringAsFixed(1)}kNm");
      print("=" * 40);
    }

    // Foundation reactions
    double foundationUlsMoment = sections.first.ulsMoment;
    double foundationAxial = sections.first.totalAxial;
    double foundationShear = sections.first.totalShear;

    report.writeln("\n===== FINAL FOUNDATION REACTIONS =====");
    report.writeln("Moment: ${foundationUlsMoment.toStringAsFixed(1)} kNm");
    report.writeln("Axial:  ${foundationAxial.toStringAsFixed(1)} kN");
    report.writeln("Shear:  ${foundationShear.toStringAsFixed(1)} kN");
    report.writeln("=" * 40);

    return {
      "foundationUlsMoment": foundationUlsMoment,
      "foundationAxial": foundationAxial,
      "foundationShear": foundationShear,
      "report": report.toString(),
    };
  }

  Map<String, dynamic> calculateSectionLoads2(
      List<MastSection> sections,
      double luminaryLoadUls,
      double luminaryLoadSls,
      double equipmentWeight,
      double totalHeight) {
    StringBuffer report = StringBuffer();
    report.writeln("\n===== LOAD CALCULATION PROCESS =====");

    double totalShearUls = luminaryLoadUls / 1000;
    double totalShearSls = luminaryLoadSls / 1000;
    double totalWeight = 0.0;

    // Loop in **reverse** order to match Python logic
    for (int idx = sections.length - 1; idx >= 0; idx--) {
      int sectionNum = idx + 1;
      report.writeln("\n===== SECTION $sectionNum LOAD ANALYSIS =====");

      // Axial Load Calculation
      double weight = calculateSectionWeight2(sections[idx], sectionNum);
      totalWeight += weight;

      if (idx == sections.length - 1) {
        // Top section
        double luminaryWeight = (equipmentWeight * GRAVITY) / 1000;
        totalWeight += luminaryWeight;
        report.writeln(
            "+ Luminary weight: ${luminaryWeight.toStringAsFixed(1)} kN");
      }

      sections[idx].totalAxial = totalWeight;
      report.writeln("Weight report: ${weight.toStringAsFixed(1)} kN");

      // Shear Force Calculation
      double sectionShearUls = sections[idx].ulsLoad / 1000;
      totalShearUls += sectionShearUls;
      sections[idx].totalShear = totalShearUls;

      report.writeln("\n----- Shear Forces -----");
      report.writeln(
          "Section Wind Shear: ${sectionShearUls.toStringAsFixed(1)} kN");
      report
          .writeln("Cumulative Shear: ${totalShearUls.toStringAsFixed(1)} kN");

      // Moment Calculation
      double ulsMoment =
          luminaryLoadUls * (totalHeight - sections[idx].baseHeight);
      double slsMoment =
          luminaryLoadSls * (totalHeight - sections[idx].baseHeight);

      // Fix: Accumulate wind moments in the correct order
      for (int j = idx; j < sections.length; j++) {
        double leverArm = sections[j].center - sections[idx].baseHeight;
        ulsMoment += sections[j].ulsLoad * leverArm;
        slsMoment += sections[j].slsLoad * leverArm;
      }

      sections[idx].ulsMoment = ulsMoment / 1000;
      sections[idx].slsMoment = slsMoment / 1000;

      // Fix: Correct Wind Contribution Calculation
      double luminaryContribution =
          (luminaryLoadUls / 1000) * (totalHeight - sections[idx].baseHeight);
      double windContribution =
          (sections[idx].ulsMoment / 1000) - luminaryContribution;

      report.writeln("\n----- Moments -----");
      report.writeln(
          "Luminary Moment: (${(luminaryLoadUls / 1000).toStringAsFixed(1)} kN × ${(totalHeight - sections[idx].baseHeight).toStringAsFixed(1)} m) = ${luminaryContribution.toStringAsFixed(1)} kNm");
      report.writeln(
          "Wind Load Moments: ${windContribution.toStringAsFixed(1)} kNm");
      report.writeln(
          "Total Section Moment: ${sections[idx].ulsMoment.toStringAsFixed(1)} kNm");
      report.writeln("=" * 40);
      print("\n----- Moments -----");
      print(
          "Luminary Moment: (${luminaryLoadUls / 1000}kN × ${(totalHeight - sections[idx].baseHeight).toStringAsFixed(1)}m) = ${luminaryContribution.toStringAsFixed(1)}kNm");
      print("Wind Load Moments: ${windContribution.toStringAsFixed(1)}kNm");
      print(
          "Total Section Moment: ${sections[idx].ulsMoment.toStringAsFixed(1)}kNm");
      print("=" * 40);
    }

    // Foundation reactions
    double foundationUlsMoment = sections.first.ulsMoment;
    double foundationAxial = sections.first.totalAxial;
    double foundationShear = sections.first.totalShear;

    report.writeln("\n===== FINAL FOUNDATION REACTIONS =====");
    report.writeln("Moment: ${foundationUlsMoment.toStringAsFixed(1)} kNm");
    report.writeln("Axial:  ${foundationAxial.toStringAsFixed(1)} kN");
    report.writeln("Shear:  ${foundationShear.toStringAsFixed(1)} kN");
    report.writeln("=" * 40);

    print("Finished Load Calculation!");

    return {
      "foundationUlsMoment": foundationUlsMoment,
      "foundationAxial": foundationAxial,
      "foundationShear": foundationShear,
      "report": report.toString(),
    };
  }

  String deflectionAndFrequencyChecks(
      List<MastSection> sections,
      double totalHeight,
      int mastType,
      double foundationUlsMoment,
      double foundationAxial,
      double foundationShear) {
    StringBuffer report = StringBuffer();
    double totalDeflection = 0;

    // Deflection Checks
    for (int sectionNum = 0; sectionNum < sections.length; sectionNum++) {
      MastSection section = sections[sectionNum];

      // Calculate deflection
      var result = calculateDeflection(section.slsMoment * 1e6, section.height,
          section.baseDia, section.thickness, sectionNum + 1);
      double defl = result["deflection"];
      String deflReport = result["report"];

      totalDeflection += defl;
      print(deflReport);
      report.writeln(deflReport);
    }

    // Allowable Deflection
    double allowableDeflection =
        mastType == 1 ? (totalHeight * 1000) / 40 : 150;

    report.writeln("\n===== DEFLECTION CHECK =====");
    report.writeln(
        "Calculated: ${totalDeflection.toStringAsFixed(1)}mm vs Allowable: ${allowableDeflection.toStringAsFixed(1)}mm");
    report.writeln(totalDeflection <= allowableDeflection ? "PASS" : "FAIL");
    report.writeln("=" * 40);

    // Natural Frequency Check
    double n0 = 46 / totalHeight;
    report.writeln("\n===== NATURAL FREQUENCY CHECK =====");
    report.writeln("Calculated: ${n0.toStringAsFixed(2)}Hz vs Required: >1Hz");
    report.writeln(n0 >= 1 ? "PASS" : "FAIL");
    report.writeln("=" * 40);

    // Final Output
    report.writeln("\n===== FINAL FOUNDATION DESIGN LOADS =====");
    report.writeln(
        "Ultimate Moment: ${foundationUlsMoment.toStringAsFixed(1)} kNm");
    report.writeln("Ultimate Axial:  ${foundationAxial.toStringAsFixed(1)} kN");
    report.writeln("Ultimate Shear:  ${foundationShear.toStringAsFixed(1)} kN");
    report.writeln("=" * 40);
    print(report);

    return report.toString();

    // print("\n===== DEFLECTION CHECK =====");
    // print(
    //     "Calculated: ${totalDeflection.toStringAsFixed(1)}mm vs Allowable: ${allowableDeflection.toStringAsFixed(1)}mm");
    // print(totalDeflection <= allowableDeflection ? "PASS" : "FAIL");
    // print("=" * 40);
    //
    // // Natural Frequency Check
    // double n0 = 46 / totalHeight;
    // print("\n===== NATURAL FREQUENCY CHECK =====");
    // print("Calculated: ${n0.toStringAsFixed(2)}Hz vs Required: >1Hz");
    // print(n0 >= 1 ? "PASS" : "FAIL");
    // print("=" * 40);
    //
    // // Final Output
    // print("\n===== FINAL FOUNDATION DESIGN LOADS =====");
    // print("Ultimate Moment: ${foundationUlsMoment.toStringAsFixed(1)} kNm");
    // print("Ultimate Axial:  ${foundationAxial.toStringAsFixed(1)} kN");
    // print("Ultimate Shear:  ${foundationShear.toStringAsFixed(1)} kN");
    // print("=" * 40);
  }

  Future<void> generatePDFReport(String reportContent) async {
    final font = await rootBundle.load("assets/fonts/OpenSans-Bold.ttf");
    final ttf = Font.ttf(font);
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Mast Calculation Report",
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 24,
                  // fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                reportContent,
                style: pw.TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );

    final output = await getExternalStorageDirectory();
    final file = File("${output!.path}/Mast_Report.pdf");
    await file.writeAsBytes(await pdf.save());

    Fluttertoast.showToast(msg: "PDF Report Saved: ${file.path}");

    OpenFile.open(file.path);
  }

  Future<void> generateAndSaveReport(
      String inputs,
      String sectionAnalysisReport,
      String loadCalculationReport,
      String ulsCheckReport,
      String deflectionAndFrequencyReport) async {
    var fontData2 = await rootBundle.load("assets/fonts/OpenSans-Regular.ttf");
    final Font ttfBold = Font.ttf(fontData2.buffer.asByteData());

    final pdf = pw.Document();

    // Combine all reports into one structured string
    String fullReport = """
===== MAST STRUCTURAL ANALYSIS REPORT =====
$inputs

$sectionAnalysisReport

$loadCalculationReport

$ulsCheckReport

$deflectionAndFrequencyReport

=========================================
""";

    // Split the report into paragraphs for better formatting
    List<String> reportSections = fullReport.split("\n");

    // Add content dynamically, splitting into multiple pages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4, // A4-sized pages
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              text: "MAST STRUCTURAL ANALYSIS REPORT",
              textStyle:
                  pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: reportSections.map((line) {
                return pw.Padding(
                  padding: pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text(line,
                      style: pw.TextStyle(fontSize: 12, font: ttfBold)),
                );
              }).toList(),
            ),
          ];
        },
      ),
    );

    // Save the PDF to a file
    final output = await getExternalStorageDirectory();
    final file = File("${output!.path}/mast_report.pdf");
    await file.writeAsBytes(await pdf.save());

    print("PDF saved at: ${file.path}");

    // Open the PDF file after saving
    OpenFile.open(file.path);
  }

  String _getMaterialName(int choice) {
    switch (choice) {
      case 1:
        return "Steel";
      case 2:
        return "Concrete";
      default:
        return "Steel";
    }
  }

  String _getTerrainName(int choice) {
    switch (choice) {
      case 1:
        return "Urban";
      case 2:
        return "Suburban";
      case 3:
        return "Open Terrain";
      default:
        return "Urban";
    }
  }

  String _getExposureName(int choice) {
    switch (choice) {
      case 1:
        return "Isolated";
      case 2:
        return "Clustered";
      default:
        return "Isolated";
    }
  }

  String _getMastTypeName(int choice) {
    switch (choice) {
      case 1:
        return "Lighting Mast";
      case 2:
        return "CCTV Mast";
      default:
        return "Lighting Mast";
    }
  }

  void main(
      {required double totalHeight2,
      required double topDiameter2,
      required double bottomDiameter2,
      required int sidesNumber2,
      required double vb2,
      required double fy2,
      required int mastType2,
      required List<double> thicknesses2,
      required int noLuminaries2,
      required double luminaryWidth2,
      required double luminaryHeight2,
      required int material2,
      required int terrain2,
      required int exposure2,
      required double equipmentweight2,
      required String location2,
      required double beta2}) {
    String finalreport = "";
    String finalreport2 = "";
    String userInputRepo = "";
    String location = "LOCATION : " +
        location2 +
        " | DATE: " +
        DateTime.now().toString().substring(0, 16);

    print("=== TR7-Compliant Mast Design Analysis ===");
    // double totalHeight2 = 30.0;
    // double topDia2 = 200.0;
    // double bottomDia2 = 500.0;
    // int N = 12;
    // double fy2 = 355.0;
    // double Vb2 = 25.0;
    // double beta = 1.0;
    // int mastType = 1;
    // List<double> thicknesses = [10.0, 12.0, 15.0];
    // int numLuminaries = 2;
    // double luminaryWidth = 600.0;
    // double luminaryHeight = 800.0;
    double luminaryProjectedArea =
        noLuminaries2 * (luminaryWidth2 / 1000) * (luminaryHeight2 / 1000);

    // Inputs
    try {
      print("Enter total height (10-60m): ");
      double totalHeight = totalHeight2;
      if (totalHeight < 10 || totalHeight > 60) {
        throw Exception("Height must be between 10 and 60 meters.");
      }

      print("Enter material (1=Steel, 2=Concrete): ");
      int materialChoice = material2;
      print("Enter terrain (1=Urban, 2=Suburban, 3=Open): ");
      int terrainChoice = terrain2;
      print("Enter basic wind speed (m/s): ");
      double Vb = vb2;
      print("Enter equipment weight (kg): ");
      double equipmentWeight = equipmentweight2;
      print("Enter exposure (1=Isolated, 2=Clustered): ");
      int exposureChoice = exposure2;

      // Response factor calculation
      double beta = calculateResponseFactor(
          totalHeight, materialChoice, terrainChoice, Vb);
      print("Response factor beta : $beta ");
      //end

      // Mast geometry
      print("Enter top diameter (mm): ");
      double topDia = topDiameter2;
      print("Enter bottom diameter (mm): ");
      double bottomDia = bottomDiameter2;
      print("Enter number of sides (≥8): ");
      int N = sidesNumber2;
      print("Enter yield strength (N/mm²): ");
      double fy = fy2;
      print("Enter mast type (1=Lighting, 2=CCTV): ");
      int mastType = mastType2;

      List<double> thicknesses = thicknesses2;

      print("Enter number of luminaries: ");
      int numLuminaries = noLuminaries2;
      print("Enter luminary width (mm): ");
      double luminaryWidth = luminaryWidth2 / 1000;
      print("Enter luminary height (mm): ");
      double luminaryHeight = luminaryHeight2 / 1000;

      double luminaryArea = numLuminaries * luminaryWidth * luminaryHeight;
      print("liminary Area calculate : $luminaryArea");

      userInputRepo = """ 
      {{  $location    }}
      
      
===== USER INPUT  =====
 Environmental Conditions:
- Material: ${_getMaterialName(materialChoice)}
- Terrain: ${_getTerrainName(terrainChoice)}
- Basic Wind Speed: ${Vb.toStringAsFixed(2)} m/s
- Equipment Weight: ${equipmentWeight.toStringAsFixed(1)} kg
- Exposure Type: ${_getExposureName(exposureChoice)}
- Response Factor (β): ${beta.toStringAsFixed(3)}

 Mast Geometry:
- Top Diameter: ${topDia.toStringAsFixed(1)} mm
- Bottom Diameter: ${bottomDia.toStringAsFixed(1)} mm
- Number of Sides: $N
- Yield Strength (fy): ${fy.toStringAsFixed(1)} N/mm²
- Mast Type: ${_getMastTypeName(mastType)}
- Thicknesses (mm): ${thicknesses.join(", ")}

Luminary Details:
- Number of Luminaries: $numLuminaries
- Luminary Width: ${(luminaryWidth * 1000).toStringAsFixed(1)} mm
- Luminary Height: ${(luminaryHeight * 1000).toStringAsFixed(1)} mm
- Luminary Area: ${luminaryArea.toStringAsFixed(3)} m²

=================================
""";

      String cfReport = """
\n=========================================
            Drag Coefficient (C_f) Report            
=========================================

For Circular Masts:
0        < Re ≤ 2 × 10⁵               C_f = 1.2  
2 × 10⁵ < Re ≤ 4 × 10⁵               C_f = 1.9 - 0.35 × (Re × 10-⁵)  
4 × 10⁵ < Re ≤ 22 × 10⁵              C_f = 0.433 + 0.0167 × (Re × 10-⁵)  
22 × 10⁵ < Re                          C_f = 0.8  

For Octagonal Masts (8-sided):
0        < Re ≤ 2.3 × 10⁵             C_f = 1.45  
2.3 × 10⁵ < Re ≤ 3.0 × 10⁵           C_f = 1.943 - 0.2143 × (Re × 10-⁵)  
3.0 × 10⁵ < Re                        C_f = 1.3  

For Dodecagonal Masts (12-sided):
0        < Re ≤ 2 × 10⁵               C_f = 1.3  
2 × 10⁵ < Re ≤ 7 × 10⁵               C_f = 1.38 - 0.04 × (Re × 10-⁵)  
7 × 10⁵ < Re                          C_f = 1.1  

For Hexadecagonal Masts (16-sided):
0        < Re ≤ 2 × 10⁵               C_f = 1.25  
2 × 10⁵ < Re ≤ 6 × 10⁵               C_f = 1.475 - 0.1125 × (Re × 10-⁵)  
6 × 10⁵ < Re ≤ 14 × 10⁵              C_f = 0.725 + 0.0125 × (Re × 10-⁵)  
14 × 10⁵ < Re                         C_f = 0.9  

=========================================
""";

      print("inputs------------------> $userInputRepo");
      // Call createTaperedSections and other functions here, like in Python version
      List<MastSection> sections =
          createTaperedSections(totalHeight2, topDia, bottomDia, thicknesses);

      //wind loads
      print("starting windloads");
      double V_uls = calculateDesignWindSpeed(Vb, 1);
      double V_sls = mastType == 2 ? 22.0 : V_uls * 0.2;
      // calculateDesignWindSpeed(Vb, mastType) * (mastType == 1 ? 0.2 : 1.0);
      double deltaLum = 1 - 0.1 * log(totalHeight);
      double qLumUls = 0.613 * pow(V_uls, 2);
      double qLumSls = 0.613 * pow(V_sls, 2);
      // double peakStaticPressure = beta * deltaLum * qLumUls;
      double luminaryLoadSls = 1.0 * beta * deltaLum * qLumSls * luminaryArea;
      double luminaryLoadUls = 1.0 * beta * deltaLum * qLumUls * luminaryArea;
      print("\n===== WIND LOAD INPUTS =====");
      print(
          "V_uls (Ultimate Wind Speed)     : ${V_uls.toStringAsFixed(2)} m/s");
      print(
          "V_sls (Serviceability Wind Speed) : ${V_sls.toStringAsFixed(2)} m/s");
      print(
          "Delta Factor                     : ${deltaLum.toStringAsFixed(4)}");
      print(
          "q_uls (Wind Pressure ULS)        : ${qLumUls.toStringAsFixed(2)} N/m²");
      print(
          "q_sls (Wind Pressure SLS)        : ${qLumSls.toStringAsFixed(2)} N/m²");
      print(
          "Luminary Load ULS                : ${luminaryLoadUls.toStringAsFixed(2)} N");
      print(
          "Luminary Load SLS                : ${luminaryLoadSls.toStringAsFixed(2)} N");
      print("===================================");
      // Section load analysis
      print("starting section load analysis");
      String set = ":";
      for (var section in sections) {
        print(section.cf +
            section.peak_static_pressure +
            section.wind_force +
            section.ulsMoment +
            section.height +
            section.baseDia +
            section.baseHeight);
      }

      print("v uls" + V_uls.toString());
      print("height" + totalHeight.toString());
      print("beta" + beta.toString());
      print("N" + N.toString());
      print("fy" + fy.toString());

      var sectionRep =
          sectionAnalysis(sections, V_uls, totalHeight, beta, N, fy);
      // finalreport.writeln(sectionRep["windreport"]);
      // finalreport.writeln(sectionRep["mpreport"]);

      finalreport += sectionRep["windreport"];
      finalreport += sectionRep["mpreport"];

      print("finish section load analysis--start load");
      print("final report as at now-------------> $finalreport");

      print("start CALCULATE SECTION LOADS");

      var result = calculateSectionLoads(sections, luminaryLoadUls,
          luminaryLoadSls, equipmentWeight, totalHeight);

      //end
      // finalreport.writeln(sectionRep["report"]);
      finalreport += result["report"];

      print("wadhamadaye 2++++++");

      print("final report as at now- post sec loads------------> $finalreport");
      // Extract values from the map
      double foundationUlsMoment = result["foundationUlsMoment"] ?? 0.0;
      double foundationAxial = result["foundationAxial"] ?? 0.0;
      double foundationShear = result["foundationShear"] ?? 0.0;

      print("calculate secTION LOADS VALUE: _MOMEMNT $foundationUlsMoment");

      print("start uls check summarry");
      var repo = ulsChecksSummary(sections);
      // finalreport.writeln(repo);
      finalreport2 += repo;

      print("finishuls check summarry" + repo);
      print("final report as at now- post summary------------> $finalreport2");
      //
      print("start deflection and frequency checks");

      print("foundationUlsMoment" + foundationUlsMoment.toString());
      print("foundationAxial" + foundationAxial.toString());
      print("foundationShear" + foundationShear.toString());
      var defrepo = deflectionAndFrequencyChecks(sections, totalHeight,
          mastType, foundationUlsMoment, foundationAxial, foundationShear);
      // finalreport.writeln(defrepo);
      finalreport2 += defrepo;

      print(
          "final report as at now- post defeletcion------------> $finalreport2");

      //generatePDFReport(finalreport.toString() + finalreport2);
      generateAndSaveReport(
          userInputRepo + cfReport,
          sectionRep["windreport"] + sectionRep["mpreport"],
          result["report"],
          repo,
          defrepo);
    } catch (e) {
      print("\n!===== ERROR =====!");
      print(e.toString());
      print("=" * 40);
    }
  }
}
