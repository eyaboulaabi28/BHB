import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/common_widget/custom_search_bar.dart';
import 'package:app_bhb/data/auth/models/meeting_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_meeting.dart';
import 'package:app_bhb/presentation/pages/meeting/add_meeting_modal.dart';
import 'package:app_bhb/presentation/pages/meeting/meeting_pdf_generator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common_widget/generic_form_modal.dart' as generic_modal;
import 'package:printing/printing.dart';
import '../../../service_locator.dart';
import 'dart:io' as io;                 // io.File
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:path_provider/path_provider.dart'; // getTemporaryDirectory
import 'package:share_plus/share_plus.dart'; // Share + XFile
import 'package:url_launcher/url_launcher.dart'; // launchUrl



class MeetingPage extends StatefulWidget {
  final String selectedType;

  const MeetingPage({super.key, required this.selectedType});

  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  int _selectedIndex = 0;
  late final GetMeetingUseCase _getAllMeetingUseCase;
  String _selectedType = "";
  List<Meeting> meetings = [];
  List<Meeting> filteredMeetings = [];
  late String currentUserId;
  String userRole = "";
  final TextEditingController _searchController = TextEditingController();
  List<String>? images;

  @override
  void initState() {
    super.initState();

    _getAllMeetingUseCase = sl<GetMeetingUseCase>();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        currentUserId = user.uid;
        print("🔥 Auth loaded UID = $currentUserId");
        _loadUserRole();
      } else {
        print("❌ User not logged in");
      }
    });
  }

  Future<void> _generateMeetingPdf(Meeting meeting) async {
    try {
      CustomSnackBar.show(
        context,
        message: " جاري توليد ملف PDF...",
        type: SnackBarType.loading,
        duration: const Duration(seconds: 300),
      );

      final pdf = await MeetingPdfGenerator.generate(meeting: meeting);
      final bytes = await pdf.save();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // 🌐 WEB
      if (kIsWeb) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'meeting_${meeting.titleMeeting}.pdf',
        );

        CustomSnackBar.show(
          context,
          message: "✅ تم تحميل ملف PDF بنجاح",
          type: SnackBarType.success,
        );
      }
      // 📱 MOBILE
      else {
        final dir = await getTemporaryDirectory();
        final file = io.File(
          '${dir.path}/meeting_${meeting.titleMeeting}.pdf',
        );
        await file.writeAsBytes(bytes);

        // 🔹 رقم العميل
        final phone = meeting.customerPhone?? "";
        final sanitizedPhone = phone.replaceAll("+", "").trim();

        // 1️⃣ مشاركة الملف (attach PDF)
        await Share.shareXFiles(
          [XFile(file.path)],
          text: "📄 محضر الاجتماع",
          subject: "محضر اجتماع",
        );

        // 2️⃣ فتح محادثة واتساب مباشرة
        if (sanitizedPhone.isNotEmpty) {
          final whatsappUrl = "https://wa.me/$sanitizedPhone";
          await launchUrl(
            Uri.parse(whatsappUrl),
            mode: LaunchMode.externalApplication,
          );
        }

        CustomSnackBar.show(
          context,
          message: "📤 تم إرسال محضر الاجتماع عبر واتساب",
          type: SnackBarType.success,
        );
      }
    } catch (e, stack) {
      debugPrint("❌ PDF ERROR: $e");
      debugPrint(stack.toString());

      CustomSnackBar.show(
        context,
        message: " خطأ أثناء توليد PDF",
        type: SnackBarType.error,
      );
    }
  }
  Future<void> _fetchMeetings() async {
    final result = await _getAllMeetingUseCase.call();

    result.fold(
          (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $failure")),
        );
      },
          (meetingList) {
        setState(() {
          meetings = List<Meeting>.from(meetingList);

          // 👉 SI ADMIN → tout afficher
          if (userRole == "admin") {
            filteredMeetings = meetings;
          } else {
            filteredMeetings = meetings.where((m) {
              return m.uidCustomer == currentUserId ||
                  m.uidEngineer == currentUserId ||
                  m.uidEmployee == currentUserId;
            }).toList();
          }
        });
      },
    );
  }
  void _filterMeeting(String query) {
    setState(() {
      List<Meeting> baseList;

      // 👉 admin voit tout
      if (userRole == "admin") {
        baseList = meetings;
      } else {
        baseList = meetings.where((m) {
          return m.uidCustomer == currentUserId ||
              m.uidEngineer == currentUserId ||
              m.uidEmployee == currentUserId;
        }).toList();
      }

      if (query.isEmpty) {
        filteredMeetings = baseList;
        return;
      }

      filteredMeetings = baseList.where((e) {
        final q = query.toLowerCase();
        return (e.description ?? "").toLowerCase().contains(q) ||
            (e.titleMeeting ?? "").toLowerCase().contains(q) ||
            (e.type ?? "").toLowerCase().contains(q);
      }).toList();
    });
  }
  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  void _applyTypeFilter(String type) {
    setState(() {
      _selectedType = type;

      // admin voit tout
      final sourceList = userRole == "admin"
          ? meetings
          : meetings.where((m) {
        return m.uidCustomer == currentUserId ||
            m.uidEngineer == currentUserId ||
            m.uidEmployee == currentUserId;
      }).toList();

      filteredMeetings = sourceList.where((m) => m.type == type).toList();
    });
  }
  Future<void> _loadUserRole() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserId)
        .get();
    if (snapshot.exists) {
      final data = snapshot.data(); // <-- récupère le MAP
      print("User data: $data");

      setState(() {
        userRole = data?["role"] ?? "";  // <-- CORRECT
      });
    }

    print("👤 USER UID = $currentUserId");
    print("📌 LOADED ROLE = $userRole");

    // Charger les meetings
    _fetchMeetings();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF2F4F3),
        appBar: AppBar(
          backgroundColor: TColor.primary,
          elevation: 0,
          title: const SizedBox(),
        ),

        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 25, top: 20),
              decoration: BoxDecoration(
                color: TColor.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: const Center(
                child: Text(
                  "محاضر الإجتماعات",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            CustomSearchBar(
              controller: _searchController,
              hintText: 'ابحث عن إجتماع...',
              onChanged: _filterMeeting,
              onFilterTap: () {
                CustomSnackBar.show(
                  context,
                  message: "ميزة الفلترة قيد التطوير ",
                  type: SnackBarType.info,
                );
              },
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  FilterChip(
                    label: Row(
                      children: const [
                        Icon(Icons.list_alt, size: 18),
                        SizedBox(width: 6),
                        Text("الكل"),
                      ],
                    ),
                    selected: _selectedType == "",
                    onSelected: (_) {
                      setState(() {
                        _selectedType = "";

                        if (userRole == "admin") {
                          // 👉 Admin voit tout
                          filteredMeetings = meetings;
                        } else {
                          // 👉 Les autres voient seulement leurs réunions
                          filteredMeetings = meetings.where((m) {
                            return m.uidCustomer == currentUserId ||
                                m.uidEngineer == currentUserId ||
                                m.uidEmployee == currentUserId;
                          }).toList();
                        }
                      });
                    },

                  ),
                  FilterChip(
                    label: Row(
                      children: const [
                        Icon(Icons.handshake, size: 18),
                        SizedBox(width: 6),
                        Text("مع العميل"),
                      ],
                    ),
                    selected: _selectedType == "مع العميل",
                    onSelected: (_) {
                      _applyTypeFilter("مع العميل");
                    },
                  ),

                  FilterChip(
                    label: Row(
                      children: const [
                        Icon(Icons.groups, size: 18),
                        SizedBox(width: 6),
                        Text("مع الموظفين"),
                      ],
                    ),
                    selected: _selectedType == "مع الموظفين",
                    onSelected: (_) {
                      _applyTypeFilter("مع الموظفين");
                    },
                  ),
                ],
              ),
            ),



            const SizedBox(height: 10),

            Expanded(
              child: filteredMeetings.isEmpty
                  ? const Center(
                child: Text(
                  "لا يوجد إجتماعات مطابقون للبحث",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredMeetings.length,
                itemBuilder: (context, index) {
                  final meeting = filteredMeetings[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          // Icon type meeting
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: meeting.type == "مع العميل"
                                ? Colors.green.withOpacity(0.2)
                                : Colors.blue.withOpacity(0.2),
                            child: Icon(
                              meeting.type == "مع العميل" ? Icons.person : Icons.groups,
                              color: TColor.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meeting.titleMeeting ?? "",
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                    children: [
                                      const Icon(Icons.description, size: 18, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        meeting.description ?? "",
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 15,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ]
                                ),
                                const SizedBox(height: 10),
                                // Chaque champ avec icône
                                Row(
                                  children: [
                                    const Icon(Icons.category, size: 18, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      "نوع الاجتماع: ${meeting.type ?? "-"}",
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(Icons.engineering, size: 18, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      "مهندس: ${meeting.nameEngineer ?? "-"}",
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(Icons.account_circle, size: 18, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      "موظف: ${meeting.nameEmployee ?? "-"}",
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 18, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      "عميل: ${meeting.nameCustomer ?? "-"}",
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      "📅 ${meeting.dateMeeting?.toLocal().toString().split(' ')[0] ?? ''}",
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Voir détails
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 👁️ عرض التفاصيل
                              IconButton(
                                tooltip: "عرض التفاصيل",
                                icon: const Icon(Icons.visibility, color: Colors.blue),
                                onPressed: () => _openMeetingDetails(meeting),
                              ),

                              // 📄 توليد PDF
                              IconButton(
                                tooltip: "توليد PDF",
                                icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                onPressed: () => _generateMeetingPdf(meeting),
                              ),
                            ],
                          ),

                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),

        /******************/
        floatingActionButton: FloatingActionButton(
          backgroundColor: TColor.primary,
          shape: const CircleBorder(),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddMeetingModal(
                title: "إضافة محضر جديد",
                submitButtonText: "إضافة",
                onAdd: (values) {
                  setState(() {
                    meetings.add(
                      Meeting(
                        titleMeeting: values["titleMeeting"] ,
                        description: values["description"] ,
                        type: values["type"] ?? "",
                        nameEngineer: values["nameEngineer"] ,
                        uidEngineer: values["uidEngineer"] ,
                        nameEmployee: values["nameEmployee"],
                        uidEmployee: values["uidEmployee"] ,
                        nameCustomer: values["nameCustomer"] ,
                        uidCustomer: values["uidCustomer"] ,
                        imageUrl:values["imageUrl"],
                        signatureUrl: values["signatureUrl"],
                        customerPhone: values['customerPhone'],

                      ),
                    );

                  });
                },
              ),
            );
          },
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),


        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        bottomNavigationBar: CustomBottomNav(
          selectedIndex: _selectedIndex,
          onTap: _onBottomNavTapped,
          selectedType: widget.selectedType,

        ),
      ),
    );
  }
  void _openMeetingDetails(Meeting meeting) {
    // Champs du formulaire
    final List<generic_modal.FormFieldConfig> fields = [
      generic_modal.FormFieldConfig(
        key: "titleMeeting",
        hint: "عنوان الاجتماع",
        icon: const Icon(Icons.title, color: Colors.grey),
      ),
      generic_modal.FormFieldConfig(
        key: "description",
        hint: "تفاصيل الاجتماع",
        icon: const Icon(Icons.description, color: Colors.grey),
      ),
      generic_modal.FormFieldConfig(
        key: "type",
        hint: "نوع الاجتماع",
        icon: const Icon(Icons.category, color: Colors.grey),
        options: ["مع العميل", "مع الموظفين"],
      ),
      generic_modal.FormFieldConfig(
        key: "nameEngineer",
        hint: "المهندس",
        icon: const Icon(Icons.engineering, color: Colors.grey),
      ),
      generic_modal.FormFieldConfig(
        key: "nameEmployee",
        hint: "الموظف",
        icon: const Icon(Icons.account_circle, color: Colors.grey),
      ),
      generic_modal.FormFieldConfig(
        key: "nameCustomer",
        hint: "العميل",
        icon: const Icon(Icons.person, color: Colors.grey),
      ),
    ];

    // Valeurs initiales
    final Map<String, String> initialValues = {
      "titleMeeting": meeting.titleMeeting ?? "",
      "description": meeting.description ?? "",
      "type": meeting.type ?? "",
      "nameEngineer": meeting.nameEngineer ?? "",
      "nameEmployee": meeting.nameEmployee ?? "",
      "nameCustomer": meeting.nameCustomer ?? "",
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  children: [
                    generic_modal.GenericFormModal(
                      fields: fields,
                      initialValues: initialValues,
                      title: "تفاصيل الاجتماع",
                      submitButtonText: "إغلاق",
                      includeImagePicker: false,
                      includeFilePicker: false,
                      readOnly: true,
                      onSubmit: (values) => Navigator.pop(context),

                      // 👇👇👇 IMAGE AVANT LES BOUTONS
                      topWidget: (meeting.imageUrl != null && meeting.imageUrl!.isNotEmpty) ||
                          (meeting.signatureUrl != null && meeting.signatureUrl!.isNotEmpty)
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          // 📷 صورة الاجتماع
                          if (meeting.imageUrl != null && meeting.imageUrl!.isNotEmpty) ...[
                            const Text(
                              "📷 الصورة المرفقة للاجتماع",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: "Tajawal",
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                meeting.imageUrl!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 25),
                          ],

                          // ✍️ توقيع العميل
                          if (meeting.signatureUrl != null &&
                              meeting.signatureUrl!.isNotEmpty &&
                              meeting.type == "مع العميل") ...[
                            const Text(
                              "✍️ توقيع العميل",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: "Tajawal",
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  meeting.signatureUrl!,
                                  height: 150,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),
                          ],
                        ],
                      )
                          : null,
                      // 👆👆👆 FIN IMAGE
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

}
