import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SectionPdfBuilder {
  final Map<String, dynamic> section;
  final pw.Font arabicFont;
  final pw.Font emojiFont;
  final pw.Widget Function() buildTests;

  SectionPdfBuilder({
    required this.section,
    required this.arabicFont,
    required this.emojiFont,
    required this.buildTests,
  });

  pw.Widget build() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // HEADER
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [
                PdfColor.fromHex('#0E4D92'),
                PdfColor.fromHex('#1E6091'),
              ],
            ),
          ),
          child: pw.Text(
            "📌 ${section['section_name']}",
            style: pw.TextStyle(
              font: arabicFont,
              fontFallback: [emojiFont],
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
            textDirection: pw.TextDirection.rtl,
          ),
        ),

        pw.SizedBox(height: 3),

        buildTests(),
      ],
    );
  }
}
