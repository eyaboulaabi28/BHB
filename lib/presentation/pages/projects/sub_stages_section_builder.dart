import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:app_bhb/data/auth/models/sub_stages_model.dart';
import 'package:app_bhb/data/auth/models/tasks_model.dart';


class SubStagesSectionBuilder {
  final List<SubStage> subStages;
  final List<Tasks> tasks;
  final Map<String, List<Uint8List>> imagesBeforeMap;
  final Map<String, List<Uint8List>> imagesAfterMap;
  final pw.Font arabicFont;
  final pw.Font emojiFont;
  final Map<String, String> imageDownloadUrlMap;

  SubStagesSectionBuilder({
    required this.subStages,
    required this.tasks,
    required this.imagesBeforeMap,
    required this.imagesAfterMap,
    required this.arabicFont,
    required this.emojiFont,
    required this.imageDownloadUrlMap,

  });

  List<String> _collectRemainingImages(SubStage subStage) {
    final List<String> urls = [];

    final subTasks = tasks
        .where((t) => t.subStageId?.trim() == subStage.id?.trim());

    for (final t in subTasks) {
      final before = t.imagesBefore ?? [];
      final after  = t.imagesAfter ?? [];

      if (before.length > 1) {
        urls.addAll(before.skip(1));
      }
      if (after.length > 1) {
        urls.addAll(after.skip(1));
      }
    }

    return urls
        .map((u) => imageDownloadUrlMap[u])
        .whereType<String>()
        .toList();
  }
  String _buildWebGalleryUrl(String subStageId) {
    return "https://bhbgroup-ed1bc.web.app/substage.html?subStageId=$subStageId";
  }
  pw.Widget build() {
    if (subStages.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: subStages.map((subStage) {
        final subTasks = tasks
            .where((t) => t.subStageId?.trim() == subStage.id?.trim())
            .toList();
        return _buildSubStageBox(subStage, subTasks);
      }).toList(),
    );
  }

  pw.Widget _buildSubStageBox(SubStage subStage, List<Tasks> subTasks) {

    // 1️⃣ جمع الصور الإضافية لهذا SubStage
    final remainingImages = _collectRemainingImages(subStage);

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [

          // ================= HEADER =================
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  PdfColor.fromHex('#0E4D92'),
                  PdfColor.fromHex('#1E6091'),
                ],
              ),
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Text(
              subStage.subStageName ?? '-',
              style: pw.TextStyle(
                font: arabicFont,
                fontFallback: [emojiFont],
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              textAlign: pw.TextAlign.center,
              textDirection: pw.TextDirection.rtl,
            ),
          ),

          pw.SizedBox(height: 2),

          // ================= BODY =================
          subTasks.isEmpty
              ? pw.Text(
            "لا توجد مهام مضافة لهذه المرحلة الفرعية.",
            style: pw.TextStyle(
              font: arabicFont,
              fontFallback: [emojiFont],
              fontSize: 11,
              color: PdfColors.grey700,
            ),
            textDirection: pw.TextDirection.rtl,
          )
              : pw.Column(
            children: [
              _buildTaskBox(subTasks.first, 1),
            ],
          ),

          // ================= 🔗 LINK =================
          ...[
            pw.SizedBox(height:2),
            // 🔵 Lien cliquable (Web / Drive / PC)
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.UrlLink(
                destination: _buildWebGalleryUrl(subStage.id!),
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
            // 🟢 URL AFFICHÉE EN CLAIR (COPIABLE)
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Text(
                "https://bhbgroup-ed1bc.web.app/substage.html?subStageId=${subStage.id}",
                style: pw.TextStyle(
                  fontSize: 6,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ]

        ],
      ),
    );
  }

  pw.Widget _buildTaskBox(Tasks task, int taskNumber) {
    final beforeImages = (imagesBeforeMap[task.id ?? ''] ?? []).take(1).toList();
    final afterImages = (imagesAfterMap[task.id ?? ''] ?? []).take(1).toList();
    String firebaseInlineImageUrl(String originalUrl) {
      final uri = Uri.parse(originalUrl);
      final params = Map<String, String>.from(uri.queryParameters);

      // ✅ FORCER le téléchargement du fichier
      params['alt'] = 'media';

      // ✅ affichage inline (pas download forcé)
      params['response-content-disposition'] = 'inline';

      return uri.replace(queryParameters: params).toString();
    }
    pw.Widget _buildBeforeAfterImages({
      required List<List<int>> beforeImages,
      required List<List<int>> afterImages,
      List<String>? beforeUrls,
      List<String>? afterUrls,
    }) {
      pw.Widget buildImage(List<int> bytes, String? url) {
        final safeUrl = url != null ? imageDownloadUrlMap[url.trim()] : null;
        final inlineUrl =
        safeUrl != null ? firebaseInlineImageUrl(safeUrl) : null;
        final googleUrl = inlineUrl != null
            ? 'https://www.google.com/url?q=${Uri.encodeComponent(inlineUrl)}'
            : null;
        final imageWidget = pw.Image(
          pw.MemoryImage(Uint8List.fromList(bytes)),
          width: 50,
          height: 50,
          fit: pw.BoxFit.cover,
        );

        return pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            googleUrl != null
                ? pw.UrlLink(destination: googleUrl, child: imageWidget)
                : imageWidget,
            if (inlineUrl != null) ...[
              pw.SizedBox(height: 2),
             /* pw.UrlLink(
                destination: inlineUrl,
                child: pw.Text(
                  'عرض',
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontSize: 7,
                    color: PdfColors.blue,
                    decoration: pw.TextDecoration.underline,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
              ),*/

            ]
          ],
        );
      }

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            "📸 الصور:",
            style: pw.TextStyle(
              font: arabicFont,
              fontFallback: [emojiFont],
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 1),
          pw.Wrap(
            alignment: pw.WrapAlignment.end,
            spacing: 6,
            runSpacing: 6,
            children: [
              // 🔵 BEFORE
              ...beforeImages.asMap().entries.map((e) {
                final url = (beforeUrls != null && e.key < beforeUrls.length)
                    ? beforeUrls[e.key]
                    : null;
                return pw.Column(
                  children: [
                    buildImage(e.value, url),
                  ],
                );
              }),

              // 🟢 AFTER
              ...afterImages.asMap().entries.map((e) {
                final url = (afterUrls != null && e.key < afterUrls.length)
                    ? afterUrls[e.key]
                    : null;
                return pw.Column(
                  children: [
                    buildImage(e.value, url),
                  ],
                );
              }),
            ],
          ),
        ],
      );
    }
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4),
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.15),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // 🟡 En-tête mission
         /* pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfColor.fromHex('#B8860B'), PdfColor.fromHex('#B8860B')],
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              "المهمة $taskNumber",
              style: pw.TextStyle(
                font: arabicFont,
                fontFallback: [emojiFont],
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              textAlign: pw.TextAlign.center,
              textDirection: pw.TextDirection.rtl,
            ),
          ),*/
          pw.SizedBox(height: 3),

          // 📝 Notes (titre + contenu sur la même ligne)
            // 📝 Notes (titre + contenu sur la même ligne)
          if (task.notes != null && task.notes!.isNotEmpty) ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                // النص
                pw.Expanded(
                  child: pw.Text(
                    task.notes!,
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontFallback: [emojiFont],
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                    textDirection: pw.TextDirection.rtl,
                    softWrap: true,
                  ),
                ),
                // 📝 العنوان
                pw.Text(
                  "📝 الملاحظات: ",
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontFallback: [emojiFont],
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),


              ],
            ),
            pw.SizedBox(height:1),
          ],
          if (beforeImages.isNotEmpty || afterImages.isNotEmpty)
            _buildBeforeAfterImages(
              beforeImages: beforeImages,
              afterImages: afterImages,
              beforeUrls: task.imagesBefore,
              afterUrls: task.imagesAfter,
            ),

        ],
      ),
    );
  }

}
