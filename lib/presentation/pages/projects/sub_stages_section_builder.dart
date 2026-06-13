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

  // ✅ maintenant on stocke directement les bytes
  final Map<String, Uint8List> imageMemoryMap;

  final String projectId;
  final String stageId;

  SubStagesSectionBuilder({
    required this.subStages,
    required this.tasks,
    required this.arabicFont,
    required this.emojiFont,
    required this.imageMemoryMap,
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

      result.putIfAbsent(floor, () => []);
      result[floor]!.add(task);
    }

    return result;
  }

  String _floorLabel(String floorId) {
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

  String _buildTaskGalleryUrl(String taskId) {
    return "https://bhbgroup-ed1bc.web.app/task?taskId=$taskId&projectId=$projectId";
  }

  pw.Widget build() {
    if (subStages.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Wrap(
      runSpacing: 8,
      children: subStages.map((subStage) {
        final subTasks = tasks
            .where((t) => t.projectId == projectId)
            .where((t) => t.subStageId?.trim() == subStage.id?.trim())
            .toList();

        return _buildSubStageBox(subStage, subTasks);
      }).toList(),
    );
  }

  pw.Widget _buildSubStageBox(
      SubStage subStage,
      List<Tasks> subTasks,
      ) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(
          pw.Radius.circular(4),
        ),
        border: pw.Border.all(
          color: PdfColors.grey300,
          width: 0.6,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // HEADER
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

          pw.SizedBox(height: 4),

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
        ],
      ),
    );
  }

  pw.Widget _buildTasksGroupedByFloor(List<Tasks> subTasks) {
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

    final grouped = _groupTasksByFloor(subTasks);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: grouped.entries.map((entry) {
        final floorId = entry.key;
        final floorTasks = entry.value;

        return pw.Container(
          margin: const pw.EdgeInsets.only(top: 6),
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(
              color: PdfColors.grey400,
              width: 0.5,
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
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

              ...floorTasks.asMap().entries.map((e) {
                return _buildTaskBox(e.value, e.key + 1);
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildTaskBox(
      Tasks task,
      int taskNumber,
      ) {
    Uint8List? imageBytes;

    // ✅ prendre une seule image
    if (task.imagesAfter != null &&
        task.imagesAfter!.isNotEmpty) {
      imageBytes =
      imageMemoryMap[task.imagesAfter!.first];
    } else if (task.imagesBefore != null &&
        task.imagesBefore!.isNotEmpty) {
      imageBytes =
      imageMemoryMap[task.imagesBefore!.first];
    }

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
          // NOTES
          if (task.notes != null &&
              task.notes!.isNotEmpty) ...[
            pw.Row(
              crossAxisAlignment:
              pw.CrossAxisAlignment.start,
              mainAxisAlignment:
              pw.MainAxisAlignment.end,
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
                    textDirection:
                    pw.TextDirection.rtl,
                  ),
                ),

                pw.Text(
                  "📝 الملاحظات:",
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontFallback: [emojiFont],
                    fontSize: 9,
                    fontWeight:
                    pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                  textDirection:
                  pw.TextDirection.rtl,
                ),
              ],
            ),

            pw.SizedBox(height: 5),
          ],


          // IMAGE
          if (imageBytes != null && imageBytes.isNotEmpty) ...[
            pw.Text(
              "📸 صورة المهمة :",
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

            pw.UrlLink(
              destination: _buildTaskGalleryUrl(task.id ?? ""),
              child: pw.Container(
                constraints: const pw.BoxConstraints(
                  maxHeight: 120,
                ),
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(
                    color: PdfColors.grey400,
                    width: 0.5,
                  ),
                ),
                child: pw.ClipRRect(
                  horizontalRadius: 6,
                  verticalRadius: 6,
                  child: pw.FittedBox(
                    fit: pw.BoxFit.contain,
                    child: pw.Image(
                      pw.MemoryImage(imageBytes),
                    ),
                  ),
                ),
              ),
            ),

            pw.SizedBox(height: 6),
          ],
          // LINK
          pw.UrlLink(
            destination:
            _buildTaskGalleryUrl(
              task.id ?? "",
            ),
            child: pw.Container(
              padding:
              const pw.EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 8,
              ),
              decoration: pw.BoxDecoration(
                color:
                PdfColor.fromHex('#EAF4FF'),
                borderRadius:
                pw.BorderRadius.circular(6),
                border: pw.Border.all(
                  color:
                  PdfColor.fromHex('#0E4D92'),
                  width: 0.6,
                ),
              ),
              child: pw.Row(
                mainAxisAlignment:
                pw.MainAxisAlignment.center,
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
                      fontWeight:
                      pw.FontWeight.bold,
                    ),
                    textDirection:
                    pw.TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}