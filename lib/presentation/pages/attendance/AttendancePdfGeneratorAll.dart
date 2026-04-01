import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/data/auth/models/attendance_model.dart';
import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

class AttendancePdfGeneratorAll {
  static Future<void> generateAndOpenPdf({
    required List<Employees> employees,
    required Map<String, List<Attendance>> allAttendances, // clé = employeeId
    required BuildContext context,
  }) async {
    if (allAttendances.isEmpty) {
      CustomSnackBar.show(
        context,
        message: "لا توجد بيانات لتصدير PDF",
        type: SnackBarType.info,
      );
      return;
    }

    // Générer le PDF
    final pdfBytes = await _generatePdf(allAttendances, employees, context);

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
          text: "👋 مرحبا، هذا تقرير الحضور للموظفين.",
          subject: "تقرير الحضور",
        );

        final whatsappNumber = "+966560952288";
        final whatsappUrl =
            "https://wa.me/${whatsappNumber.replaceAll("+", "").trim()}?text=👋 مرحبا، هذا تقرير الحضور للموظفين.";
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
  static String _formatMinutes(double totalMinutes) {
    int hours = totalMinutes ~/ 60;
    int minutes = (totalMinutes % 60).round();

    return "$hours ساعة و $minutes دقيقة";
  }

  static Future<Uint8List> _generatePdf(
      Map<String, List<Attendance>> allAttendances,
      List<Employees> employees,
      BuildContext context,
      ) async {

    CustomSnackBar.show(
      context,
      message: "جاري إنشاء ملف PDF...",
      type: SnackBarType.loading,
      duration: const Duration(seconds: 300),
    );

    final pdf = pw.Document();

    // 🔹 Fonts
    final arabicFont = pw.Font.ttf(await rootBundle.load("assets/font/NotoSansArabic-Regular.ttf"));
    final emojiFont = pw.Font.ttf(await rootBundle.load("assets/font/NotoEmoji-Regular.ttf"));

    final logo = await _imageFromAsset("assets/img/app_logo.png");
    final fbEmoji = await _imageFromAsset("assets/img/fb.png");
    final googleEmoji = await _imageFromAsset("assets/img/google.png");
    final linkedInEmoji = await _imageFromAsset("assets/img/in.png");

    // 🔹 Styles
    final pw.TextStyle arabicStyle = pw.TextStyle(
      font: arabicFont,
      fontFallback: [emojiFont],
      fontSize: 12,
      color: PdfColor.fromHex('#022C43'),
    );

    final pw.TextStyle titleStyle = pw.TextStyle(
      font: arabicFont,
      fontFallback: [emojiFont],
      fontSize: 15,
      fontWeight: pw.FontWeight.bold,
      color: PdfColor.fromHex('#022C43'),
    );

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
        build: (context) {
          List<pw.Widget> content = [];

          // ===== TITRE =====
          content.add(
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    "تقرير مفصل حول سجل حضور الموظفين",
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
                  pw.SizedBox(height: 20),
                ],
              ),
            ),
          );

        // 🔹 Grouper les employés par 2 pour les afficher côte à côte
          for (int i = 0; i < employees.length; i += 2) {
            List<pw.Widget> rowChildren = [];

            for (int j = i; j < i + 2 && j < employees.length; j++) {

              final employee = employees[j];
              final attendances = allAttendances[employee.id] ?? [];

              final now = DateTime.now();

              final monthlyAttendances = attendances.where((a) =>
              a.startTime != null &&
                  a.startTime!.year == now.year &&
                  a.startTime!.month == now.month
              ).toList();

              final presentDays =
              monthlyAttendances.where((a) => a.status == 'present').toList();

              final absentDays =
              monthlyAttendances.where((a) => a.status == 'absent').toList();

              double totalWorkMinutes = 0;
              double totalWaitingMinutes = 0;
              double totalOvertimeMinutes = 0;

              for (var a in presentDays) {

                /// 🟢 Total heures de travail
                if (a.startTime != null && a.endTime != null) {
                  totalWorkMinutes +=
                      a.endTime!.difference(a.startTime!).inMinutes;
                }

                /// ⏳ Total heures attente
                if (a.waitingHours != null) {
                  totalWaitingMinutes += _parseHourMinute(a.waitingHours!);
                }

                /// ⏰ Total heures supplémentaires
                if (a.overtimeHours != null) {
                  totalOvertimeMinutes += _parseHourMinute(a.overtimeHours!);
                }
              }

              /// 🔥 Conversion correcte en heure + minute
              final workFormatted = _formatMinutes(totalWorkMinutes);
              final waitingFormatted = _formatMinutes(totalWaitingMinutes);
              final overtimeFormatted = _formatMinutes(totalOvertimeMinutes);

              rowChildren.add(
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    margin: const pw.EdgeInsets.only(right: 8, bottom: 16),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F8FAFF'),
                      borderRadius: pw.BorderRadius.circular(16),
                      border: pw.Border.all(color: PdfColor.fromHex('#DCE6FF')),
                    ),
                    child: pw.Align(
                      alignment: pw.Alignment.topRight,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [

                          pw.Text(
                            "👤 ${employee.firstName ?? "-"}",
                            style: titleStyle,
                            textDirection: pw.TextDirection.rtl,
                          ),

                          pw.SizedBox(height: 6),

                          pw.Text(
                            "⏳مجموع ساعات الانتظار:$waitingFormatted",
                            style: arabicStyle,
                            textDirection: pw.TextDirection.rtl,
                          ),

                          pw.Text(
                            "⏰مجموع ساعات العمل الإضافية:$overtimeFormatted",
                            style: arabicStyle,
                            textDirection: pw.TextDirection.rtl,
                          ),

                          pw.Text(
                            "🟢 عدد أيام الحضور: ${presentDays.length}",
                            style: arabicStyle,
                            textDirection: pw.TextDirection.rtl,
                          ),

                          pw.Text(
                            "🔴 عدد أيام الغياب: ${absentDays.length}",
                            style: arabicStyle,
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            content.add(
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: rowChildren,
              ),
            );
          }


          return content;
        },
      ),
    );

    return pdf.save();
  }

  /// 🔹 Convertit "5 ساعة و 55 دقيقة" en minutes
  static double _parseHourMinute(String str) {
    int hours = 0;
    int minutes = 0;

    final hourReg = RegExp(r'(\d+)\s*ساعة');
    final minuteReg = RegExp(r'(\d+)\s*دقيقة');

    final hourMatch = hourReg.firstMatch(str);
    final minuteMatch = minuteReg.firstMatch(str);

    if (hourMatch != null) hours = int.parse(hourMatch.group(1)!);
    if (minuteMatch != null) minutes = int.parse(minuteMatch.group(1)!);

    return (hours * 60 + minutes).toDouble(); // <-- convertir en double ici
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
}
