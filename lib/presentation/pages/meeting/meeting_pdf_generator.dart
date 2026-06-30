import 'package:app_bhb/data/auth/models/meeting_model.dart';
import 'package:app_bhb/presentation/pages/engineers_evaluation/common_pdf_header_footer.dart';
import 'package:flutter/cupertino.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';


class MeetingPdfGenerator {
  static Future<pw.Document> generate({
    required Meeting meeting,
  }) async {


    final pdf = pw.Document();
// 🔹 Images avec remarques
    List<Map<String, dynamic>> imagesWithRemarks = [];

    if (meeting.imageUrlsWithRemarks != null &&
        meeting.imageUrlsWithRemarks!.isNotEmpty) {
      for (final item in meeting.imageUrlsWithRemarks!) {
        final img = await imageFromUrl(item['url']);
        if (img != null) {
          imagesWithRemarks.add({
            "image": img,
            "remark": item['remark'] ?? "",
          });
        }
      }
    }

    // ⚠️ Police arabe et emoji
    final arabicFont = pw.Font.ttf(await rootBundle.load("assets/font/NotoSansArabic-Regular.ttf"));
    final emojiFont = pw.Font.ttf(await rootBundle.load("assets/font/NotoEmoji-Regular.ttf"));

    // 🔹 Images du meeting (plusieurs)
    List<pw.ImageProvider> meetingImages = [];
    if (meeting.imageUrls != null && meeting.imageUrls!.isNotEmpty) {
      for (final url in meeting.imageUrls!) {
        final img = await imageFromUrl(url);
        if (img != null) meetingImages.add(img);
      }
    }

    // 🔹 Signature (une seule)
    final signatureImage = await imageFromUrl(meeting.signatureUrl);

    // 🔹 Logos & emojis pour footer/header
    final logo = await imageFromAssetBundle("assets/img/app_logo.png");
    final fbEmoji = await imageFromAssetBundle("assets/img/fb.png");
    final googleEmoji = await imageFromAssetBundle("assets/img/google.png");
    final linkedInEmoji = await imageFromAssetBundle("assets/img/in.png");

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 100,
        textDirection: pw.TextDirection.rtl,
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
        build: (_) {
          final List<pw.Widget> widgets = [];

          widgets.add(
            _buildTitle(arabicFont, emojiFont, meeting),
          );

          widgets.add(
            pw.SizedBox(height: 20),
          );

          widgets.add(
            _buildMeetingInfo(
              meeting,
              arabicFont,
            ),
          );

          if (imagesWithRemarks.isNotEmpty) {
            widgets.add(
              pw.SizedBox(height: 22),
            );

            widgets.add(
              pw.Text(
                "صور الاجتماع مع الملاحظات",
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#022C43'),
                ),
              ),
            );

            widgets.add(
              pw.SizedBox(height: 12),
            );

            for (final item in imagesWithRemarks) {
              widgets.add(
                pw.Container(
                  height: 220,
                  width: double.infinity,
                  child: pw.ClipRRect(
                    horizontalRadius: 12,
                    verticalRadius: 12,
                    child: pw.Image(
                      item["image"],
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              );

              if ((item["remark"] as String).trim().isNotEmpty) {
                widgets.add(
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 8, bottom: 20),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F5F5F5'),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Text(
                      item["remark"],
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }
            }
          }

          if (signatureImage != null) {
            widgets.add(
              _buildSignature(
                signatureImage,
                arabicFont,
              ),
            );
          }

          return widgets;
        },
      ),
    );

    return pdf;
  }

  // =============================
  static Future<pw.ImageProvider> imageFromAssetBundle(String path) async {
    final bytes = await rootBundle.load(path);
    return pw.MemoryImage(bytes.buffer.asUint8List());
  }

  static Future<pw.ImageProvider?> imageFromUrl(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      return await networkImage(url);
    } catch (e) {
      debugPrint("❌ Image load failed: $e");
      return null;
    }
  }
  static pw.Widget _buildMeetingInfo(
      Meeting meeting,
      pw.Font arabicFont,
      ) {
    String formatDate(DateTime? date) {
      if (date == null) return "-";
      return DateFormat('yyyy/MM/dd').format(date);
    }

    pw.Widget infoRow(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 90,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#022C43'),
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 12,
                  color: PdfColors.grey800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(16),
        border: pw.Border.all(color: PdfColors.grey300),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColors.grey300,
            blurRadius: 6,
            offset: const PdfPoint(0, 3),
          ),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          infoRow("عنوان الاجتماع", meeting.titleMeeting ?? "-"),
          infoRow("وصف الاجتماع", meeting.description ?? "-"),
          infoRow("نوع الاجتماع", meeting.type ?? "-"),
          infoRow("المهندس", meeting.nameEngineer ?? "-"),
          infoRow("الموظف", meeting.nameEmployee ?? "-"),
          infoRow("العميل", meeting.nameCustomer ?? "-"),
          infoRow("تاريخ الاجتماع", formatDate(meeting.dateMeeting)),
        ],
      ),
    );
  }
  static pw.Widget _buildImageCard(
      Map<String, dynamic> item,
      pw.Font arabicFont,
      ) {
    final pw.ImageProvider img = item["image"];
    final String remark = item["remark"];

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 18),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.ClipRRect(
            horizontalRadius: 12,
            verticalRadius: 12,
            child: pw.Container(
              constraints: const pw.BoxConstraints(
                maxHeight: 250,
              ),
              child: pw.Image(
                img,
                fit: pw.BoxFit.contain,
              ),
            ),
          ),
          if (remark.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F5F5F5'),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Text(
                remark,
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 12,
                  color: PdfColors.grey800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  static pw.Widget _buildSignature(
      pw.ImageProvider signatureImage,
      pw.Font arabicFont,
      ) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 26),

        pw.Text(
          "توقيع",
          style: pw.TextStyle(
            font: arabicFont,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#022C43'),
          ),
        ),

        pw.SizedBox(height: 10),

        pw.Container(
          height: 120,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(14),
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          child: pw.Image(
            signatureImage,
            fit: pw.BoxFit.contain,
          ),
        ),

        pw.SizedBox(height: 20),

        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 12,
          ),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#FDE2E2'),
            borderRadius: const pw.BorderRadius.all(
              pw.Radius.circular(8),
            ),
            border: pw.Border.all(
              color: PdfColor.fromHex('#D32F2F'),
              width: 1,
            ),
          ),
          child: pw.Text(
            "يُعتبر هذا التقرير نهائيًا ومعتمدًا تلقائيًا بعد مرور 48 ساعة من تاريخ إرساله، ما لم يُقدَّم اعتراض خطي ومعتمد خلال هذه الفترة.",
            textAlign: pw.TextAlign.center,
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#B71C1C'),
            ),
          ),
        ),

        pw.SizedBox(height: 20),
      ],
    );
  }
  // =============================
  static pw.Widget _buildTitle(pw.Font arabicFont, pw.Font emojiFont, Meeting meeting) {
    return pw.Center(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            "محضر اجتماع ${meeting.titleMeeting ?? ""}",
            style: pw.TextStyle(
              font: arabicFont,
              fontFallback: [emojiFont],
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#022C43'),
            ),
            textDirection: pw.TextDirection.rtl,
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 3),
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
    );
  }

}

