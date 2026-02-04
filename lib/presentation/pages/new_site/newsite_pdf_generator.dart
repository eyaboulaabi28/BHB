import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/data/auth/models/newsite_model.dart';
import 'package:app_bhb/presentation/pages/engineers_evaluation/common_pdf_header_footer.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';


class NewSitePdfGenerator {
  static Future<pw.Document> generate({required NewSite site,required BuildContext context}) async {

    CustomSnackBar.show(
      context,
      message: " جاري إنشاء ملف PDF...",
      type: SnackBarType.loading,
      duration: const Duration(seconds: 300),
    );

    final pdf = pw.Document();
    String locationText = "غير معروف";
    final PdfColor primaryYellow = PdfColor.fromHex('#B8860B');

    Future<String> getAddressFromLatLng(double lat, double lng) async {
      try {

        if (kIsWeb) {
          final url = Uri.parse(
              "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1&accept-language=ar");

          final response = await http.get(url);
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            return data["display_name"] ?? "غير معروف";
          } else {
            return "غير معروف";
          }
        }
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isEmpty) return "غير معروف";

        final p = placemarks.first;

        final locality = p.locality ?? "";
        final street = p.street ?? "";
        final country = p.country ?? "";

        if (locality.isEmpty && street.isEmpty && country.isEmpty) {
          return "غير معروف";
        }

        return "$locality - $street - $country".trim();
      } catch (e) {
        print("Reverse Geocoding Error: $e");
        return "غير معروف";
      }
    }

    if (site.latitude != null && site.longitude != null) {
      locationText = await getAddressFromLatLng(
        site.latitude!,
        site.longitude!,
      );
    }

    String formatDateOnly(DateTime? date) {
      if (date == null) return "-";
      return "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year}";
    }
    // ===== Fonts =====
    final arabicFont = pw.Font.ttf(
      await rootBundle.load("assets/font/NotoSansArabic-Regular.ttf"),
    );
    final emojiFont = pw.Font.ttf(
      await rootBundle.load("assets/font/NotoEmoji-Regular.ttf"),
    );


    /*******************/

    pw.Widget buildTaskCard({required String title,required pw.Widget content,}) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white, // corps du card blanc
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300),
          boxShadow: [
            pw.BoxShadow(
              color: PdfColors.grey300,
              blurRadius: 1.5,
              spreadRadius: 0.3,
            ),
          ],
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ===== Card Title avec dégradé jaune comme isAlternate =====
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [primaryYellow, PdfColor.fromHex('#E6C200')],
                  begin: pw.Alignment.centerLeft,
                  end: pw.Alignment.centerRight,
                ),
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(8),
                  topRight: pw.Radius.circular(8),
                ),
              ),
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  font: arabicFont,
                  fontFallback: [emojiFont],
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 6),
            // ===== Contenu =====
            content,
          ],
        ),
      );
    }
    pw.Widget buildGeneralRemarkCard(String generalRemarkText, pw.Font arabicFont, pw.Font emojiFont) {
      final PdfColor primaryBlue = PdfColor.fromHex('#21206C'); // header principal bleu
      final PdfColor primaryYellow = PdfColor.fromHex('#B8860B'); // header interne jaune
      final PdfColor textColor = PdfColor.fromHex('#333333');

      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white, // corps principal blanc
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300),
          boxShadow: [
            pw.BoxShadow(
              color: PdfColors.grey300,
              blurRadius: 1.5,
              spreadRadius: 0.3,
            ),
          ],
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ===== Header principal bleu =====
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: primaryBlue,
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(8),
                  topRight: pw.Radius.circular(8),
                ),
              ),
              child: pw.Text(
                "ملاحظات تقرير الاشراف",
                style: pw.TextStyle(
                  font: arabicFont,
                  fontFallback: [emojiFont],
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 6),

            // ===== Card interne jaune (header jaune, corps blanc) =====
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.white, // corps interne blanc
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // header interne jaune
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      gradient: pw.LinearGradient(
                        colors: [primaryYellow, PdfColor.fromHex('#E6C200')],
                        begin: pw.Alignment.centerLeft,
                        end: pw.Alignment.centerRight,
                      ),
                      borderRadius: const pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(6),
                        topRight: pw.Radius.circular(6),
                      ),
                    ),
                    child: pw.Text(
                      "ملاحظات",
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontFallback: [emojiFont],
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(height: 4),

                  // contenu généralRemark
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: pw.Text(
                      generalRemarkText.isNotEmpty ? generalRemarkText : "-",
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontFallback: [emojiFont],
                        fontSize: 12,
                        color: textColor,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }


    // ===== Assets =====
    final logo = await _imageFromAsset("assets/img/app_logo.png");
    final fbEmoji = await _imageFromAsset("assets/img/fb.png");
    final googleEmoji = await _imageFromAsset("assets/img/google.png");
    final linkedInEmoji = await _imageFromAsset("assets/img/in.png");
    final Map<String, pw.ImageProvider> taskImages = {};
    for (final task in site.task.items) {
      if (task.imageUrl.isNotEmpty) {
        try {
          final image = await networkImage(task.imageUrl);
          taskImages[task.imageUrl] = image;
        } catch (e) {
          print("Image load error: $e");
        }
      }
    }

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
          pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
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
                pw.SizedBox(height:3),
                pw.Container(
                  height: 4,
                  width: 150,
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [
                        PdfColor.fromHex('#FFD700'),
                        PdfColor.fromHex('#022C43'),
                      ],
                    ),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          if (site != null) ...[
            pw.SizedBox(height: 8),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Ligne 1 (bleu foncé)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    buildInfoBox(site?.projectName ?? "-", "اسم المشروع", "Project Name", arabicFont, emojiFont, icon: "📝",),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    buildInfoBox(site?.customerName ?? "-", "اسم المالك", "Owner's Name", arabicFont, emojiFont, icon: "👤",isAlternate: true),
                    pw.SizedBox(width: 4),
                    buildInfoBox(site?.phone ?? "-", "الهاتف", "Phone", arabicFont, emojiFont, icon: "📞",isAlternate: true),
                  ],
                ),
                pw.SizedBox(height: 10),
                // Ligne 2
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    buildInfoBox(locationText, "الموقع", "Location", arabicFont, emojiFont, icon: "🌍",),                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [

                    buildInfoBox(site?.nameEngineer ?? "-", "اسم المهندس المشرف", "Name Of Supervising Engineer", arabicFont, emojiFont, icon: "👷 ", isAlternate: true),
                    pw.SizedBox(width: 4),
                    buildInfoBox(
                      formatDateOnly(site.createdAt),
                      "تاريخ التقرير",
                      "Report date",
                      arabicFont,
                      emojiFont,
                      icon: "📅",
                      isAlternate: true,
                    ),
                    pw.SizedBox(width: 4),

                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    buildInfoBox( "جميع الصور و الملاحظات الخاصة بزيارة المشروع موجودة في الصفحات اللاحقة.⬇️⬇️⬇️", "الصور و الملاحظات الخاصة بالمشروع", "All images and notes related to the project.", arabicFont, emojiFont, icon: "📋",),
                    pw.SizedBox(width: 8),
                  ],
                ),

              ],
            ),
          ],
          pw.SizedBox(height: 25),





         // ✅ Liste des tasks (images + remarques)
          ...site.task.items.map((task) {
            final image = taskImages[task.imageUrl];

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // ===== HEADER =====
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [
                        PdfColor.fromHex('#21206C'),
                        PdfColor.fromHex('#1E6091'),
                      ],
                    ),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "📝 اسم المشروع : ${site.projectName ?? '-'}",
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontFallback: [emojiFont],
                          fontSize: 11,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.Text(
                        "👤 اسم المالك : ${site.customerName ?? '-'}",
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontFallback: [emojiFont],
                          fontSize: 10,
                          color: PdfColors.white,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ],
                  ),
                ),

                // ===== IMAGE CARD =====
                if (image != null)
                  buildTaskCard(
                    title: "صورة",
                    content: pw.Center(
                      child: pw.ClipRRect(
                        horizontalRadius: 6,
                        verticalRadius: 6,
                        child: pw.Container(
                          width: 300,
                          height: 300,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            border: pw.Border.all(color: PdfColors.grey300),
                          ),
                          child: pw.Image(image, fit: pw.BoxFit.contain),
                        ),
                      ),
                    ),
                  ),

                // ===== REMARK CARD =====
                buildTaskCard(
                  title: "ملاحظة",
                  content: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6),
                    child: pw.Text(
                      "• ${task.remark}",
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontFallback: [emojiFont],
                        fontSize: 12,
                        color: PdfColor.fromHex('#333333'),
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ),
                ),
              ],
            );
          }),

         // ✅ Carte General Remark
          pw.SizedBox(height: 12),
          if (site.generalRemark != null && site.generalRemark!.trim().isNotEmpty)
            buildGeneralRemarkCard(site.generalRemark!, arabicFont, emojiFont),





        ],
      ),
    );

    final pdfBytes = await pdf.save();
    if (kIsWeb) {

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'تفاصيل_زيارة_الموقع.pdf',
      );


      CustomSnackBar.show(
        context,
        message: "✅ تم تحميل ملف PDF بنجاح!",
        type: SnackBarType.success,
      );
    } else {
      final dir = await getTemporaryDirectory();
      final file = io.File('${dir.path}/تفاصيل_زيارة_الموقع.pdf');
      await file.writeAsBytes(pdfBytes);

      final phone = site!.phone ?? "";
      final sanitizedPhone = phone.replaceAll("+", "").trim();

      await Share.shareXFiles(
        [XFile(file.path)],
        text: "👋 مرحبا، هذا تقرير تفاصيل زيارةالموقع.",
        subject: "تقرير تفاصيل زيارةالموقع",
      );

      if (sanitizedPhone.isNotEmpty) {
        final whatsappUrl = "https://wa.me/$sanitizedPhone";
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
      }

      CustomSnackBar.show(
        context,
        message: "📤 تم إرسال التقرير بنجاح",
        type: SnackBarType.success,
      );

    }
    return pdf;
  }


  static pw.Expanded buildInfoBox(String value, String titleAr, String titleEn, pw.Font arabicFont, pw.Font emojiFont, {String? icon, bool isAlternate = false,}) {
    final PdfColor primaryColor = isAlternate ? PdfColor.fromHex('#B8860B') : PdfColor.fromHex('#21206C');
    final PdfColor textColor = PdfColor.fromHex('#333333');

    return pw.Expanded(
      child: pw.Container(
        width: 160,
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
          boxShadow: [
            pw.BoxShadow(
              color: PdfColors.grey300,
              blurRadius: 1.5,
              spreadRadius: 0.3,
            ),
          ],
        ),
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: isAlternate
                      ? [primaryColor, PdfColor.fromHex('#E6C200')] // dégradé jaune
                      : [primaryColor, PdfColor.fromHex('#1E6091')],
                ),
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(6),
                  topRight: pw.Radius.circular(6),
                ),
              ),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    titleAr,
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontFallback: [emojiFont],
                      fontSize: 10.5,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textDirection: pw.TextDirection.rtl,
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    titleEn,
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontFallback: [emojiFont],
                      fontSize: 8.5,
                      color: PdfColors.white,
                    ),
                    textDirection: pw.TextDirection.ltr,
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
              alignment: pw.Alignment.center,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  if (icon != null)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(right: 3),
                      child: pw.Text(
                        icon,
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontFallback: [emojiFont],
                          fontSize: 11.5,
                          color: textColor,
                        ),
                      ),
                    ),
                  pw.Flexible(
                    child: pw.Text(
                      value.isEmpty ? '-' : value,
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontFallback: [emojiFont],
                        fontSize: 11.5,
                        color: textColor,
                      ),
                      textAlign: pw.TextAlign.center,
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<pw.ImageProvider> _imageFromAsset(String path) async {
    final bytes = await rootBundle.load(path);
    return pw.MemoryImage(bytes.buffer.asUint8List());
  }




}
