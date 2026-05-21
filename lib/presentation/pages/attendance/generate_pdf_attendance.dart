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
  static Future<void> generateAndOpenPdf({required List<Attendance> attendances, required String employeeName, required DateTime startDate, required DateTime endDate, required BuildContext context,}) async {
    if (attendances.isEmpty) {
      CustomSnackBar.show(
        context,
        message: "لا توجد بيانات لتصدير PDF",
        type: SnackBarType.info,
      );
      return;
    }

    final pdfBytes = await _generatePdf(attendances, employeeName, startDate, endDate, context);

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
  static Future<Uint8List> _generatePdf(List<Attendance> attendances, String employeeName, DateTime startDate, DateTime endDate, BuildContext context,) async {

    final totalOvertimeHours = attendances.fold<double>(0, (sum, a) {
      return sum + parseArabicDurationToHours(a.overtimeHours ?? "");
    });

    final totalWaitingHours = attendances.fold<double>(0, (sum, a) {
      return sum + parseArabicDurationToHours(a.waitingHours ?? "");
    });

    final totalOvertimeHoursInt = totalOvertimeHours.floor(); // entier
    final totalWaitingHoursInt = totalWaitingHours.floor();   // entier

    final String overtimeHoursText = "$totalOvertimeHoursInt س"; // seulement les heures
    final String waitingHoursText = "$totalWaitingHoursInt س";   // seulement les heures


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

          /// ================= TITRE =================
          pw.Center(
            child: pw.Column(
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
                pw.SizedBox(height: 4),
                pw.Container(
                  height: 4,
                  width: 160,
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

          pw.SizedBox(height: 20),

          /// ================= HEADER EMPLOYEE =================
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F8FAFF'),
              borderRadius: pw.BorderRadius.circular(20),
              border: pw.Border.all(color: PdfColor.fromHex('#DCE6FF')),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [

                /// Period
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "📅 الفترة",
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontFallback: [emojiFont],
                        fontSize: 10,
                        color: PdfColor.fromHex('#6B7280'),
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.Text(
                      "${startDate.toIso8601String().split('T')[0]} إلى ${endDate.toIso8601String().split('T')[0]}",
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontFallback: [emojiFont],
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#022C43'),
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),

                /// Employee
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "👤 الموظف",
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontFallback: [emojiFont],
                        fontSize: 10,
                        color: PdfColor.fromHex('#6B7280'),
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.Text(
                      employeeName,
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontFallback: [emojiFont],
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#022C43'),
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          /// ================= CHART & MINI STAT MODERNE =================
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [

              /// ===== MINI STAT CARDS (même ligne) =====
              pw.Expanded(
                flex: 2,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [

                    pw.Expanded(
                      child: _miniStatCard(
                        title: "🟢 أيام الحضور",
                        value: attendances
                            .where((a) => a.status == "present")
                            .length
                            .toString(),
                        colorHex: "#1B5E20", // vert premium
                        arabicFont: arabicFont,
                        emojiFont: emojiFont,
                      ),
                    ),

                    pw.SizedBox(width: 8), pw.Expanded(
                      child: _miniStatCard(
                        title: "🟢 أيام الاجازة",
                        value: attendances
                            .where((a) => a.status == "conge")
                            .length
                            .toString(),
                        colorHex: "#FF8F00", // vert premium
                        arabicFont: arabicFont,
                        emojiFont: emojiFont,
                      ),
                    ),

                    pw.SizedBox(width: 8),

                    pw.Expanded(
                      child: _miniStatCard(
                        title: "🔴 أيام الغياب",
                        value: attendances
                            .where((a) => a.status == "absent")
                            .length
                            .toString(),
                        colorHex: "#B71C1C", // rouge premium
                        arabicFont: arabicFont,
                        emojiFont: emojiFont,
                      ),
                    ),

                    pw.SizedBox(width: 8),

                    pw.Expanded(
                      child: _miniStatCard(
                        title: "⏱ ساعات إضافية",
                        value: overtimeHoursText,
                        colorHex: "#2E7D32",
                        arabicFont: arabicFont,
                        emojiFont: emojiFont,
                      ),
                    ),

                    pw.SizedBox(width: 8),

                    pw.Expanded(
                      child: _miniStatCard(
                        title: "🕓 ساعات انتظار",
                        value: waitingHoursText,
                        colorHex: "#EF6C00",
                        arabicFont: arabicFont,
                        emojiFont: emojiFont,
                      ),
                    ),

                  ],
                ),
              ),

            ],
          ),

          pw.SizedBox(height: 10),
          /// ================= ATTENDANCE CARDS =================
          ...attendanceWidgets,

        ],
      ),
    );

    return pdf.save();
  }


  static double parseArabicDurationToHours(String text) {
    if (text.trim().isEmpty) return 0;

    final hourRegex = RegExp(r'(\d+)\s*ساعة');
    final minuteRegex = RegExp(r'(\d+)\s*دقيقة');

    int hours = 0;
    int minutes = 0;

    final hourMatch = hourRegex.firstMatch(text);
    if (hourMatch != null) {
      hours = int.tryParse(hourMatch.group(1) ?? "0") ?? 0;
    }

    final minuteMatch = minuteRegex.firstMatch(text);
    if (minuteMatch != null) {
      minutes = int.tryParse(minuteMatch.group(1) ?? "0") ?? 0;
    }

    return hours + (minutes / 60);
  }
  static pw.Widget _miniStatCard({
    required String title,
    required String value,
    required String colorHex,
    required pw.Font arabicFont,
    required pw.Font emojiFont,
  }) {
    final baseColor = PdfColor.fromHex(colorHex);

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: pw.BoxDecoration(
        color: baseColor.shade(0.08),
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(
          color: baseColor.shade(0.4),
          width: 0.8,
        ),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [

          /// VALUE (grand et visible)
          pw.Text(
            value,
            style: pw.TextStyle(
              font: arabicFont,
              fontFallback: [emojiFont],
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),

          pw.SizedBox(height: 4),

          /// TITLE
          pw.Text(
            title,
            textAlign: pw.TextAlign.center,
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              font: arabicFont,
              fontFallback: [emojiFont],
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildMiniHoursChart(double overtimeHours, double waitingHours, pw.Font arabicFont, pw.Font emojiFont,) {
    final maxHours = (overtimeHours > waitingHours ? overtimeHours : waitingHours) * 1.2;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          "📊 ملخص الساعات",
          style: pw.TextStyle(
            font: arabicFont,
            fontFallback: [emojiFont],
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#022C43'),
          ),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 8),

        // Bar ساعات إضافية
        pw.Text(
          "🧮 إضافية: ${overtimeHours.toStringAsFixed(1)} س",
          style: pw.TextStyle(
            font: arabicFont,
            fontFallback: [emojiFont],
            fontSize: 11,
            color: PdfColor.fromHex('#2E7D32'),
          ),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 2),
        pw.Container(
          height: 10,
          width: (overtimeHours / maxHours) * 80, // chart صغير
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#2E7D32'),
            borderRadius: pw.BorderRadius.circular(4),
          ),
        ),

        pw.SizedBox(height: 6),

        // Bar ساعات انتظار
        pw.Text(
          "⌛ انتظار: ${waitingHours.toStringAsFixed(1)} س",
          style: pw.TextStyle(
            font: arabicFont,
            fontFallback: [emojiFont],
            fontSize: 11,
            color: PdfColor.fromHex('#EF6C00'),
          ),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 2),
        pw.Container(
          height: 10,
          width: (waitingHours / maxHours) * 80,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#EF6C00'),
            borderRadius: pw.BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  // ---------------- Helpers ----------------
  static String _formatTime(DateTime? t) =>
      t == null ? "-" : "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  static String _formatDate(DateTime? d) =>
      d == null ? "-" : "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  static String _formatClock(DateTime? d) =>
      d == null ? "-" : "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

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

  // ---------------- Cards PDF ----------------
  static Future<List<pw.Widget>> buildAttendanceCards(List<Attendance> attendances, pw.Font arabicFont, pw.Font emojiFont) async {

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
        try {
          final bytes = await _loadImageFromNetwork(a.signatureUrl!);
          if (bytes.isNotEmpty) {
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
        } catch (_) {
          // الافتراضي
        }
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
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "👤 العميل: ${a.customerName ?? "-"}",
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 12,
                        color: PdfColor.fromHex('#3949AB'),
                        fontFallback: [emojiFont],
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(height: 7),
                    _infoRow("📝 بداية الدوام", _formatTime(a.startTime), arabicFont, emojiFont),
                    _infoRow("📝 نهاية الدوام", _formatTime(a.endTime), arabicFont, emojiFont),
                    if (a.waitingHours != null && a.waitingHours!.trim().isNotEmpty)
                      _infoRow(
                        "⌛ الانتظار",
                        a.waitingHours!,
                        arabicFont,
                        emojiFont,
                      ),
                    if (a.overtimeHours != null && a.overtimeHours!.trim().isNotEmpty)
                      _infoRow(
                        "🧮 إضافية",
                        a.overtimeHours!,  // العرض كما هو في Firebase
                        arabicFont,
                        emojiFont,
                      ),

                    if (a.notes != null && a.notes!.trim().isNotEmpty)
                      pw.Text(
                        "📝 ملاحظات: ${a.notes}",
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 12,
                          color: PdfColor.fromHex('#3949AB'),
                          fontFallback: [emojiFont],
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
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
                    pw.SizedBox(height: 6),
                    if (a.status != null)
                      pw.Text(
                        a.status == "present"
                            ? "✅ الحالة: حاضر"
                            : a.status == "conge"
                            ? "🏖 الحالة: إجازة"
                            : "❌ الحالة: غائب",
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: a.status == "present"
                              ? PdfColor.fromHex('#2E7D32')
                              : a.status == "conge"
                              ? PdfColor.fromHex('#EF6C00')
                              : PdfColor.fromHex('#C62828'),
                          fontFallback: [emojiFont],
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    pw.SizedBox(height: 6),
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

  static pw.Widget _infoRow(String label, String value, pw.Font arabicFont, pw.Font emojiFont,) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        "$label: $value",
        style: pw.TextStyle(
          font: arabicFont,
          fontSize: 12,
          color: PdfColor.fromHex('#303F9F'),
          fontFallback: [emojiFont],
        ),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  static pw.Widget buildAutoGeneratedNotice(pw.Font arabicFont, pw.Font emojiFont) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 20),
        pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 18),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FDECEA'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(14)),
              border: pw.Border.all(color: PdfColor.fromHex('#D32F2F'), width: 0.8),
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
}




