import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

class PdfThemeManager {
  final pw.Font arabicFont;
  final pw.Font emojiFont;
  static PdfColor get primary =>
      PdfColor.fromHex('#21206C');

  PdfThemeManager._(this.arabicFont, this.emojiFont);

  static Future<PdfThemeManager> init() async {
    final arabicFont = pw.Font.ttf(
      await rootBundle.load("assets/font/NotoSansArabic-Regular.ttf"),
    );

    final emojiFont = pw.Font.ttf(
      await rootBundle.load("assets/font/NotoEmoji-Regular.ttf"),
    );

    return PdfThemeManager._(arabicFont, emojiFont);
  }

  /// 🔹 Style par défaut
  pw.TextStyle get baseStyle => pw.TextStyle(
    font: arabicFont,
    fontFallback: [emojiFont],
    fontSize: 10,
  );

  /// 🔹 Texte arabe SAFE
  pw.Text arabicText(
      String text, {
        double size = 10,
        pw.FontWeight weight = pw.FontWeight.normal,
        PdfColor? color,
        pw.TextAlign align = pw.TextAlign.right,
      }) {
    return pw.Text(
      text,
      textDirection: pw.TextDirection.rtl,
      textAlign: align,
      style: baseStyle.copyWith(
        fontSize: size,
        fontWeight: weight,
        color: color,
      ),
    );
  }

  /// 🔹 Header de sous-section
  pw.Widget sectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(6),
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [
            PdfColor.fromHex('#0E4D92'),
            PdfColor.fromHex('#1E6091'),
          ],
        ),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: arabicText(
        title,
        size: 12,
        weight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
    );
  }
}
