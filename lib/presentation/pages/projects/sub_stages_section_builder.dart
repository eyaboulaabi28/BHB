import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:app_bhb/data/auth/models/sub_stages_model.dart';
import 'package:app_bhb/data/auth/models/tasks_model.dart';


class SubStagesSectionBuilder {
  final List<SubStage> subStages;
  final List<Tasks> tasks;
  final pw.Font arabicFont;
  final pw.Font emojiFont;
  final Map<String, String> imageDownloadUrlMap;
  final String projectId;
  final String stageId;

  SubStagesSectionBuilder({
    required this.subStages,
    required this.tasks,
    required this.arabicFont,
    required this.emojiFont,
    required this.imageDownloadUrlMap,
    required this.projectId,
    required this.stageId,

  });

  static const List<String> phasesWithFloorLabels = [
    'phase_08',
    'phase_09',
    'phase_10',
  ];
  Map<String, List<Tasks>> _groupTasksByFloor(List<Tasks> tasks) {
    final Map<String, List<Tasks>> result = {};
    for (final task in tasks) {
      final floor = task.floorId ?? 'غير محدد';
      if (!result.containsKey(floor)) {
        result[floor] = [task];
      }
    }
    return result;
  }

  String _floorLabel(String floorId) {
    // ✅ Si la phase n’est pas dans celles avec étages, ne rien afficher
    if (!phasesWithFloorLabels.contains(stageId)) {
      return '';
    }

    switch (floorId) {
      case 'ground':
        return '🧱 الدور الأرضي';
      case 'floor_1':
        return '🧱 الدور الأول';
      case 'floor_2':
        return '🧱 الدور الثاني';
      case 'floor_3':
        return '🧱 الدور الثالث';
      case 'floor_4':
        return '🧱 الدور الرابع';
      case 'floor_5':
        return '🧱 الدور الخامس';
      case 'roof':
        return '🧱 السطح';
      default:
        return '🧱 طابق غير محدد';
    }
  }
  List<String> _collectRemainingImages(SubStage subStage) {
    final subTasks = tasks.where((t) =>
    t.projectId == projectId && t.subStageId?.trim() == subStage.id?.trim()
    );

    final urls = <String>[];

    for (final t in subTasks) {
      final before = t.imagesBefore ?? [];
      final after  = t.imagesAfter ?? [];

      // On prend toutes sauf la première (déjà affichée)
      if (before.length > 1) urls.addAll(before.skip(1).where((u) => u.isNotEmpty));
      if (after.length > 1) urls.addAll(after.skip(1).where((u) => u.isNotEmpty));
    }

    // ✅ Filtrer uniquement les URLs existantes dans ce projet
    return urls
        .map((u) => imageDownloadUrlMap[u])
        .where((url) => url != null)
        .cast<String>()
        .toList();
  }

  String _buildTaskGalleryUrl(String taskId) {
    return "https://bhbgroup-ed1bc.web.app/task?taskId=$taskId&projectId=$projectId";
  }

  pw.Widget build() {
    if (subStages.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: subStages.map((subStage) {
        final subTasks = tasks
            .where((t) => t.projectId == projectId)
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
              : _buildTasksGroupedByFloor(subTasks),

          // ================= 🔗 LINK =================

        ],
      ),
    );
  }
  pw.Widget _buildTasksGroupedByFloor(List<Tasks> subTasks) {
    // ✅ CAS 1 : phases SANS étages → UNE SEULE task
    if (!phasesWithFloorLabels.contains(stageId)) {
      int index = 0;

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: subTasks.map((task) {
          index++;
          return _buildTaskBox(task, index);
        }).toList(),
      );
    }
    // ✅ CAS 2 : phase_08 / phase_09 / phase_10 → TOUTES les tasks
    final grouped = _groupTasksByFloor(subTasks);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: grouped.entries.map((entry) {
        final floorId = entry.key;
        final tasks = entry.value;

        return pw.Container(
          margin: const pw.EdgeInsets.only(top: 6),
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 🧱 Titre étage (uniquement pour phases 08/09/10)
              pw.Text(
                _floorLabel(floorId),
                style: pw.TextStyle(
                  font: arabicFont,
                  fontFallback: [emojiFont],
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
                textDirection: pw.TextDirection.rtl,
              ),

              pw.SizedBox(height: 4),

              // 📋 Toutes les tasks
              ...tasks.asMap().entries.map(
                    (e) => _buildTaskBox(e.value, e.key + 1),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  pw.Widget _buildTaskBox(Tasks task, int taskNumber) {

    final allUrls = <String>[
      ...?task.imagesBefore,
      ...?task.imagesAfter,
    ]
        .map((u) => imageDownloadUrlMap[u])
        .whereType<String>()
        .toList();

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4),
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(
          pw.Radius.circular(2),
        ),
        border: pw.Border.all(
          color: PdfColors.grey300,
          width: 0.15,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [

          if (task.notes != null && task.notes!.isNotEmpty) ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [

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
                  ),
                ),

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
            pw.SizedBox(height: 3),
          ],

          // ================= ALL IMAGES =================
          if (allUrls.isNotEmpty) ...[

            // ===== TITLE =====
            pw.Text(
              "📸 جميع صور المهمة :",
              style: pw.TextStyle(
                font: arabicFont,
                fontFallback: [emojiFont],
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
              textDirection: pw.TextDirection.rtl,
            ),

            pw.SizedBox(height: 4),

            // ===== BOX LINK =====
            pw.UrlLink(
              destination: _buildTaskGalleryUrl(task.id ?? ""),
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 8,
                ),

                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#EAF4FF'),

                  borderRadius: pw.BorderRadius.circular(6),

                  border: pw.Border.all(
                    color: PdfColor.fromHex('#0E4D92'),
                    width: 0.6,
                  ),
                ),

                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [

                    pw.Text(
                      "🔗",
                      style: pw.TextStyle(
                        fontFallback: [emojiFont],
                        fontSize: 10,
                      ),
                    ),

                    pw.SizedBox(width: 4),

                    pw.Text(
                      "عرض المزيد من الصور",
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontFallback: [emojiFont],
                        fontSize: 8,
                        color: PdfColors.blue900,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ),
          ],        ],
      ),
    );
  }
}
