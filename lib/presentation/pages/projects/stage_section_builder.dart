import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class StageSectionBuilder {
  final Map<String, dynamic> stage;
  final pw.Font arabicFont;
  final pw.Font emojiFont;
  final pw.Widget Function() buildSubStages;

  StageSectionBuilder({
    required this.stage,
    required this.arabicFont,
    required this.emojiFont,
    required this.buildSubStages,
  });

  pw.Widget build() {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [

          // ===== HEADER STAGE =====
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  PdfColor.fromHex('#0E4D92'),
                  PdfColor.fromHex('#1E6091'),
                ],
              ),
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Text(
              "📌 ${stage['name']}",
              style: pw.TextStyle(
                font: arabicFont,
                fontFallback: [emojiFont],
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              textAlign: pw.TextAlign.center,
              textDirection: pw.TextDirection.rtl,
            ),
          ),

          pw.SizedBox(height: 6),

          // ===== SUB STAGES + TASKS =====
          buildSubStages(),
        ],
      ),
    );
  }
}
