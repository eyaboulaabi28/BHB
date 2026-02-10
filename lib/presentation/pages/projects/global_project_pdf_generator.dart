import 'dart:io' as io;
import 'package:app_bhb/data/auth/models/sub_stages_model.dart';
import 'package:app_bhb/data/auth/models/tasks_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_tasks.dart';
import 'package:app_bhb/presentation/pages/projects/stage_section_builder.dart';
import 'package:app_bhb/presentation/pages/projects/sub_stages_section_builder.dart';
import 'package:app_bhb/presentation/pages/projects/sub_stages_section_builder1.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

class GlobalStagesPdfGenerator {
  final String projectId;
  final List<Map<String, dynamic>> stages;

  // ✅ أضف هذا
  final Map<String, String> imageDownloadUrlMap = {};

  List<SubStage> allSubStages = [];
  List<Tasks> allTasks = [];

  Map<String, List<Uint8List>> imagesBeforeMap = {};
  Map<String, List<Uint8List>> imagesAfterMap = {};
  GlobalStagesPdfGenerator({
    required this.projectId,
    required this.stages,
  });

  Project? projectDetails;

  final GetProjectUseCase _projectUseCase = sl<GetProjectUseCase>();

  Future<void> generate(BuildContext context) async {
    Project? projectDetails;
    final arabicFont = pw.Font.ttf(await rootBundle.load("assets/font/NotoSansArabic-Regular.ttf"),);
    final emojiFont = pw.Font.ttf(await rootBundle.load("assets/font/NotoEmoji-Regular.ttf"),);
    final taskUseCase = sl<GetTaskUseCase>();
    final taskResult = await taskUseCase.call();
    List<Tasks> tasksList = [];
    taskResult.fold((_) {}, (list) {
      tasksList = list as List<Tasks>;
    });
    taskResult.fold(
          (_) {},
          (list) {
        allTasks = list as List<Tasks>;
      },
    );
    final validSubStageIds =
    allSubStages.map((e) => e.id).whereType<String>().toSet();

    final filteredTasks = allTasks.where((t) {
      final sid = t.subStageId?.trim();
      return sid != null && validSubStageIds.contains(sid);
    }).toList();

    final List<String> allBeforeUrls = [];
    final List<String> allAfterUrls = [];

    for (final t in filteredTasks) {
      allBeforeUrls.addAll(t.imagesBefore ?? []);
      allAfterUrls.addAll(t.imagesAfter ?? []);
    }
    // تحويل gs:// إلى https
    Future<String?> _toHttpsDownloadUrl(String url) async {
      try {
        if (url.startsWith('https://')) return url;
        if (url.startsWith('gs://')) {
          final ref = FirebaseStorage.instance.refFromURL(url);
          return await ref.getDownloadURL();
        }
      } catch (_) {}
      return null;
    }

    final allUrls = {...allBeforeUrls, ...allAfterUrls};
    for (final url in allUrls) {
      final httpsUrl = await _toHttpsDownloadUrl(url);
      if (httpsUrl != null) {
        imageDownloadUrlMap[url] = httpsUrl;
      }
    }
    CustomSnackBar.show(
        context,
        message: " جاري إنشاء ملف PDF...",
        type: SnackBarType.loading, duration: const Duration(seconds: 300)
    );
    final pdf = pw.Document();
    // === Logo ===
    final logo = await imageFromAssetBundle('assets/img/app_logo.png');
    final fbEmoji = await imageFromAssetBundle("assets/img/fb.png");
    final googleEmoji = await imageFromAssetBundle('assets/img/google.png');
    final inEmoji = await imageFromAssetBundle('assets/img/in.png');


    // 🔹 1️⃣ جلب تفاصيل المشروع
    final projectResult = await _projectUseCase.call();
    projectResult.fold(
          (failure) {
        CustomSnackBar.show(
          context,
          message: "❌ فشل في تحميل بيانات المشروع",
          type: SnackBarType.error,
        );
        return;
      },
          (projects) {
        final List<Project> list = projects as List<Project>;

        debugPrint("🆔 projectId = $projectId");
        for (final p in list) {
          debugPrint("📦 Project ID Firestore = ${p.id}");
        }

        projectDetails = list.firstWhere(
              (p) => p.id == projectId,
          orElse: () => Project(),
        );
      },
    );

    if (projectDetails == null || projectDetails!.id == null) {
      CustomSnackBar.show(
        context,
        message: "⚠ لم يتم العثور على المشروع",
        type: SnackBarType.warning,
      );
      return;
    }


    if (projectDetails == null) return;
    final Map<String, dynamic> stagesStatus =
        projectDetails?.stagesStatus ?? {};

    allSubStages.clear();


    // 🔹 2️⃣ تصفية المراحل المنتهية
    final List<Map<String, dynamic>> finishedStages =
    stages.where((s) => s['status'] == 'terminé').toList();
    for (final stage in finishedStages) {
      final stageId = stage['id'];
      final stageStatus = stagesStatus[stageId] ?? {};
      final subStagesStatus = stageStatus['subStages'] ?? {};

      final List<SubStage> stageSubStages =
      (stage['subPhases'] as List)
          .where((sub) {
        final subId = sub['id'];
        return subStagesStatus[subId] == 'terminé';
      })
          .map((sub) => SubStage(
        id: sub['id'],
        stageId: stageId,
        subStageName: sub['name'],
        subStageStatus: 'terminé',
      ))
          .toList();

      allSubStages.addAll(stageSubStages);
    }


    if (finishedStages.isEmpty) {
      CustomSnackBar.show(
        context,
        message: " لا توجد مراحل منتهية",
        type: SnackBarType.warning,
      );
      return;
    }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          header: (context) => pw.Column(
            children: [
              pw.Container(
                height: 5,
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [
                      PdfColor.fromHex('#FFD700'),
                      PdfColor.fromHex('#022C43'),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height:5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    ' ${DateFormat('dd/MM/yyyy').format(DateTime.now())}    🕓  ',
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontFallback: [emojiFont],
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.Image(logo, width: 80),
                ],
              ),
            ],
          ),
          footer: (context) => pw.Container(
            margin: const pw.EdgeInsets.only(top: 13),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height:5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "+966545388835    ☎",
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontFallback: [emojiFont],
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Image(fbEmoji, width: 14, height: 14),
                        pw.SizedBox(width: 4),
                        pw.Image(googleEmoji, width: 14, height: 14),
                        pw.SizedBox(width: 4),
                        pw.Image(inEmoji, width: 14, height: 14),
                        pw.SizedBox(width: 12),
                        pw.Text(
                          "BHB_Group",
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontFallback: [emojiFont],
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Text(
                          "🌐 https://x.com/BHB_Group",
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontFallback: [emojiFont],
                            fontSize: 10,
                            color: PdfColors.blue700,
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                        pw.SizedBox(width: 4),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          build: (_) => [
            pw.Center(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    "تقرير العام لمراحل المشروع",
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
            if (projectDetails != null) ...[
              pw.SizedBox(height: 8),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Ligne 1 (bleu foncé)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [

                      buildInfoBox(projectDetails?.ownerName ?? "-", "اسم المالك", "Owner's Name", arabicFont, emojiFont, icon: "👤",),
                      pw.SizedBox(width: 4),
                      buildInfoBox(projectDetails?.projectName ?? "-", "اسم المشروع", "Project Name", arabicFont, emojiFont, icon: "📝",),
                     // pw.SizedBox(width: 4),
                     // buildInfoBox(projectDetails?.district ?? "-", "البلدية", "Sub Municipality", arabicFont, emojiFont, icon: "📍"),
                      //pw.SizedBox(width: 4),
                     // buildInfoBox(projectDetails?.municipality ?? "-", "المدينة", "Municipal", arabicFont, emojiFont, icon: "🧱"),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  // Ligne 2
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.SizedBox(width: 4),
                      buildInfoBox(projectDetails?.planNumber ?? "-", "رقم المخطط", "Plan Number", arabicFont, emojiFont, icon: "📌",isAlternate: true),
                      pw.SizedBox(width: 4),
                      buildInfoBox(projectDetails?.plotNumber ?? "-", "رقم قطعة الارض", "Land Number", arabicFont, emojiFont, icon: "📄",isAlternate: true),
                      pw.SizedBox(width: 4),
                      buildInfoBox(projectDetails?.licenseNumber ?? "-", "رقم رخصة البناء", "Building Permit Number", arabicFont, emojiFont, icon: "⚠",isAlternate: true),
                      pw.SizedBox(width: 4),
                      buildInfoBox(projectDetails?.buildingDescription ?? "-", "وصف البناء", "Building Description", arabicFont, emojiFont, icon: "🏠", isAlternate: true),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  // Ligne 3 (bleu foncé)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.SizedBox(width: 4),
                      buildInfoBox(projectDetails?.reportDate?? "-", "تاريخ التقرير", "Report date", arabicFont, emojiFont, icon: "📅"),
                      pw.SizedBox(width: 4),
                      buildInfoBox(projectDetails?.floorsCount ?? "-", "عدد الادوار", "Number Of Floors", arabicFont, emojiFont, icon: "🧮"),
                      pw.SizedBox(width: 4),
                      buildInfoBox(projectDetails?.buildingType ?? "-", "نوع المبنى", "Building Type", arabicFont, emojiFont, icon: "🏭"),
                      pw.SizedBox(width: 4),
                      buildInfoBox(projectDetails?.supervisorOffice ?? "-", "المكتب الهندسي المشرف", "Supervising engineering office", arabicFont, emojiFont, icon: "🏣"),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  // Ligne
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.SizedBox(width: 4),
                      buildInfoBox(projectDetails?.phaseResult ?? "-", "نتيجة فحص المرحلة", "Check Result", arabicFont, emojiFont, icon: "✅", isAlternate: true),
                      pw.SizedBox(width: 4),
                      buildInfoBox(projectDetails?.engineerName ?? "-", "اسم المهندس المشرف", "Name Of Supervising Engineer", arabicFont, emojiFont, icon: "👷 ", isAlternate: true),
                      pw.SizedBox(width: 4),
                      buildInfoBox(projectDetails?.contractor?? "-", "مقاول البناء", "Construction Contractor", arabicFont, emojiFont, icon: "👨", isAlternate: true),
                      pw.SizedBox(width: 4),
                      buildInfoBox(projectDetails?.designerOffice ?? "-", "مكتب المصمم المعتمد", "Certified Designer's Office", arabicFont, emojiFont, icon: "🏢", isAlternate: true),

                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      buildInfoBox( "جميع المراحل لاختبارات الخاصة بالمشروع موجودة في الصفحات اللاحقة.⬇️⬇️⬇️", "مراحل لاختبارات المشروع", "Project Testing Phases", arabicFont, emojiFont, icon: "📋",),
                      pw.SizedBox(width: 8),
                    ],
                  ),

                ],
              ),
              pw.SizedBox(height: 20),
            ],
            pw.SizedBox(height: 15),
          ],

        ),
      );
    for (final stage in finishedStages) {
      final stageId = stage['id'];

      final stageSubStages =
      allSubStages.where((s) => s.stageId == stageId).toList();

      if (stageSubStages.isEmpty) continue;

      final stageSubStageIds =
      stageSubStages.map((s) => s.id).whereType<String>().toSet();

      final stageTasks = allTasks.where((t) {
        final sid = t.subStageId?.trim();
        return sid != null && stageSubStageIds.contains(sid);
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          header: (context) => pw.Column(
            children: [
              pw.Container(
                height: 5,
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [
                      PdfColor.fromHex('#FFD700'),
                      PdfColor.fromHex('#022C43'),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height:5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    ' ${DateFormat('dd/MM/yyyy').format(DateTime.now())}    🕓  ',
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontFallback: [emojiFont],
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.Image(logo, width: 80),
                ],
              ),
            ],
          ),
          footer: (context) => pw.Container(
            margin: const pw.EdgeInsets.only(top: 13),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height:5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "+966545388835    ☎",
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontFallback: [emojiFont],
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Image(fbEmoji, width: 14, height: 14),
                        pw.SizedBox(width: 4),
                        pw.Image(googleEmoji, width: 14, height: 14),
                        pw.SizedBox(width: 4),
                        pw.Image(inEmoji, width: 14, height: 14),
                        pw.SizedBox(width: 12),
                        pw.Text(
                          "BHB_Group",
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontFallback: [emojiFont],
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Text(
                          "🌐 https://x.com/BHB_Group",
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontFallback: [emojiFont],
                            fontSize: 10,
                            color: PdfColors.blue700,
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                        pw.SizedBox(width: 4),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          build: (_) => [
            StageSectionBuilder(
              stage: stage,
              arabicFont: arabicFont,
              emojiFont: emojiFont,
              buildSubStages: () {
                return SubStagesSectionBuilder1(
                  subStages: stageSubStages,
                  tasks: stageTasks,
                  arabicFont: arabicFont,
                  emojiFont: emojiFont,
                  imageDownloadUrlMap: imageDownloadUrlMap,
                  projectId: projectId,
                  stageId: stageId,
                ).build();
              },
            ).build(),
          ],
        ),
      );
    }



    final bytes = await pdf.save();

    // 🔹 4️⃣ مشاركة PDF
    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'التقرير_العام_للمشروع.pdf',
      );

      CustomSnackBar.show(
        context,
        message: "✅ تم تحميل ملف PDF بنجاح!",
        type: SnackBarType.success,
      );
    } else {
      final dir = await getTemporaryDirectory();
      final file = io.File('${dir.path}/التقرير_العام_للمشروع.pdf');
      await file.writeAsBytes(bytes);

      final phone = projectDetails!.phoneNumber ?? "";
      final sanitizedPhone = phone.replaceAll("+", "").trim();

      await Share.shareXFiles(
        [XFile(file.path)],
        text: "👋 مرحبا، هذا تقرير مراحل المشروع.",
        subject: "تقرير المشروع",
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


