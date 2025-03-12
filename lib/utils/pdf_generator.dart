import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

Future<void> generatePDF(
    double moment, double thickness, double mastStrength) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.Center(
        child: pw.Column(
          children: [
            pw.Text("Mast Calculation Report",
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text("Moment: ${moment.toStringAsFixed(2)} Nm"),
            pw.Text("Thickness: ${thickness.toStringAsFixed(2)} mm"),
            pw.Text("Mast Strength: ${mastStrength.toStringAsFixed(2)}"),
          ],
        ),
      ),
    ),
  );

  final output = await getExternalStorageDirectory();
  final file = File("${output!.path}/mast_report.pdf");
  await file.writeAsBytes(await pdf.save());

  print("PDF saved at ${file.path}");
}
