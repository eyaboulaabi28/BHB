import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class CommonPdfHeaderFooter {
  static pw.Widget buildHeader({
    required pw.Font arabicFont,
    required pw.Font emojiFont,
    required pw.ImageProvider logo,
  }) {
    final now = DateTime.now();
    final dateText = "${now.day}/${now.month}/${now.year}  🕓";

    return pw.Column(
      children: [
        // ===== BAR COLOR =====
        pw.Container(
          height: 8,
          width: double.infinity,
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [
                PdfColor.fromHex('#FFD700'),
                PdfColor.fromHex('#022C43'),
              ],
            ),
          ),
        ),

        pw.SizedBox(height: 8),

        // ===== HEADER CONTENT (FORCED LTR) =====
        pw.Directionality(
          textDirection: pw.TextDirection.ltr,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [

              // 📅 DATE — LEFT
              pw.Text(
                dateText,
                style: pw.TextStyle(
                  font: arabicFont,
                  fontFallback: [emojiFont],
                  fontSize: 11,
                  color: PdfColors.grey700,
                ),
              ),

              // 🏢 LOGO — RIGHT
              pw.Image(
                logo,
                width: 80,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget buildFooter({
    required pw.Font arabicFont,
    required pw.Font emojiFont,
    required pw.ImageProvider fb,
    required pw.ImageProvider google,
    required pw.ImageProvider linkedIn,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      child: pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 6),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "+966545388835  ☎",
                style: pw.TextStyle(
                  font: arabicFont,
                  fontFallback: [emojiFont],
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
                textDirection: pw.TextDirection.rtl,
              ),

              pw.Row(
                children: [
                  pw.Image(fb, width: 14),
                  pw.SizedBox(width: 4),
                  pw.Image(google, width: 14),
                  pw.SizedBox(width: 4),
                  pw.Image(linkedIn, width: 14),
                  pw.SizedBox(width: 12),

                  pw.Text(
                    "BHB_Group",
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontFallback: [emojiFont],
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),

                  pw.SizedBox(width: 12),

                  pw.Text(
                    "🌐 https://x.com/BHB_Group",
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontFallback: [emojiFont],
                      fontSize: 10,
                      color: PdfColors.blue700,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
