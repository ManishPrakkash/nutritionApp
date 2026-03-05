import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../providers/reports_provider.dart';

class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  // ---------------------------------------------------------------------------
  // Single Performance Analytics PDF
  // ---------------------------------------------------------------------------
  Future<File> generatePerformanceReport({
    required PerformanceReportData data,
    required String userName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (ctx) => _header(
        'Performance Analytics Report',
        userName,
        data.reportDate,
      ),
      footer: (ctx) => _footer(ctx),
      build: (ctx) => [
        // ── Profile snapshot ──
        _sectionTitle('Profile Snapshot'),
        _kv('Activity Level', _capitalize(data.activityLevel)),
        _kv('Health Goal', _capitalize(data.healthGoal)),
        _kv('Current Weight', '${data.currentWeight.toStringAsFixed(1)} kg'),
        _kv('Daily Calorie Target', '${data.targetCalories.toStringAsFixed(0)} kcal'),
        pw.SizedBox(height: 16),

        // ── Performance Scores ──
        _sectionTitle('Performance Scores (Last 7 Days)'),
        pw.TableHelper.fromTextArray(
          headerStyle:
              pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellAlignment: pw.Alignment.center,
          headers: [
            'Nutrition',
            'Activity',
            'Sleep',
            'Hydration',
          ],
          data: [
            [
              '${data.nutritionScore.round()}%',
              '${data.activityScore.round()}%',
              '${data.sleepScore.round()}%',
              '${data.hydrationScore.round()}%',
            ]
          ],
        ),
        pw.SizedBox(height: 16),

        // ── Nutrition Breakdown ──
        _sectionTitle('Nutrition Breakdown'),
        _kv('Meals Eaten', '${data.mealsEaten} / ${data.totalMeals}'),
        _kv('Average Calories',
            '${data.avgCalories.toStringAsFixed(0)} kcal'),
        _nutrientRow('Protein', data.totalProtein),
        _nutrientRow('Carbs', data.totalCarbs),
        _nutrientRow('Fat', data.totalFat),
        pw.SizedBox(height: 16),

        // ── Activity & Workouts ──
        _sectionTitle('Activity & Workouts'),
        _kv('Workouts Completed',
            '${data.workoutsCompleted} / ${data.totalWorkoutDays} days'),
        _kv('Total Steps', '${data.totalSteps}'),
        _kv('Average Steps/Day', '${data.avgSteps}'),
        _kv('Steps Target', '${data.targetSteps}'),
        pw.SizedBox(height: 16),

        // ── Sleep & Hydration ──
        _sectionTitle('Sleep & Hydration'),
        pw.TableHelper.fromTextArray(
          headerStyle:
              pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellAlignment: pw.Alignment.center,
          headers: [
            'Avg Sleep (h)',
            'Target Sleep (h)',
            'Avg Water (L)',
            'Target Water (L)',
          ],
          data: [
            [
              data.avgSleep.toStringAsFixed(1),
              data.targetSleep.toStringAsFixed(1),
              data.avgWater.toStringAsFixed(1),
              data.targetWater.toStringAsFixed(1),
            ]
          ],
        ),
        pw.SizedBox(height: 24),

        _disclaimer(),
      ],
    ));

    return _save(pdf, 'Performance_Report');
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  pw.Widget _header(String title, String userName, String dateStr) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'ZenFuel AI',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.Text(dateStr,
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text('Subject: $userName',
              style: const pw.TextStyle(
                  fontSize: 11, color: PdfColors.grey800)),
          pw.Divider(thickness: 0.5),
        ],
      ),
    );
  }

  pw.Widget _footer(pw.Context ctx) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(title,
          style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900)),
    );
  }

  pw.Widget _kv(String key, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(children: [
        pw.Text('$key: ',
            style:
                pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
      ]),
    );
  }

  pw.Widget _nutrientRow(String name, double grams) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(children: [
        pw.SizedBox(width: 16),
        pw.Text('• $name: ',
            style:
                pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.Text('${grams.toStringAsFixed(1)} g',
            style: const pw.TextStyle(fontSize: 10)),
      ]),
    );
  }

  pw.Widget _disclaimer() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        'DISCLAIMER: This report is generated for informational purposes only. '
        'It does not constitute medical advice. Please consult healthcare professionals for clinical decisions.',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  Future<File> _save(pw.Document pdf, String prefix) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
