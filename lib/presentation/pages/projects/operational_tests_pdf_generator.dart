import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/data/auth/models/projects_model.dart';
import 'package:app_bhb/data/auth/models/tasks_tests_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_projects.dart';
import 'package:app_bhb/presentation/pages/engineers_evaluation/common_pdf_header_footer.dart';
import 'package:app_bhb/presentation/pages/projects/tests_section_builder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../service_locator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

class OperationalTestPdfGenerator {
  final String projectId;
  final Map<String, dynamic> section;

  OperationalTestPdfGenerator({
    required this.projectId,
    required this.section,
  });

  Future<void> generate(BuildContext context) async {
    Project? projectDetails;
    final GetProjectUseCase _projectUseCase = sl<GetProjectUseCase>();
    final Map<String, List<Uint8List>> imagesMap = {};
    final Map<String, String> imageDownloadUrlMap = {};

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
    final arabicFont = pw.Font.ttf(
      await rootBundle.load("assets/font/NotoSansArabic-Regular.ttf"),
    );
    final emojiFont = pw.Font.ttf(
      await rootBundle.load("assets/font/NotoEmoji-Regular.ttf"),
    );
    // === Logo ===
    final logo = await imageFromAssetBundle('assets/img/app_logo.png');
    final fbEmoji = await imageFromAssetBundle("assets/img/fb.png");
    final googleEmoji = await imageFromAssetBundle('assets/img/google.png');
    final inEmoji = await imageFromAssetBundle('assets/img/in.png');

    CustomSnackBar.show(
      context,
      message: "جاري إنشاء تقرير القسم...",
      type: SnackBarType.loading,
      duration: const Duration(seconds: 60),
    );

    /// 1️⃣ Charger project pour lire testsStatus
    final projectDoc = await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .get();

    final Map<String, dynamic> testsStatus =
        projectDoc.data()?['testsStatus'] ?? {};

    final sectionStatus = testsStatus[section['section_id']] ?? {};
    final Map<String, dynamic> testsMap =
        sectionStatus['tests'] ?? {};

    /// 2️⃣ Tests TERMINÉS uniquement (🔥 IMPORTANT)
    final List<Map<String, dynamic>> completedTests =
    (section['tests'] as List)
        .where((test) {
      final map = Map<String, dynamic>.from(test as Map);
      final status = testsMap[map['id']];
      return status == 'terminé';
    })
        .map<Map<String, dynamic>>(
          (test) => Map<String, dynamic>.from(test as Map),
    )
        .toList();



    if (completedTests.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      CustomSnackBar.show(
        context,
        message: "⚠️ لا يوجد اختبارات مكتملة في هذا القسم",
        type: SnackBarType.warning,
      );
      return;
    }

    /// 3️⃣ IDs des tests validés
    final List<String> subTestIds =
    completedTests.map((t) => t['id'] as String).toList();

    /// 4️⃣ Charger TasksTests associées
    final snapshot = await FirebaseFirestore.instance
        .collection('tasksTest')
        .where('projectId', isEqualTo: projectId)
        .where('subTestId', whereIn: subTestIds)
        .get();
    debugPrint("🧪 completedTests IDs = $subTestIds");
    debugPrint("📋 tasks count = ${snapshot.docs.length}");

    for (final d in snapshot.docs) {
      debugPrint("📝 task => ${d.data()}");
    }
    final List<TasksTests> tasks = snapshot.docs
        .map((d) => TasksTests.fromMap(d.id, d.data()))
        .toList();

    for (final task in tasks) {
      final taskId = task.subTestId;
      if (taskId == null) continue;

      final images = task.images ?? [];

      for (final imgUrl in images) {
        try {
          // حفظ الرابط
          imageDownloadUrlMap[imgUrl] = imgUrl;

          // تحميل bytes
          final uri = Uri.parse(imgUrl);
          final response = await http.get(uri);

          if (response.statusCode == 200) {
            imagesMap.putIfAbsent(taskId, () => []);
            imagesMap[taskId]!.add(response.bodyBytes);
          }
        } catch (e) {
          debugPrint("❌ Error loading image: $e");
        }
      }
    }


    final testsSection = TestsSectionBuilder(
      tests: completedTests,
      tasks: tasks,
      imagesMap: imagesMap,
      imageDownloadUrlMap: imageDownloadUrlMap,
      arabicFont: arabicFont,
      emojiFont: emojiFont,
      projectId: projectId,
    );
    /// 5️⃣ PDF
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 18),

        // ✅ HEADER
        header: (context) {
          return CommonPdfHeaderFooter.buildHeader(
            arabicFont: arabicFont,
            emojiFont: emojiFont,
            logo: logo,
          );
        },

        // ✅ FOOTER
        footer: (context) {
          return CommonPdfHeaderFooter.buildFooter(
            arabicFont: arabicFont,
            emojiFont: emojiFont,
            fb: fbEmoji,
            google: googleEmoji,
            linkedIn: inEmoji,
          );
        },

        build: (_) => [pw.Center(
      child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            "تقرير الاختبار",
            style: pw.TextStyle(
              font: arabicFont,
              fontFallback: [emojiFont],
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#022C43'),
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            section['section_name'],
            style: pw.TextStyle(
              font: arabicFont,
              fontFallback: [emojiFont],
              fontSize: 14,
              fontWeight: pw.FontWeight.normal,
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
    ),

    pw.SizedBox(height: 18),
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
                    buildInfoBox( "جميع اختبارات الخاصة بالمشروع موجودة في الصفحات اللاحقة.⬇️⬇️⬇️", "اختبارات المشروع", "Project Tests ", arabicFont, emojiFont, icon: "📋",),
                    pw.SizedBox(width: 8),
                  ],
                ),

              ],
            ),
            pw.SizedBox(height: 40),
            testsSection.build(),
            pw.SizedBox(height: 20), // un petit espace avant le paragraphe
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FDE2E2'), // fond rouge clair pour avertissement
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColor.fromHex('#D32F2F'), width: 1), // bordure rouge foncé
              ),
              child: pw.Text(
                "  يُعتبر هذا التقرير نهائيًا ومعتمدًا تلقائيًا بعد مرور 48 ساعة من تاريخ إرساله، ما لم يُقدَّم اعتراض خطي ومعتمد خلال هذه الفترة. ",
                style: pw.TextStyle(
                  font: arabicFont,
                  fontFallback: [emojiFont],
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#B71C1C'), // texte rouge foncé
                ),
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.rtl,
              ),
            ),

          ],
        ],
      ),
    );


    final bytes = await pdf.save();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'تقرير_الاختبار_للمشروع.pdf',
      );

      CustomSnackBar.show(
        context,
        message: "✅ تم تحميل ملف PDF بنجاح!",
        type: SnackBarType.success,
      );
    } else {
      final dir = await getTemporaryDirectory();
      final file = io.File('${dir.path}/تقرير_الاختبار_للمشروع.pdf');
      await file.writeAsBytes(bytes);

      final phone = projectDetails!.phoneNumber ?? "";
      final sanitizedPhone = phone.replaceAll("+", "").trim();

      await Share.shareXFiles(
        [XFile(file.path)],
        text: "👋 مرحبا، هذا تقرير  الاختبار المشروع.",
        subject: "تقريرالاختبار المشروع",
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


