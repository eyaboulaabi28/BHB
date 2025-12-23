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



    // ⚠️ أنصحك مؤقتًا بدون emojiFont (أكثر استقرار)
    final arabicFont = pw.Font.ttf(await rootBundle.load("assets/font/NotoSansArabic-Regular.ttf"));
    final emojiFont = pw.Font.ttf(await rootBundle.load("assets/font/NotoEmoji-Regular.ttf"));
    final meetingImage = await imageFromUrl(meeting.imageUrl);
    final signatureImage = await imageFromUrl(meeting.signatureUrl);

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
            meetingImage: meetingImage,
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
        pw.ImageProvider? meetingImage,
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

          // 🔹 INFORMATIONS
          infoRow("عنوان الاجتماع", meeting.titleMeeting ?? "-"),
          infoRow("وصف الاجتماع", meeting.description ?? "-"),
          infoRow("نوع الاجتماع", meeting.type ?? "-"),
          infoRow("المهندس", meeting.nameEngineer ?? "-"),
          infoRow("الموظف", meeting.nameEmployee ?? "-"),
          infoRow("العميل", meeting.nameCustomer ?? "-"),
          infoRow("تاريخ الاجتماع", formatDate(meeting.dateMeeting)),

          // 🔸 IMAGE MEETING
          if (meetingImage != null) ...[
            pw.SizedBox(height: 22),
            pw.Text(
              " صورة الاجتماع",
              style: pw.TextStyle(
                font: arabicFont,
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#022C43'),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              height: 200,
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(14),
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 14,
                verticalRadius: 14,
                child: pw.Image(
                  meetingImage,
                  fit: pw.BoxFit.cover,
                ),
              ),
            ),
          ],

          // 🔸 SIGNATURE CLIENT
          if (signatureImage != null && meeting.type == "مع العميل") ...[
            pw.SizedBox(height: 26),
            pw.Text(
              " توقيع العميل",
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
          ],
        ],
      ),
    );
  }


  static Future<pw.ImageProvider> imageFromAssetBundle(String path) async {
    final bytes = await rootBundle.load(path);
    return pw.MemoryImage(bytes.buffer.asUint8List());
  }
  // =============================
// 🧾 TITLE MODERNE
  static pw.Widget _buildTitle(
      pw.Font arabicFont,
      pw.Font emojiFont,
      Meeting meeting,
      ) {
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
              borderRadius: const pw.BorderRadius.all(
                pw.Radius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
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


}
