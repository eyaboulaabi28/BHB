import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class StageSectionBuilder1 {
  final Map<String, dynamic> stage;
  final pw.Font arabicFont;
  final pw.Font emojiFont;
  final pw.Widget Function() buildSubStages;

  StageSectionBuilder1({
    required this.stage,
    required this.arabicFont,
    required this.emojiFont,
    required this.buildSubStages,
  });

  List<pw.Widget> buildAsList() {
    return [
      pw.Container(
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

            // HEADER
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

            // 👇 هذا الآن آمن
            buildSubStages(),
          ],
        ),
      ),
    ];
  }
  pw.Widget buildStageHeader({
    required String stageName,
    required pw.Font arabicFont,
    required pw.Font emojiFont,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      margin: const pw.EdgeInsets.only(bottom: 6),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [
            PdfColor.fromHex('#0E4D92'),
            PdfColor.fromHex('#1E6091'),
          ],
        ),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        '📌 $stageName',
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: arabicFont,
          fontFallback: [emojiFont],
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

}

