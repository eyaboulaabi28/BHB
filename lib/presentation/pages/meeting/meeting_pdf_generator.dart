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
        build: (_) => [
          _buildTitle(arabicFont, emojiFont, meeting),
          pw.SizedBox(height: 20),
          _buildMeetingInfo(
            meeting,
            arabicFont,
            meetingImages: meetingImages,
            signatureImage: signatureImage,
          ),
        ],
      ),
    );

    return pdf;
  }

  // =============================

  static pw.Widget _buildMeetingInfo(
      Meeting meeting,
      pw.Font arabicFont, {
        List<pw.ImageProvider>? meetingImages,
        pw.ImageProvider? signatureImage,
      }) {
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

    List<pw.Widget> imageWidgets = [];
    if (meetingImages != null && meetingImages.isNotEmpty) {
      for (final img in meetingImages) {
        imageWidgets.add(
          pw.Container(
            height: 200,
            margin: const pw.EdgeInsets.only(bottom: 12),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(14),
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.ClipRRect(
              horizontalRadius: 14,
              verticalRadius: 14,
              child:pw.Image(img, fit: pw.BoxFit.contain),
            ),
          ),
        );
      }
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
          // 🔹 Infos
          infoRow("عنوان الاجتماع", meeting.titleMeeting ?? "-"),
          infoRow("وصف الاجتماع", meeting.description ?? "-"),
          infoRow("نوع الاجتماع", meeting.type ?? "-"),
          infoRow("المهندس", meeting.nameEngineer ?? "-"),
          infoRow("الموظف", meeting.nameEmployee ?? "-"),
          infoRow("العميل", meeting.nameCustomer ?? "-"),
          infoRow("تاريخ الاجتماع", formatDate(meeting.dateMeeting)),

          // 🔸 Images
          // 🔸 Images
          if (meetingImages != null && meetingImages.isNotEmpty) ...[
            pw.SizedBox(height: 22),
            pw.Text(
              "صور الاجتماع",
              style: pw.TextStyle(
                font: arabicFont,
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#022C43'),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: meetingImages.map((img) {
                return pw.Container(
                  width: 180,
                  height: 180,
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(14),
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 14,
                    verticalRadius: 14,
                    child: pw.Image(img, fit: pw.BoxFit.contain),
                  ),
                );
              }).toList(),
            ),

            // 🔹 COMMENTAIRE CLIENT
            if (meeting.commentCtrl != null && meeting.commentCtrl!.isNotEmpty) ...[
              pw.SizedBox(height: 18),
              pw.Text(
                "ملاحظات الاجتماع:",
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#022C43'),
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 6),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F0F0F0'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  meeting.commentCtrl!,
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontSize: 12,
                    color: PdfColors.black,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
              ),
            ],
          ],


          // 🔸 Signature
          if (signatureImage != null && meeting.type == "مع العميل") ...[
            pw.SizedBox(height: 26),
            pw.Text(
              "توقيع العميل",
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
              child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
            ),
          ],

          // ─────────── Paragraphe final ⚠️ ───────────
          pw.SizedBox(height: 20),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FDE2E2'), // fond rouge clair
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColor.fromHex('#D32F2F'), width: 1), // bordure rouge foncé
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    "  يُعتبر هذا التقرير نهائيًا ومعتمدًا تلقائيًا بعد مرور 48 ساعة من تاريخ إرساله، ما لم يُقدَّم اعتراض خطي ومعتمد خلال هذه الفترة. ",
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#B71C1C'), // texte rouge foncé
                    ),
                    textAlign: pw.TextAlign.center,
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
        ],
      ),
    );

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

