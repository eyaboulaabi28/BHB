import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/data/auth/models/projects_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_projects.dart';
import 'package:app_bhb/presentation/pages/projects/sub_stages_section_builder.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:app_bhb/data/auth/models/sub_stages_model.dart';
import 'package:app_bhb/data/auth/models/tasks_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../service_locator.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_tasks.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:share_plus/share_plus.dart';


class TColor {
  static const int chatTextBG = 0xff115173;
}

class StagePdfGenerator {
  final String projectId;
  final Map<String, String> imageDownloadUrlMap = {};

  StagePdfGenerator({
    required this.projectId,

  });
  final Map<String, Uint8List> _imageMemoryCache = {};
  String formatPhoneForWhatsApp(String phone) {
    phone = phone.trim().replaceAll(" ", "");

    // إذا بدأ بـ 0 (رقم سعودي محلي)
    if (phone.startsWith("0")) {
      phone = phone.substring(1);
      phone = "966$phone";
    }

    // إزالة +
    phone = phone.replaceAll("+", "");

    return phone;
  }

  Future<void> generate(BuildContext context, Map<String, dynamic> stage) async {


    // 1️⃣ Charger les polices
    final arabicFont = pw.Font.ttf(await rootBundle.load("assets/font/NotoSansArabic-Regular.ttf"),);
    final emojiFont = pw.Font.ttf(await rootBundle.load("assets/font/NotoEmoji-Regular.ttf"),);

    // SnackBar "en cours de téléchargement"
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
    Project? projectDetails;

    // === Données ===
    final taskUseCase = sl<GetTaskUseCase>();
    final projectUseCase = sl<GetProjectUseCase>();
    final projectResult = await projectUseCase.call();
    final taskResult = await taskUseCase.call();
    Map<String, List<Uint8List>> imagesBeforeMap = {};
    Map<String, List<Uint8List>> imagesAfterMap = {};
    // 🔹 Ajoute ce bloc pour debug
    projectResult.fold(
          (_) {},
          (list) {
        final projects = list as List<Project>;
        debugPrint("🆔 projectId = $projectId");

        projectDetails = projects.firstWhere(
              (p) => p.id == projectId,
        );
        debugPrint("🆔 stage.projectId = $projectId");

        for (final p in projects) {
          debugPrint("📦 Project ID Firestore = ${p.id}");
        }
        projectDetails = projects.firstWhere(
              (p) => p.id == projectId,
          orElse: () => Project(),
        );
      },
    );

    final Map<String, dynamic> stagesStatus = projectDetails?.stagesStatus ?? {};
    final Map<String, dynamic> currentPhaseStatus = stagesStatus[stage['id']] ?? {};
    final Map<String, dynamic> subStagesStatus = currentPhaseStatus['subStages'] ?? {};
    debugPrint("🧱 stage['id'] = ${stage['id']}");
    debugPrint("🧱 stagesStatus KEYS = ${stagesStatus.keys.toList()}");
    debugPrint("🧱 currentPhaseStatus = $currentPhaseStatus");
    debugPrint("🧱 subStagesStatus = $subStagesStatus");
   // ✅ SubStages TERMINÉS uniquement (source Firestore correcte)
    final List<SubStage> subStages =
    (stage['subPhases'] as List)
        .where((sub) {
      final subId = sub['id'];
      final status = subStagesStatus[subId];
      return status == 'terminé';
    })
        .map((sub) => SubStage(
      id: sub['id'],
      stageId: stage['id'],
      subStageName: sub['name'],
      subStageStatus: 'terminé',
    )).toList();
    final validSubStageIds =
    subStages.map((e) => e.id).whereType<String>().toSet();
    debugPrint("📄 PDF → SubStages TERMINÉS : ${subStages.length}");

    List<Tasks> tasksList = [];
    taskResult.fold((_) {}, (list) {
      tasksList = list as List<Tasks>;
    });
    final filteredTasks = tasksList.where((t) {
      final sid = t.subStageId?.trim();
      return sid != null && validSubStageIds.contains(sid);
    }).toList();
    for (final subStage in subStages) {
      debugPrint("Checking SubStage ID: '${subStage.id}'");

      final subTasks = tasksList.where((t) {
        final tId = (t.subStageId ?? '').trim();
        final sId = (subStage.id ?? '').trim();

        debugPrint("Task subStageId: '$tId' vs SubStageId: '$sId'");
        return tId.isNotEmpty && sId.isNotEmpty && tId == sId;
      }).toList();

      debugPrint(
        "SubStage: ${subStage.subStageName}, Tasks: ${subTasks.length}",
      );
    }

    final subStagesSection = SubStagesSectionBuilder(
      subStages: subStages,
      tasks: filteredTasks,
      imagesBeforeMap: imagesBeforeMap,
      imagesAfterMap: imagesAfterMap,
      arabicFont: arabicFont,
      emojiFont: emojiFont,
      imageDownloadUrlMap: imageDownloadUrlMap,

    );

   // ========= Téléchargement + Resize (séquentiel protégé) =========
    Future<String?> _toHttpsDownloadUrl(String url) async {
      try {
        if (url.startsWith('https://')) {
          return url; // déjà OK
        }

        if (url.startsWith('gs://')) {
          final ref = FirebaseStorage.instance.refFromURL(url);
          return await ref.getDownloadURL();
        }
      } catch (e) {
        debugPrint("❌ URL convert error: $url → $e");
      }
      return null;
    }

    // ========= Collecte de toutes les URLs =========
    // ========= Collecte de toutes les URLs =========
    final List<String> allBeforeUrls = [];
    final List<String> allAfterUrls = [];

    for (final t in filteredTasks) {
      allBeforeUrls.addAll(t.imagesBefore ?? []);
      allAfterUrls.addAll(t.imagesAfter ?? []);
    }

    final allUrls = {...allBeforeUrls, ...allAfterUrls};

    for (final url in allUrls) {
      final httpsUrl = await _toHttpsDownloadUrl(url);
      if (httpsUrl != null) {
        imageDownloadUrlMap[url] = httpsUrl;
      }
    }

    debugPrint("🔗 imageDownloadUrlMap size = ${imageDownloadUrlMap.length}");


    debugPrint("Total BEFORE URLs = ${allBeforeUrls.length}");
    debugPrint("Total AFTER URLs  = ${allAfterUrls.length}");

// ========= Téléchargement global (beaucoup plus rapide) =========
    final allBeforeImages = await _downloadImagesBatch(allBeforeUrls, batchSize: 8);
    final allAfterImages  = await _downloadImagesBatch(allAfterUrls, batchSize: 8);

    debugPrint("Downloaded BEFORE = ${allBeforeImages.length}");
    debugPrint("Downloaded AFTER  = ${allAfterImages.length}");

// ========= Resize global ( isolates ) =========
    final resizedBefore = await Future.wait(
      allBeforeImages.map(resizeImageInIsolate),
    );

    final resizedAfter = await Future.wait(
      allAfterImages.map(resizeImageInIsolate),
    );

    debugPrint("Resized BEFORE = ${resizedBefore.length}");
    debugPrint("Resized AFTER  = ${resizedAfter.length}");

// ========= Redistribution vers chaque tâche =========
    int beforeIndex = 0;
    int afterIndex = 0;

    for (final t in filteredTasks) {
      final nBefore = t.imagesBefore?.length ?? 0;
      final nAfter  = t.imagesAfter?.length ?? 0;

      final taskBefore = resizedBefore.skip(beforeIndex).take(nBefore).toList();
      final taskAfter  = resizedAfter.skip(afterIndex).take(nAfter).toList();

      beforeIndex += nBefore;
      afterIndex  += nAfter;

      // Max 4 images
      imagesBeforeMap[t.id ?? ""] = taskBefore.take(1).toList();
      imagesAfterMap[t.id ?? ""]  = taskAfter.take(1).toList();

      debugPrint("✔️ Tâche ${t.id} => ${taskBefore.length} before / ${taskAfter.length} after");
    }
    for (final url in allBeforeUrls) {
      debugPrint("URL BEFORE = $url");
    }
    for (final url in allAfterUrls) {
      debugPrint("URL AFTER = $url");
    }

    // === PDF ===
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

        build: (context) => [
          pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  "تقرير مرحلة ${stage['name']}",
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
                    pw.SizedBox(width: 4),
                    buildInfoBox(projectDetails?.district ?? "-", "البلدية", "Sub Municipality", arabicFont, emojiFont, icon: "📍"),
                    pw.SizedBox(width: 4),
                    buildInfoBox(projectDetails?.municipality ?? "-", "المدينة", "Municipal", arabicFont, emojiFont, icon: "🧱"),
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
                    buildInfoBox( "جميع المراحل الفرعية الخاصة بالمشروع موجودة في الصفحات اللاحقة.⬇️⬇️⬇️", "المراحل الفرعية", "Sub-Stages", arabicFont, emojiFont, icon: "📋",),
                    pw.SizedBox(width: 8),
                  ],
                ),

              ],
            ),
            pw.SizedBox(height: 20),
          ],
          pw.SizedBox(height: 15),
          subStagesSection.build(),
        ],
      ),
    );
    final bytes = await pdf.save();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${stage['name']}.pdf',
      );

      CustomSnackBar.show(
        context,
        message: "✅ تم تحميل ملف PDF بنجاح!",
        type: SnackBarType.success,
        duration: const Duration(seconds: 3),
      );
    } else {
      final dir = await getTemporaryDirectory();
      final file = io.File('${dir.path}/${stage['name']}.pdf');
      await file.writeAsBytes(bytes);

// ****** ENVOI WHATSAPP AUTOMATIQUE ******

// Récupérer numéro du client
      final phone = projectDetails?.phoneNumber ?? "";
      final whatsappPhone = formatPhoneForWhatsApp(phone);

// 1) Attacher automatiquement le PDF dans WhatsApp
      await Share.shareXFiles(
        [XFile(file.path)],
        text: "👋 مرحبا، هذا تقرير المرحلة الخاصة بالمشروع.",
        subject: "تقرير مرحلة",
      );

// 2) Ouvrir la conversation WhatsApp automatiquement
      final whatsappUrl = "https://wa.me/$whatsappPhone";
      await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);

// SnackBar
      CustomSnackBar.show(
        context,
        message: "📤 تم إرسال التقرير على واتساب للعميل",
        type: SnackBarType.success,
      );
    }
  }

  Future<List<Uint8List>> _downloadImagesBatch(List<String> urls,
      {int batchSize = 3}) async {
    if (urls.isEmpty) return [];

    List<Uint8List> results = [];

    for (int i = 0; i < urls.length; i += batchSize) {
      final batch = urls.skip(i).take(batchSize);

      // téléchargement par batch
      final futures = batch.map((url) async {
        final cached = _imageMemoryCache[url];
        if (cached != null) return cached;

        try {
          final uri = Uri.parse(url);

          final response =
          await http.get(uri).timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            _imageMemoryCache[url] = response.bodyBytes;
            return response.bodyBytes;
          }
        } catch (e) {
          debugPrint("⚠️ Erreur batch image ($url): $e");
        }

        return Uint8List(0);
      });

      final batchResults = await Future.wait(futures);

      results.addAll(batchResults.where((e) => e.isNotEmpty));
    }

    return results;
  }



  Future<Uint8List> resizeImage(Uint8List data, {int maxWidth = 600}) async {
    try {
      final original = img.decodeImage(data);
      if (original == null) return data;

      if (original.width <= maxWidth) return data;

      final resized = img.copyResize(original, width: maxWidth);
      return Uint8List.fromList(img.encodeJpg(resized, quality: 60));
    } catch (e) {
      debugPrint('Erreur redimensionnement image: $e');
      return data;
    }
  }



  Future<Uint8List> resizeImageInIsolate(Uint8List data) async {
    try {
      return await compute(_resizeImageSync, data);
    } catch (e) {
      debugPrint('resizeImageInIsolate failed: $e');
      return data;
    }
  }

  Uint8List _resizeImageSync(Uint8List data) {
    try {
      final original = img.decodeImage(data);
      if (original == null) return data;

      if (original.width <= 600) return data;

      final resized = img.copyResize(original, width: 600);
      return Uint8List.fromList(img.encodeJpg(resized, quality: 60));
    } catch (_) {
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
