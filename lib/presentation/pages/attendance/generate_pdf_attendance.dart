import 'dart:typed_data';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/data/auth/models/attendance_model.dart';
import 'package:app_bhb/presentation/pages/engineers_evaluation/common_pdf_header_footer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:http/http.dart' as http;



class AttendancePdfGenerator {
  // ---------------- Méthode principale ----------------
  static Future<void> generateAndOpenPdf({
    required List<Attendance> attendances,
    required String employeeName,
    required DateTime month,
    required BuildContext context,
  }) async {
    if (attendances.isEmpty) {
      CustomSnackBar.show(
        context,
        message: "لا توجد بيانات لتصدير PDF",
        type: SnackBarType.info,
      );
      return;
    }

    final pdfBytes = await _generatePdf(attendances, employeeName, month, context);

    // Ouvrir / Partager le PDF
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'تقرير_الحضور.pdf',
    );

    CustomSnackBar.show(
      context,
      message: "✅ تم تحميل ملف PDF بنجاح!",
      type: SnackBarType.success,
    );

    // Partage sur mobile
    if (!kIsWeb) {
      try {
        final dir = await getTemporaryDirectory();
        final file = io.File('${dir.path}/تقرير_الحضور.pdf');
        await file.writeAsBytes(pdfBytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: "👋 مرحبا، هذا تقرير الحضور للموظف $employeeName.",
          subject: "تقرير الحضور",
        );

        // WhatsApp
        final whatsappNumber = "+966560952288";
        final whatsappUrl =
            "https://wa.me/${whatsappNumber.replaceAll("+", "").trim()}?text=👋 مرحبا، هذا تقرير الحضور للموظف $employeeName.";
        if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
          await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
        }

        CustomSnackBar.show(
          context,
          message: "📤 تم إرسال التقرير بنجاح",
          type: SnackBarType.success,
        );
      } catch (e) {
        CustomSnackBar.show(
          context,
          message: "❌ حدث خطأ أثناء مشاركة التقرير: $e",
          type: SnackBarType.error,
        );
      }
    }
  }

  // ---------------- Génération PDF ----------------
  static Future<Uint8List> _generatePdf(
      List<Attendance> attendances,
      String employeeName,
      DateTime month,
      BuildContext context,
      ) async {
    final totalOvertimeMinutes = attendances
        .where((a) => a.overtimeHours != null)
        .fold<double>(
        0,
            (sum, a) =>
        sum + double.tryParse(a.overtimeHours!)!
    );

    final totalWaitingMinutes = attendances
        .where((a) => a.waitingHours != null)
        .fold<double>(
        0,
            (sum, a) =>
        sum + double.tryParse(a.waitingHours!)!
    );



    final totalOvertimeHours = totalOvertimeMinutes / 60;
    final totalWaitingHours = totalWaitingMinutes / 60;

    CustomSnackBar.show(
      context,
      message: " جاري إنشاء ملف PDF...",
      type: SnackBarType.loading,
      duration: const Duration(seconds: 300),
    );

    final pdf = pw.Document();

    final arabicFont = pw.Font.ttf(await rootBundle.load("assets/font/NotoSansArabic-Regular.ttf"));
    final emojiFont = pw.Font.ttf(await rootBundle.load("assets/font/NotoEmoji-Regular.ttf"));

    final logo = await _imageFromAsset("assets/img/app_logo.png");
    final fbEmoji = await _imageFromAsset("assets/img/fb.png");
    final googleEmoji = await _imageFromAsset("assets/img/google.png");
    final linkedInEmoji = await _imageFromAsset("assets/img/in.png");

    final attendanceWidgets = await buildAttendanceCards(attendances, arabicFont, emojiFont);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
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
        build: (context) => [
          pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  "تقرير مفصل حول سجل حضور الموظف",
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontFallback: [emojiFont],
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#022C43'),
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 3),
                pw.Container(
                  height: 4,
                  width: 150,
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [PdfColor.fromHex('#FFD700'), PdfColor.fromHex('#022C43')],
                    ),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 15),
          buildEmployeeCardWithChart(
            employeeName,
            month,
            totalOvertimeHours,
            totalWaitingHours,
            arabicFont,
            emojiFont,
          ),
          pw.SizedBox(height:15),
          ...attendanceWidgets,
          pw.SizedBox(height: 5),
          buildAutoGeneratedNotice(arabicFont, emojiFont),

        ],
      ),
    );

    return pdf.save();
  }
  static pw.Widget buildEmployeeCardWithChart(
      String employeeName,
      DateTime month,
      double totalOvertimeHours,
      double totalWaitingHours,
      pw.Font arabicFont,
      pw.Font emojiFont,
      ) {
    // حساب max للساعات لتحديد طول الأعمدة
    final maxHours = (totalOvertimeHours > totalWaitingHours ? totalOvertimeHours : totalWaitingHours) * 1.2;

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 12),
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#EEF4FF'),
        borderRadius: pw.BorderRadius.circular(18),
        border: pw.Border.all(color: PdfColor.fromHex('#D6E4FF')),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColor(0.1, 0.2, 0.4, 0.12),
            blurRadius: 12,
            offset: const PdfPoint(0, 6),
          ),
        ],
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ====== Chart à gauche ======
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Overtime
                pw.Text(
                  "🧮 إضافية: ${totalOvertimeHours.toStringAsFixed(2)} س",
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontFallback: [emojiFont],
                    fontSize: 12,
                    color: PdfColor.fromHex('#2E7D32'),
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  height: 16,
                  width: (totalOvertimeHours / maxHours) * 150,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#2E7D32'),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                ),
                pw.SizedBox(height: 12),

                // Waiting
                pw.Text(
                  "⌛ انتظار: ${totalWaitingHours.toStringAsFixed(2)} س",
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontFallback: [emojiFont],
                    fontSize: 12,
                    color: PdfColor.fromHex('#EF6C00'),
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  height: 16,
                  width: (totalWaitingHours / maxHours) * 150,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#EF6C00'),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(width: 20),

          // ====== Info à droite ======
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  "👷 الموظف: $employeeName",
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontFallback: [emojiFont],
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  "📅 الشهر: ${month.year}-${month.month.toString().padLeft(2, '0')}",
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontFallback: [emojiFont],
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  "🧮 إجمالي الساعات الإضافية: ${totalOvertimeHours.toStringAsFixed(2)} س",
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontFallback: [emojiFont],
                    fontSize: 13,
                    color: PdfColor.fromHex('#1B5E20'),
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  "⌛ إجمالي ساعات الانتظار: ${totalWaitingHours.toStringAsFixed(2)} س",
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontFallback: [emojiFont],
                    fontSize: 13,
                    color: PdfColor.fromHex('#E65100'),
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildHoursChart(double overtimeHours, double waitingHours, pw.Font arabicFont, pw.Font emojiFont,) {
    final maxHours = (overtimeHours > waitingHours ? overtimeHours : waitingHours) * 1.2; // مسافة للعرض

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F9FF'),
        borderRadius: pw.BorderRadius.circular(18),
        border: pw.Border.all(color: PdfColor.fromHex('#D6E4FF')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            "📊 ملخص الساعات الشهرية",
            style: pw.TextStyle(
              font: arabicFont,
              fontFallback: [emojiFont],
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#022C43'),
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 12),

          // Bar for Overtime
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                "🧮 إضافية: ${overtimeHours.toStringAsFixed(2)} س",
                style: pw.TextStyle(
                  font: arabicFont,
                  fontFallback: [emojiFont],
                  fontSize: 12,
                  color: PdfColor.fromHex('#2E7D32'),
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                height: 16,
                width: (overtimeHours / maxHours) * 200, // max width 200
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#2E7D32'),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          // Bar for Waiting
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                "⌛ انتظار: ${waitingHours.toStringAsFixed(2)} س",
                style: pw.TextStyle(
                  font: arabicFont,
                  fontFallback: [emojiFont],
                  fontSize: 12,
                  color: PdfColor.fromHex('#EF6C00'),
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                height: 16,
                width: (waitingHours / maxHours) * 200,
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#EF6C00'),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<pw.ImageProvider> _imageFromAsset(String path) async {
    final bytes = await rootBundle.load(path);
    return pw.MemoryImage(bytes.buffer.asUint8List());
  }

  static Future<Uint8List> _loadImageFromNetwork(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception("Impossible de charger l'image depuis $url");
    }
  }

  // ---------------- Cards PDF modernes ----------------
  static Future<List<pw.Widget>> buildAttendanceCards(List<Attendance> attendances, pw.Font arabicFont, pw.Font emojiFont,) async {
    List<pw.Widget> cards = [];

    for (var a in attendances) {
      pw.Widget signatureWidget = pw.Container(
        height: 90,
        width: 90,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F5F9FF'),
          borderRadius: pw.BorderRadius.circular(14),
          border: pw.Border.all(color: PdfColor.fromHex('#D6E4FF')),
        ),
        child: pw.Text(
          "—",
          style: pw.TextStyle(fontSize: 20, color: PdfColor.fromHex('#90A4AE')),
        ),
      );

      if (a.signatureUrl != null && a.signatureUrl!.isNotEmpty) {
        final bytes = await _loadImageFromNetwork(a.signatureUrl!);
        signatureWidget = pw.Container(
          height: 90,
          width: 90,
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#FFFFFF'),
            borderRadius: pw.BorderRadius.circular(14),
            border: pw.Border.all(color: PdfColor.fromHex('#D6E4FF')),
          ),
          child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
        );
      }

      cards.add(
        pw.Container(
          margin: const pw.EdgeInsets.symmetric(vertical: 10),
          padding: const pw.EdgeInsets.all(18),
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
              colors: [
                PdfColor.fromHex('#EEF4FF'),
                PdfColor.fromHex('#FFFFFF'),
              ],
            ),
            borderRadius: pw.BorderRadius.circular(22),
            border: pw.Border.all(color: PdfColor.fromHex('#D6E4FF')),
            boxShadow: [
              pw.BoxShadow(
                color: PdfColor(0.1, 0.2, 0.4, 0.12),
                blurRadius: 14,
                offset: const PdfPoint(0, 6),
              ),
            ],
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Signature
              pw.Column(
                children: [
                  signatureWidget,
                  pw.SizedBox(height: 6),
                  pw.Text(
                    "التوقيع",
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 11,
                      color: PdfColor.fromHex('#5C6BC0'),
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ],
              ),

              pw.SizedBox(width: 16),

              // Infos
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // Header
                    pw.Text(
                      "👤 العميل: ${a.customerName ?? "-"}",
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 12,
                        color: PdfColor.fromHex('#3949AB'),
                        fontFallback: [emojiFont], // ✅
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),


                    pw.SizedBox(height: 7),

                    _infoRow("📝 بداية الدوام", _formatTime(a.startTime), arabicFont, emojiFont),

                    _infoRow("📝 نهاية الدوام", _formatTime(a.endTime), arabicFont, emojiFont),

                    if (a.waitingHours != null && a.waitingHours!.isNotEmpty)
                      _infoRow(
                        "⌛الانتظار",
                        "${(double.tryParse(a.waitingHours!)! / 60).toStringAsFixed(2)} س",
                        arabicFont,
                        emojiFont,
                      ),

                    if (a.overtimeHours != null && a.overtimeHours!.isNotEmpty)
                      _infoRow(
                        "🧮 إضافية",
                        "${(double.tryParse(a.overtimeHours!)! / 60).toStringAsFixed(2)} س",
                        arabicFont,
                        emojiFont,
                      ),

                    if (a.notes != null && a.notes!.trim().isNotEmpty)
                      pw.Text(
                        "📝 ملاحظات: ${a.notes ?? "-"}",
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 12,
                          color: PdfColor.fromHex('#3949AB'),
                          fontFallback: [emojiFont], // ✅
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),


                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          "📅 التاريخ: ${_formatDate(a.createdAt)}",
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontSize: 11,
                            color: PdfColor.fromHex('#3949AB'),
                            fontFallback: [emojiFont],
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          "⏰ الساعة: ${_formatClock(a.createdAt)}",
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontSize: 11,
                            color: PdfColor.fromHex('#3949AB'),
                            fontFallback: [emojiFont],
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return cards;
  }

// Helpers
  static pw.Widget _infoRow(
      String label,
      String value,
      pw.Font arabicFont,
      pw.Font emojiFont,
      ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        "$label: $value",
        style: pw.TextStyle(
          font: arabicFont,
          fontSize: 12,
          color: PdfColor.fromHex('#303F9F'),
          fontFallback: [emojiFont], // ✅ ضروري
        ),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }
static  pw.Widget buildAutoGeneratedNotice(pw.Font arabicFont, pw.Font emojiFont) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 20),
        pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 18),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FDECEA'), // أحمر فاتح جداً
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(14)),
              border: pw.Border.all(
                color: PdfColor.fromHex('#D32F2F'),
                width: 0.8,
              ),
            ),
            child: pw.Text(
              "تم إنشاء هذا التقرير تلقائياً عبر نظام الحضور",
              style: pw.TextStyle(
                font: arabicFont,
                fontFallback: [emojiFont],
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#B71C1C'),
              ),
              textAlign: pw.TextAlign.center,
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }



  static String _formatTime(DateTime? t) =>
      t == null ? "-" : "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  static String _formatDate(DateTime? d) =>
      d == null ? "-" : "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  static String _formatClock(DateTime? d) =>
      d == null ? "-" : "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

}




