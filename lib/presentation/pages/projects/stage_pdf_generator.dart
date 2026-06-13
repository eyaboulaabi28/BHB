// stage_pdf_generator.dart

import 'dart:typed_data';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import 'package:firebase_storage/firebase_storage.dart';

import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/data/auth/models/projects_model.dart';
import 'package:app_bhb/data/auth/models/sub_stages_model.dart';
import 'package:app_bhb/data/auth/models/tasks_model.dart';

import 'package:app_bhb/domain/auth/usecases/uses_cases_projects.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_tasks.dart';

import '../../../service_locator.dart';


import 'dart:io' as io;
import 'package:app_bhb/common_widget/pd_tfheme_manager.dart';
import 'package:app_bhb/data/auth/models/tasks_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_tasks.dart';
import 'package:intl/intl.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/data/auth/models/projects_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_projects.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../service_locator.dart';



class StagePdfGenerator {
  final String projectId;

  StagePdfGenerator({
    required this.projectId,
  });

  /// cache image mémoire
  final Map<String, Uint8List> imageCache = {};

  Future<void> generate(
      BuildContext context,
      Map<String, dynamic> stage,
      ) async {
    try {
      CustomSnackBar.show(
        context,
        message: "جاري إنشاء ملف PDF...",
        type: SnackBarType.loading,
        duration: const Duration(seconds: 300),
      );

      // =====================================================
      // FONT
      // =====================================================

      final arabicFont = pw.Font.ttf(
        await rootBundle.load(
          "assets/font/NotoSansArabic-Regular.ttf",
        ),
      );

      final emojiFont = pw.Font.ttf(
        await rootBundle.load(
          "assets/font/NotoEmoji-Regular.ttf",
        ),
      );

      // =====================================================
      // PDF
      // =====================================================

      final pdf = pw.Document();

      // =====================================================
      // IMAGES
      // =====================================================

      final logo = await imageFromAssetBundle(
        'assets/img/app_logo.png',
      );

      final fbEmoji = await imageFromAssetBundle(
        "assets/img/fb.png",
      );

      final googleEmoji = await imageFromAssetBundle(
        'assets/img/google.png',
      );

      final inEmoji = await imageFromAssetBundle(
        'assets/img/in.png',
      );

      // =====================================================
      // DATA
      // =====================================================

      final projectUseCase = sl<GetProjectUseCase>();
      final taskUseCase = sl<GetTaskUseCase>();

      final projectResult = await projectUseCase.call();
      final taskResult = await taskUseCase.call();

      Project? project;

      List<Tasks> allTasks = [];

      projectResult.fold(
            (_) {},
            (list) {
          final projects = list as List<Project>;

          project = projects.firstWhere(
                (e) => e.id == projectId,
            orElse: () => Project(),
          );
        },
      );

      taskResult.fold(
            (_) {},
            (list) {
          allTasks = list as List<Tasks>;
        },
      );

      if (project == null) {
        throw Exception("Projet introuvable");
      }

      // =====================================================
      // SUB STAGES
      // =====================================================

      final Map<String, dynamic> stagesStatus =
          project?.stagesStatus ?? {};

      final Map<String, dynamic> currentStageStatus =
          stagesStatus[stage['id']] ?? {};

      final Map<String, dynamic> subStagesStatus =
          currentStageStatus['subStages'] ?? {};

      final List<SubStage> subStages =
      (stage['subPhases'] as List)
          .where((sub) {
        final subId = sub['id'];

        return subStagesStatus[subId] ==
            'terminé';
      })
          .map(
            (sub) => SubStage(
          id: sub['id'],
          stageId: stage['id'],
          subStageName: sub['name'],
          subStageStatus: 'terminé',
        ),
      )
          .toList();

      // =====================================================
      // TASKS
      // =====================================================

      final validSubIds = subStages
          .map((e) => e.id ?? "")
          .toSet();

      final List<Tasks> tasks = allTasks.where((t) {
        return t.projectId == projectId &&
            validSubIds.contains(
              t.subStageId ?? "",
            );
      }).toList();

      // =====================================================
      // DOWNLOAD ONLY 1 IMAGE / TASK
      // =====================================================

      for (final task in tasks) {
        String? imageUrl;

        if (task.imagesAfter != null &&
            task.imagesAfter!.isNotEmpty) {
          imageUrl = task.imagesAfter!.first;
        } else if (task.imagesBefore != null &&
            task.imagesBefore!.isNotEmpty) {
          imageUrl = task.imagesBefore!.first;
        }

        if (imageUrl == null) continue;

        if (imageCache.containsKey(imageUrl)) {
          continue;
        }

        try {
          final httpsUrl =
          await _toHttpsUrl(imageUrl);

          if (httpsUrl == null) continue;

          const imageTimeout = Duration(minutes: 2);

          final response = await http
              .get(Uri.parse(httpsUrl))
              .timeout(imageTimeout);

          if (response.statusCode == 200) {
            final resized = await resizeImage(
              response.bodyBytes,
              maxWidth: 450,
            );
            imageCache[imageUrl] = resized;
          }
        } catch (e) {
          debugPrint("IMAGE ERROR: $e");
        }
      }
      // =====================================================
      // PAGE
      // =====================================================
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,

          /// IMPORTANT
          maxPages: 200,

          margin: const pw.EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 18,
          ),

          // =================================================
          // HEADER
          // =================================================

          header: (context) {
            return pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment:
                  pw.MainAxisAlignment
                      .spaceBetween,
                  children: [
                    pw.Text(
                      "🕓 ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontFallback: [
                          emojiFont,
                        ],
                        fontSize: 10,
                        color:
                        PdfColors.grey700,
                      ),
                      textDirection:
                      pw.TextDirection.rtl,
                    ),

                    pw.Image(
                      logo,
                      width: 75,
                    ),
                  ],
                ),

                pw.SizedBox(height: 8),

                if (context.pageNumber == 1)
                  pw.Center(

                    child: pw.Text(
                      "تقرير مرحلة ${stage['name']}",
                      textDirection:
                      pw.TextDirection.rtl,
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontFallback: [
                          emojiFont,
                        ],
                        fontSize: 18,
                        fontWeight:
                        pw.FontWeight.bold,
                        color: PdfColor.fromHex(
                          '#022C43',
                        ),
                      ),
                    ),
                  ),
                pw.SizedBox(height: 5),
                if (context.pageNumber == 1)
                  pw.SizedBox(height: 10),
                pw.Container(
                  height: 3,
                  width: 140,
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [
                        PdfColor.fromHex(
                          '#FFD700',
                        ),
                        PdfColor.fromHex(
                          '#022C43',
                        ),
                      ],
                    ),
                    borderRadius:
                    pw.BorderRadius.circular(
                      2,
                    ),
                  ),
                ),

                pw.SizedBox(height: 10),
              ],
            );
          },

          // =================================================
          // FOOTER
          // =================================================

          footer: (context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(
                top: 12,
              ),
              child: pw.Column(
                children: [
                  pw.Divider(
                    color: PdfColors.grey400,
                  ),

                  pw.SizedBox(height: 5),

                  pw.Row(
                    mainAxisAlignment:
                    pw.MainAxisAlignment
                        .spaceBetween,
                    children: [
                      // PHONE
                      pw.Text(
                        "☎ +966545388835",
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontFallback: [
                            emojiFont,
                          ],
                          fontSize: 10,
                          color: PdfColors
                              .grey700,
                        ),
                        textDirection:
                        pw.TextDirection.rtl,
                      ),

                      // SOCIAL
                      pw.Row(
                        children: [
                          pw.Image(
                            fbEmoji,
                            width: 12,
                            height: 12,
                          ),

                          pw.SizedBox(width: 4),

                          pw.Image(
                            googleEmoji,
                            width: 12,
                            height: 12,
                          ),

                          pw.SizedBox(width: 4),

                          pw.Image(
                            inEmoji,
                            width: 12,
                            height: 12,
                          ),

                          pw.SizedBox(width: 8),

                          pw.Text(
                            "BHB_Group",
                            style: pw.TextStyle(
                              font:
                              arabicFont,
                              fontFallback: [
                                emojiFont,
                              ],
                              fontSize: 8,
                              color: PdfColors
                                  .grey700,
                            ),
                          ),

                          pw.SizedBox(width: 10),

                          pw.Text(
                            "🌐 https://x.com/BHB_Group",
                            style: pw.TextStyle(
                              font:
                              arabicFont,
                              fontFallback: [
                                emojiFont,
                              ],
                              fontSize: 8,
                              color: PdfColors
                                  .blue700,
                              decoration:
                              pw.TextDecoration
                                  .underline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },

          // =================================================
          // BUILD
          // =================================================

          build: (context) {
            return [
              // =====================================================
              // PROJECT INFOS
              // =====================================================

              if (project != null) ...[
                pw.SizedBox(height: 8),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Ligne 1 (bleu foncé)
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [

                        buildInfoBox(project?.ownerName ?? "-", "اسم المالك", "Owner's Name", arabicFont, emojiFont, icon: "👤",),
                        pw.SizedBox(width: 4),
                        buildInfoBox(project?.projectName ?? "-", "اسم المشروع", "Project Name", arabicFont, emojiFont, icon: "📝",),

                      ],
                    ),
                    pw.SizedBox(height: 10),
                    // Ligne 2
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.SizedBox(width: 4),
                        buildInfoBox(project?.planNumber ?? "-", "رقم المخطط", "Plan Number", arabicFont, emojiFont, icon: "📌",isAlternate: true),
                        pw.SizedBox(width: 4),
                        buildInfoBox(project?.plotNumber ?? "-", "رقم قطعة الارض", "Land Number", arabicFont, emojiFont, icon: "📄",isAlternate: true),
                        pw.SizedBox(width: 4),
                        buildInfoBox(project?.licenseNumber ?? "-", "رقم رخصة البناء", "Building Permit Number", arabicFont, emojiFont, icon: "⚠",isAlternate: true),
                        pw.SizedBox(width: 4),
                        buildInfoBox(project?.buildingDescription ?? "-", "وصف البناء", "Building Description", arabicFont, emojiFont, icon: "🏠", isAlternate: true),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    // Ligne 3 (bleu foncé)
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.SizedBox(width: 4),
                        buildInfoBox(project?.reportDate?? "-", "تاريخ التقرير", "Report date", arabicFont, emojiFont, icon: "📅"),
                        pw.SizedBox(width: 4),
                        buildInfoBox(project?.floorsCount ?? "-", "عدد الادوار", "Number Of Floors", arabicFont, emojiFont, icon: "🧮"),
                        pw.SizedBox(width: 4),
                        buildInfoBox(project?.buildingType ?? "-", "نوع المبنى", "Building Type", arabicFont, emojiFont, icon: "🏭"),
                        pw.SizedBox(width: 4),
                        buildInfoBox(project?.supervisorOffice ?? "-", "المكتب الهندسي المشرف", "Supervising engineering office", arabicFont, emojiFont, icon: "🏣"),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    // Ligne
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.SizedBox(width: 4),
                        buildInfoBox(project?.phaseResult ?? "-", "نتيجة فحص المرحلة", "Check Result", arabicFont, emojiFont, icon: "✅", isAlternate: true),
                        pw.SizedBox(width: 4),
                        buildInfoBox(project?.engineerName ?? "-", "اسم المهندس المشرف", "Name Of Supervising Engineer", arabicFont, emojiFont, icon: "👷 ", isAlternate: true),
                        pw.SizedBox(width: 4),
                        buildInfoBox(project?.contractor?? "-", "مقاول البناء", "Construction Contractor", arabicFont, emojiFont, icon: "👨", isAlternate: true),
                        pw.SizedBox(width: 4),
                        buildInfoBox(project?.designerOffice ?? "-", "مكتب المصمم المعتمد", "Certified Designer's Office", arabicFont, emojiFont, icon: "🏢", isAlternate: true),

                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        buildInfoBox(
                          "جميع المراحل  الخاصة بالمشروع موجودة في الصفحات اللاحقة.⬇️⬇️⬇️",
                          "مراحل  المشروع",
                          "Project  Phases",
                          arabicFont,
                          emojiFont,
                          icon: "📋",
                        ),
                      ],
                    ),

                  ],
                ),
                pw.SizedBox(height: 20),
                pw.SizedBox(height: 20),
                pw.SizedBox(height: 20),

              ],
              pw.SizedBox(height: 20),
              pw.SizedBox(height: 20),
              pw.SizedBox(height: 20),

              // =====================================================
              // SUB STAGES
              // =====================================================

              ...subStages.map(
                    (subStage) {
                  final subTasks = tasks.where((t) {
                    return t.subStageId ==
                        subStage.id;
                  }).toList();

                  return buildSubStageSection(
                    subStage: subStage,
                    tasks: subTasks,
                    arabicFont: arabicFont,
                    emojiFont: emojiFont,
                  );
                },
              ),

              pw.SizedBox(height: 15),
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
                child: pw.Row(
                  crossAxisAlignment:
                  pw.CrossAxisAlignment.center,
                  mainAxisAlignment:
                  pw.MainAxisAlignment.center,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        "يُعتبر هذا التقرير نهائيًا ومعتمدًا تلقائيًا بعد مرور 48 ساعة من تاريخ إرساله، ما لم يُقدَّم اعتراض خطي ومعتمد خلال هذه الفترة.",
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontFallback: [emojiFont],
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#B71C1C'),
                        ),
                        textAlign: pw.TextAlign.center,
                        textDirection:
                        pw.TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),
            ];
          },        ),
      );

      // =====================================================
      // SAVE
      // =====================================================

      final bytes = await pdf.save();

// 🔹 nom du stage (sécurisé pour fichier)
      final stageName = (stage['name'] ?? 'stage')
          .toString()
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

      final fileName = 'تقرير_$stageName.pdf';

// 🔹 Web
      if (kIsWeb) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: fileName,
        );

        CustomSnackBar.show(
          context,
          message: "✅ تم تحميل ملف PDF بنجاح!",
          type: SnackBarType.success,
        );
      } else {
        final dir = await getTemporaryDirectory();

        final file = io.File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        final phone = project!.phoneNumber ?? "";
        final sanitizedPhone = phone.replaceAll("+", "").trim();

        await Share.shareXFiles(
          [XFile(file.path)],
          text: "👋 مرحبا، هذا تقرير المشروع: $stageName",
          subject: "تقرير المرحلة: $stageName",
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
          message: "📤 تم إرسال تقرير المرحلة ($stageName) بنجاح",
          type: SnackBarType.success,
        );
      }

    } catch (e) {
      debugPrint("PDF ERROR = $e");

      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      CustomSnackBar.show(
        context,
        message: "Erreur PDF",
        type: SnackBarType.error,
      );
    }
  }

  // =====================================================
  // PROJECT INFO ITEM
  // =====================================================

  pw.Widget buildInfoItem({
    required String title,
    required String value,
    required pw.Font arabicFont,
    required pw.Font emojiFont,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius:
          pw.BorderRadius.circular(4),
          border: pw.Border.all(
            color: PdfColors.grey300,
          ),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              title,
              textDirection:
              pw.TextDirection.rtl,
              style: pw.TextStyle(
                font: arabicFont,
                fontFallback: [emojiFont],
                fontSize: 9,
                fontWeight:
                pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),

            pw.SizedBox(height: 4),

            pw.Text(
              value,
              textDirection:
              pw.TextDirection.rtl,
              textAlign:
              pw.TextAlign.center,
              style: pw.TextStyle(
                font: arabicFont,
                fontFallback: [emojiFont],
                fontSize: 9,
                color: PdfColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // SUB STAGE SECTION
  // =====================================================

  pw.Widget buildSubStageSection({
    required SubStage subStage,
    required List<Tasks> tasks,
    required pw.Font arabicFont,
    required pw.Font emojiFont,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(
        bottom: 15,
      ),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey300,
        ),
        borderRadius:
        pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          // HEADER
          pw.Container(
            width: double.infinity,
            padding:
            const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color:
              PdfColor.fromHex('#0E4D92'),
              borderRadius:
              const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(
                  6,
                ),
                topRight:
                pw.Radius.circular(6),
              ),
            ),
            child: pw.Text(
              subStage.subStageName ?? "",
              textAlign:
              pw.TextAlign.center,
              textDirection:
              pw.TextDirection.rtl,
              style: pw.TextStyle(
                font: arabicFont,
                fontFallback: [emojiFont],
                fontSize: 13,
                color: PdfColors.white,
                fontWeight:
                pw.FontWeight.bold,
              ),
            ),
          ),

          // TASKS
          if (tasks.isEmpty)
            pw.Padding(
              padding:
              const pw.EdgeInsets.all(
                10,
              ),
              child: pw.Text(
                "لا توجد مهام",
                style: pw.TextStyle(
                  font: arabicFont,
                  fontFallback: [
                    emojiFont,
                  ],
                ),
              ),
            ),

          ...tasks.asMap().entries.map(
                (entry) {
              return buildTaskItem(
                task: entry.value,
                index: entry.key + 1,
                arabicFont:
                arabicFont,
                emojiFont:
                emojiFont,
              );
            },
          ),
        ],
      ),
    );
  }

  // =====================================================
  // TASK ITEM
  // =====================================================

  pw.Widget buildTaskItem({
    required Tasks task,
    required int index,
    required pw.Font arabicFont,
    required pw.Font emojiFont,
  }) {
    Uint8List? imageBytes;

    if (task.imagesAfter != null && task.imagesAfter!.isNotEmpty) {
      imageBytes = imageCache[task.imagesAfter!.first];
    } else if (task.imagesBefore != null && task.imagesBefore!.isNotEmpty) {
      imageBytes = imageCache[task.imagesBefore!.first];
    }

    final String taskUrl =
        "https://bhbgroup-ed1bc.web.app/task?taskId=${task.id}&projectId=$projectId";

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.all(8),

      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),

      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // TITLE
          pw.Text(
            "المهمة رقم $index",
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              font: arabicFont,
              fontFallback: [emojiFont],
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),

          pw.SizedBox(height: 5),

          // NOTES
          if ((task.notes ?? "").isNotEmpty)
            pw.Text(
              task.notes!,
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(
                font: arabicFont,
                fontFallback: [emojiFont],
                fontSize: 9,
              ),
            ),

          if (imageBytes != null) ...[
            pw.SizedBox(height: 8),

            pw.Center(
              child: pw.Image(
                pw.MemoryImage(imageBytes),
                height: 140,
                fit: pw.BoxFit.contain,
              ),
            ),

            pw.SizedBox(height: 8),

            pw.UrlLink(
              destination: taskUrl,
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
                    pw.Text("🔗"),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      "عرض المزيد من الصور",
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontFallback: [emojiFont],
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  // =====================================================
  // FIREBASE URL
  // =====================================================

  Future<String?> _toHttpsUrl(
      String url,
      ) async {
    try {
      if (url.startsWith("https://")) {
        return url;
      }

      if (url.startsWith("gs://")) {
        final ref = FirebaseStorage
            .instance
            .refFromURL(url);

        return await ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint("URL ERROR: $e");
    }

    return null;
  }

  // =====================================================
  // RESIZE
  // =====================================================

  Future<Uint8List> resizeImage(
      Uint8List data, {
        int maxWidth = 500,
      }) async {
    try {
      final original =
      img.decodeImage(data);

      if (original == null) {
        return data;
      }

      if (original.width <= maxWidth) {
        return data;
      }

      final resized = img.copyResize(
        original,
        width: maxWidth,
      );

      return Uint8List.fromList(
        img.encodeJpg(
          resized,
          quality: 65,
        ),
      );
    } catch (e) {
      return data;
    }
  }
  pw.Expanded buildInfoBox(String value, String titleAr, String titleEn, pw.Font arabicFont, pw.Font emojiFont, {String? icon, bool isAlternate = false,}) {
    final PdfColor primaryColor = isAlternate ? PdfColor.fromHex('#B8860B') : PdfColor.fromHex('#21206C');
    final PdfColor secondaryColor = PdfColor.fromHex('#E9EEF3');
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

}