import 'dart:typed_data';
import 'package:app_bhb/data/auth/models/tasks_tests_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
class TestsSectionBuilder1 {
  final List<Map<String, dynamic>> tests;
  final List<TasksTests> tasks;
  final pw.Font arabicFont;
  final pw.Font emojiFont;

  final Map<String, List<Uint8List>> imagesMap; // bytes images
  final Map<String, String> imageDownloadUrlMap; // urls firebase

  TestsSectionBuilder1({
    required this.tests,
    required this.tasks,
    required this.arabicFont,
    required this.emojiFont,
    required this.imagesMap,
    required this.imageDownloadUrlMap,
  });

  String _buildWebGalleryUrl(String subTestId) {
    return "https://bhbgroup-ed1bc.web.app/test?subTestId=$subTestId";
  }

  pw.Widget build() {
    if (tests.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: tests.map((test) {
        final testTasks = tasks
            .where((t) => t.subTestId == test['id'])
            .take(1)
            .toList();
        return _buildTestBox(test, testTasks);
      }).toList(),
    );
  }


  pw.Widget _buildTestBox(
      Map<String, dynamic> test,
      List<TasksTests> testTasks,
      ) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // ===== HEADER =====
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  PdfColor.fromHex('#0E4D92'),
                  PdfColor.fromHex('#1E6091'),
                ],
              ),
            ),
            child: pw.Text(
              "🧪 ${test['name']}",
              style: pw.TextStyle(
                font: arabicFont,
                fontFallback: [emojiFont],
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.center,
            ),
          ),

          pw.SizedBox(height: 4),

          // ===== BODY =====
          if (testTasks.isEmpty)
            pw.Text(
              "لا توجد مهام مرتبطة بهذا الاختبار",
              style: pw.TextStyle(
                font: arabicFont,
                fontSize: 10,
              ),
              textDirection: pw.TextDirection.rtl,
            )
          else
            ...testTasks.map(_buildTaskBox),

          pw.SizedBox(height: 4),

          // 🔵 Lien cliquable
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.UrlLink(
              destination: _buildWebGalleryUrl(test['id']),
              child: pw.Text(
                "عرض المزيد من الصور",
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 8,
                  color: PdfColors.blue,
                  decoration: pw.TextDecoration.underline,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
            ),
          ),

          pw.SizedBox(height: 1),

          pw.Text(
            "إذا لم يعمل الرابط من واتساب، انسخ الرابط التالي وافتحه في المتصفح:",
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: 7,
              color: PdfColors.grey700,
            ),
            textDirection: pw.TextDirection.rtl,
            textAlign: pw.TextAlign.center,
          ),

          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Text(
              "https://bhbgroup-ed1bc.web.app/test?subTestId=${test['id']}",
              style: pw.TextStyle(
                fontSize: 6,
                color: PdfColors.black,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTaskBox(TasksTests task) {
    final taskId = task.subTestId ?? '';
    final images = (imagesMap[taskId] ?? []).take(2).toList();

    String firebaseInlineImageUrl(String originalUrl) {
      final uri = Uri.parse(originalUrl);
      final params = Map<String, String>.from(uri.queryParameters);
      params['alt'] = 'media';
      params['response-content-disposition'] = 'inline';
      return uri.replace(queryParameters: params).toString();
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4),
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.3),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // 📝 Notes
          if (task.notes != null && task.notes!.isNotEmpty)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    task.notes!,
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontFallback: [emojiFont],
                      fontSize: 9,
                    ),
                    textDirection: pw.TextDirection.rtl,
                    softWrap: true,
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Text(
                  "📝 الملاحظات:",
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontFallback: [emojiFont],
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
              ],
            ),


          pw.SizedBox(height: 4),

          // 📸 Images
          if (images.isNotEmpty)
            pw.Wrap(
              alignment: pw.WrapAlignment.end,
              spacing: 6,
              runSpacing: 6,

            )

        ],
      ),
    );
  }
}
