import 'package:app_bhb/data/auth/models/tasks_model.dart';
import 'package:pdf/pdf.dart';

import 'package:pdf/widgets.dart' as pw;
class TableStageSectionBuilder {
  final Map<String, dynamic> stage;
  final List<Map<String, dynamic>> subStages;
  final List<Tasks> tasks;
  final pw.Font arabicFont;
  final pw.Font emojiFont;
  final Map<String, String> imageDownloadUrlMap;

  TableStageSectionBuilder({
    required this.stage,
    required this.subStages,
    required this.tasks,
    required this.arabicFont,
    required this.emojiFont,
    required this.imageDownloadUrlMap,
  });

  /// كل SubStage يرسم جدول منفصل
  List<pw.Widget> buildWidgets() {
    final widgets = <pw.Widget>[];

    for (final sub in subStages) {
      final subTasks = tasks.where((t) =>
      t.subStageId?.trim() == sub['id']?.trim()
      ).toList();

      widgets.add(
        pw.Text(sub['name'] ?? "-",
            style: pw.TextStyle(
              font: arabicFont,
              fontFallback: [emojiFont],
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
            textDirection: pw.TextDirection.rtl),
      );
      widgets.add(pw.SizedBox(height: 5));

      widgets.add(
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(70),
            1: const pw.FlexColumnWidth(),
            2: const pw.FixedColumnWidth(120),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _cell("المرحلة"),
                _cell("المهام / الملاحظات"),
                _cell("روابط الصور"),
              ],
            ),
            ...subTasks.map((task) => pw.TableRow(
              children: [
                _cell(stage['name'] ?? "-"),
                _cell(task.notes ?? "-"),
                _cell(_buildLinksText(task)),
              ],
            )),
            if (subTasks.isEmpty)
              pw.TableRow(
                children: [
                  _cell(stage['name'] ?? "-"),
                  _cell("لا توجد مهام"),
                  _cell("-"),
                ],
              ),
          ],
        ),
      );

      widgets.add(pw.SizedBox(height: 10));
    }

    return widgets;
  }

  pw.Widget _cell(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: arabicFont,
        fontFallback: [emojiFont],
        fontSize: 9,
      ),
      textDirection: pw.TextDirection.rtl,
      textAlign: pw.TextAlign.center,
    ),
  );

  String _buildLinksText(Tasks task) {
    final urls = [
      ...(task.imagesBefore ?? []),
      ...(task.imagesAfter ?? []),
    ]
        .map((u) => imageDownloadUrlMap[u])
        .whereType<String>()
        .toList();

    if (urls.isEmpty) return "-";
    return urls.join("\n");
  }
}