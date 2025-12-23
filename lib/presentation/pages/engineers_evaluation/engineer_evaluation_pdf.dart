import 'package:app_bhb/presentation/pages/engineers_evaluation/common_pdf_header_footer.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';


class EngineerEvaluationPDF {
  static Future<void> generate({
    required String engineerName,
    required String month,
    required String tasksCount,
    required String completedTasks,
    required String totalHours,
    required String overtimeHours,
    required String totalDays,
    required String estimatedDuration,
  }) async {
    final arabicFont = pw.Font.ttf(await rootBundle.load("assets/font/NotoSansArabic-Regular.ttf"));
    final emojiFont = pw.Font.ttf(await rootBundle.load("assets/font/NotoEmoji-Regular.ttf"));

    final logo = await imageFromAssetBundle("assets/img/app_logo.png");
    final fbEmoji = await imageFromAssetBundle("assets/img/fb.png");
    final googleEmoji = await imageFromAssetBundle("assets/img/google.png");
    final linkedInEmoji = await imageFromAssetBundle("assets/img/in.png");

    // Convert values to double
    final double tasksVal = double.parse(tasksCount);
    final double compVal = double.parse(completedTasks);
    final double hoursVal = double.parse(totalHours);
    final double extraVal = double.parse(overtimeHours);
    final double daysVal = double.parse(totalDays);

// Bar chart data avec les nouvelles informations
    final Map<String, double> barData = {
      "عدد المهام": tasksVal,
      "المهام المكتملة": compVal,
      "عدد ساعات العمل": hoursVal,
      "الساعات الإضافية": extraVal,
      "عدد أيام العمل": daysVal,
    };

    final int t = int.parse(tasksCount);
    final int c = int.parse(completedTasks);
    final double percent = t == 0 ? 0 : (c / t * 100);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(25),
        header: (_) => CommonPdfHeaderFooter.buildHeader(
          arabicFont: arabicFont,
          emojiFont: emojiFont,
          logo: logo,
        ),
        footer: (_) => CommonPdfHeaderFooter.buildFooter(
          arabicFont: arabicFont,
          emojiFont: emojiFont,
          fb: fbEmoji,
          google: googleEmoji,
          linkedIn: linkedInEmoji,
        ),
        build: (_) => [
          pw.Center(
            child: pw.Text(
              "تقرير الأداء الشهري للمهندس",
              style: pw.TextStyle(font: arabicFont, fontSize: 22, fontWeight: pw.FontWeight.bold),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.SizedBox(height: 20),

          // Info Card
          _simpleInfo(engineerName, month, arabicFont,emojiFont),


          pw.SizedBox(height: 25),

          // Charts Section
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 2,
                child: _barChartModern(barData, arabicFont),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                flex: 1,
                child: _donutCompletion(percent, t, c, arabicFont),
              ),
            ],
          ),

          pw.SizedBox(height: 25),

          // Details Table
          _statDetailsTable(
            tasksCount,
            completedTasks,
            totalHours,
            overtimeHours,
            totalDays,
            estimatedDuration,
            arabicFont,
            emojiFont,
          ),

          pw.SizedBox(height: 20),

          pw.Center(
            child: pw.Text(
              "تم إنشاء هذا التقرير تلقائياً عبر نظام تقييم الأداء",
              style: pw.TextStyle(font: arabicFont, fontSize: 11, color: PdfColors.grey600),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

// ---------------------- INFO SIMPLE EN HAUT ----------------------
  static pw.Widget _simpleInfo(String engineer, String month, pw.Font arabic, pw.Font emojiFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end, // aligné à droite
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text("", style: pw.TextStyle(font: arabic, fontFallback: [emojiFont], fontSize: 14)), // icône ingénieur
                  pw.SizedBox(width: 4),
                  pw.Text(
                    " 👷المهندس: $engineer",
                    style: pw.TextStyle(
                      font: arabic,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      fontFallback: [emojiFont],
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text("", style: pw.TextStyle(font: arabic, fontFallback: [emojiFont], fontSize: 14)), // icône calendrier
                  pw.SizedBox(width: 4),
                  pw.Text(
                    " 📅الشهر: $month",
                    style: pw.TextStyle(
                      font: arabic,
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      fontFallback: [emojiFont],
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------- BAR CHART ----------------------
  static pw.Widget _barChartModern(Map<String, double> data, pw.Font arabic) {
    double maxVal = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);

    return pw.Container(
      height: 250,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(16),
        boxShadow: [
          pw.BoxShadow(blurRadius: 8, spreadRadius: 1, color: PdfColors.grey300),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "مخطط الأداء",
            style: pw.TextStyle(font: arabic, fontSize: 14, fontWeight: pw.FontWeight.bold),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 16),
          ...data.entries.map((e) {
            final double barWidth = maxVal == 0 ? 0 : ((e.value / maxVal) * 220).clamp(10, 220);
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  // Texte (nom de la catégorie)
                  pw.Expanded(
                    child: pw.Text(
                      e.key,
                      style: pw.TextStyle(font: arabic, fontSize: 11, color: PdfColors.grey700),
                      textDirection: pw.TextDirection.rtl,
                      maxLines: 2,
                      overflow: pw.TextOverflow.clip,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  // Barre
                  pw.Stack(
                    children: [
                      pw.Container(
                        height: 20,
                        width: 220,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                      ),
                      pw.Container(
                        height: 20,
                        width: barWidth,
                        decoration: pw.BoxDecoration(
                          borderRadius: pw.BorderRadius.circular(10),
                          gradient: pw.LinearGradient(
                            colors: [PdfColor.fromHex("#1E88E5"), PdfColor.fromHex("#42A5F5")],
                          ),
                        ),
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.only(right: 8),
                          child: pw.Align(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(
                              "${e.value}",
                              style: pw.TextStyle(font: arabic, color: PdfColors.white, fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }


// ---------------------- DONUT CHART ----------------------
  static pw.Widget _donutCompletion(double percent, int total, int completed, pw.Font arabic) {
    return pw.Container(
      height: 250, // même hauteur que bar chart
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(16),
        boxShadow: [
          pw.BoxShadow(blurRadius: 8, spreadRadius: 1, color: PdfColors.grey300),
        ],
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            "نسبة الإنجاز",
            style: pw.TextStyle(font: arabic, fontSize: 14, fontWeight: pw.FontWeight.bold),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 16),
          pw.Stack(
            alignment: pw.Alignment.center,
            children: [
              pw.Container(
                width: 100,
                height: 100,
                child: pw.CircularProgressIndicator(
                  value: percent / 100,
                  backgroundColor: PdfColors.grey200,
                  color: PdfColor.fromHex("#1E88E5"),
                  strokeWidth: 10,
                ),
              ),
              pw.Text(
                "${percent.toStringAsFixed(0)}%",
                style: pw.TextStyle(font: arabic, fontSize: 18, fontWeight: pw.FontWeight.bold),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            "$completed من أصل $total مهمة",
            style: pw.TextStyle(font: arabic, fontSize: 12, color: PdfColors.grey700),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }


  // ---------------------- DETAILS TABLE ----------------------
  static pw.Widget _statDetailsTable(
      String t, String c, String h, String o, String d, String est,
      pw.Font arabic, pw.Font emojiFont) {

    final Map<String, String> titlesWithEmoji = {
      "عدد المهام": "📝",
      "المهام المكتملة": "✅",
      "عدد ساعات العمل": "⏰",
      "الساعات الإضافية": "➕",
      "عدد أيام العمل": "📅",
      "المدة التقديرية": "⏳",
    };

    final Map<String, String> values = {
      "عدد المهام": t,
      "المهام المكتملة": c,
      "عدد ساعات العمل": h,
      "الساعات الإضافية": o,
      "عدد أيام العمل": d,
      "المدة التقديرية": est,
    };

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.7),
      children: values.entries.map((e) {
        final emoji = titlesWithEmoji[e.key] ?? "";
        return pw.TableRow(
          children: [

            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                e.value,
                style: pw.TextStyle(
                  font: arabic,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.right,
                textDirection: pw.TextDirection.rtl,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                "$emoji ${e.key}",
                style: pw.TextStyle(
                  font: arabic,
                  fontFallback: [emojiFont],
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
            ),
          ],
        );
      }).toList(),
    );

  }



  // ---------------------- HELPER ----------------------
  static Future<pw.ImageProvider> imageFromAssetBundle(String path) async {
    final bytes = await rootBundle.load(path);
    return pw.MemoryImage(bytes.buffer.asUint8List());
  }
}

