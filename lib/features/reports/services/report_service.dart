import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../../models/prediction_result.dart';
import '../../../models/user_profile.dart';

class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  Future<File> generateHealthReport({
    required UserProfile profile,
    PredictionResult? predictions,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('ZenFuel AI - Intelligence Dossier',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Subject: ${profile.fullName}', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Date: ${DateTime.now().toString()}', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 20),
              
              pw.Text('Biometric Profile', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Bullet(text: 'Age: ${profile.age}'),
              pw.Bullet(text: 'Gender: ${profile.gender}'),
              pw.Bullet(text: 'Biological Mass: ${profile.weightKg} kg'),
              pw.Bullet(text: 'Stature: ${profile.heightCm} cm'),
              pw.Bullet(text: 'BMI: ${profile.bmi?.toStringAsFixed(1) ?? "N/A"}'),
              
              pw.SizedBox(height: 20),
              pw.Text('Health Risk Projections', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              if (predictions != null)
                ...predictions.predictions.map((p) => pw.Bullet(
                    text: '${p.condition}: ${p.level.toUpperCase()} (${p.score.toStringAsFixed(1)}%)')),
              if (predictions == null) pw.Text('No diagnostic data available.'),
              
              pw.SizedBox(height: 20),
              pw.Text('Strategic Targets', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Bullet(text: 'Daily Caloric Threshold: ${predictions?.calorieTarget?.round() ?? profile.tdee?.round() ?? "Calculating..."} kcal'),
              pw.Bullet(text: 'Badge Status: ${predictions?.badgeStatus ?? "Novice"}'),
              
              pw.SizedBox(height: 40),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('End of Intelligence Report', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Health_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
