import 'dart:io';
import 'package:app_bhb/data/auth/models/newsite_model.dart';
import 'package:app_bhb/presentation/pages/attendance/generate_pdf_attendance.dart';
import 'package:app_bhb/presentation/pages/engineers_evaluation/common_pdf_header_footer.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class NewSitePdfGenerator {
  /// Générer un PDF avec toutes les informations du site
  static Future<pw.Document> generate({required NewSite site}) async {
    final pdf = pw.Document();

    // ===== Fonts =====
    final arabicFont = pw.Font.ttf(
      await rootBundle.load("assets/font/NotoSansArabic-Regular.ttf"),
    );
    final emojiFont = pw.Font.ttf(
      await rootBundle.load("assets/font/NotoEmoji-Regular.ttf"),
    );

    // ===== Assets =====
    final logo = await _imageFromAsset("assets/img/app_logo.png");
    final fbEmoji = await _imageFromAsset("assets/img/fb.png");
    final googleEmoji = await _imageFromAsset("assets/img/google.png");
    final linkedInEmoji = await _imageFromAsset("assets/img/in.png");

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),

        // ✅ نفس الـ Header
        header: (_) => CommonPdfHeaderFooter.buildHeader(
          arabicFont: arabicFont,
          emojiFont: emojiFont,
          logo: logo,
        ),

        // ✅ نفس الـ Footer
        footer: (_) => CommonPdfHeaderFooter.buildFooter(
          arabicFont: arabicFont,
          emojiFont: emojiFont,
          fb: fbEmoji,
          google: googleEmoji,
          linkedIn: linkedInEmoji,
        ),

        build: (context) => [
          // ===== Title =====
          pw.Center(
            child: pw.Text(
              "تفاصيل زيارة الموقع",
              style: pw.TextStyle(
                font: arabicFont,
                fontFallback: [emojiFont],
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#022C43'),
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ),

          pw.SizedBox(height: 20),

          // ===== Site info card =====
          _infoCard("👤 اسم العميل", site.customerName, arabicFont, emojiFont),
          _infoCard("🏗️ اسم المشروع", site.projectName, arabicFont, emojiFont),
          _infoCard("📞 الهاتف", site.phone, arabicFont, emojiFont),
          _infoCard("👷 المهندس", site.nameEngineer, arabicFont, emojiFont),

          if (site.latitude != null && site.longitude != null)
            _infoCard(
              "📍 الإحداثيات",
              "${site.latitude}, ${site.longitude}",
              arabicFont,
              emojiFont,
            ),

          if (site.createdAt != null)
            _infoCard(
              "📅 تاريخ الإنشاء",
              "${site.createdAt!.year}-${site.createdAt!.month.toString().padLeft(2, '0')}-${site.createdAt!.day.toString().padLeft(2, '0')}",
              arabicFont,
              emojiFont,
            ),

          pw.SizedBox(height: 12),

          _sectionTitle("📝 ملاحظات تقرير الإشراف", arabicFont, emojiFont),
          pw.Text(
            site.generalRemark ?? "-",
            style: pw.TextStyle(
              font: arabicFont,
              fontFallback: [emojiFont],
              fontSize: 13,
            ),
            textDirection: pw.TextDirection.rtl,
          ),

          pw.SizedBox(height: 18),

          _sectionTitle("📋 تفاصيل المهام", arabicFont, emojiFont),

          ...site.task.items.map(
                (task) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F5F9FF'),
                borderRadius: pw.BorderRadius.circular(14),
                border: pw.Border.all(color: PdfColor.fromHex('#D6E4FF')),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "• ${task.remark}",
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontFallback: [emojiFont],
                      fontSize: 13,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  if (task.imageUrl.isNotEmpty)
                    pw.Text(
                      "📷 ${task.imageUrl}",
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 11,
                        color: PdfColor.fromHex('#3949AB'),
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 20),
          AttendancePdfGenerator.buildAutoGeneratedNotice(arabicFont, emojiFont),
        ],
      ),
    );

    return pdf;
  }

  // ===== Helpers =====
  static pw.Widget _infoCard(
      String label,
      String? value,
      pw.Font arabicFont,
      pw.Font emojiFont,
      ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#EEF4FF'),
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: PdfColor.fromHex('#D6E4FF')),
      ),
      child: pw.Text(
        "$label: ${value ?? '-'}",
        style: pw.TextStyle(
          font: arabicFont,
          fontFallback: [emojiFont],
          fontSize: 13,
        ),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  static pw.Widget _sectionTitle(
      String title,
      pw.Font arabicFont,
      pw.Font emojiFont,
      ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: arabicFont,
          fontFallback: [emojiFont],
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#022C43'),
        ),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  static Future<pw.ImageProvider> _imageFromAsset(String path) async {
    final bytes = await rootBundle.load(path);
    return pw.MemoryImage(bytes.buffer.asUint8List());
  }
}
