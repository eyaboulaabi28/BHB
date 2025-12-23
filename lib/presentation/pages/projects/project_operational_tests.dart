import 'package:app_bhb/data/auth/models/sub_tests_model.dart';
import 'package:app_bhb/data/auth/source/auth_firebase_service.dart';
import 'package:app_bhb/data/auth/source/projects_firebase_service.dart';
import 'package:app_bhb/presentation/pages/projects/add_task_test_dialog.dart';
import 'package:app_bhb/presentation/pages/projects/final_commissioning_tests.dart';
import 'package:app_bhb/presentation/pages/projects/global_project_pdf_generator.dart';
import 'package:app_bhb/presentation/pages/projects/global_section_pdf_generator.dart';
import 'package:app_bhb/presentation/pages/projects/operational_tests_pdf_generator.dart';
import 'package:app_bhb/presentation/pages/projects/tasks_test_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';
import '../../../service_locator.dart';

class ProjectOperationalsTest extends StatefulWidget {
  final String projectId;

  const ProjectOperationalsTest({super.key, required this.projectId});

  @override
  State<ProjectOperationalsTest> createState() => _ProjectOperationalsTestState();
}

class _ProjectOperationalsTestState extends State<ProjectOperationalsTest> {
  Map<String, dynamic> _testsStatus = {};

  List<Map<String, dynamic>> _sections = [];

  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _sections = finalCommissioningTests.map((section) {
      return {
        ...section,
        'completed': false,
        'tests': (section['tests'] as List).map((test) {
          return {
            ...test,
            'completed': false,
          };
        }).toList(),
      };
    }).toList();
    _loadTestsStatus();
  }

  Future<void> _loadTestsStatus() async {
    final doc = await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .get();

    if (doc.exists) {
      setState(() {
        _testsStatus = doc.data()?['testsStatus'] ?? {};
        _applyTestsStatusFromFirestore();
      });
    }
  }
  void _applyTestsStatusFromFirestore() {
    for (final section in _sections) {
      final sectionId = section['section_id'];
      final sectionData = _testsStatus[sectionId];

      if (sectionData != null) {
        section['status'] = sectionData['status'] ?? 'en cours';

        for (final test in section['tests']) {
          test['status'] =
              sectionData['tests']?[test['id']] ?? 'en cours';
        }
      }
    }
  }
  Future<void> _onTestStatusChanged(String sectionId,String testId,String newStatus,) async {
    // 1️⃣ Firebase
    await sl<ProjectsFirebaseService>().updateTestStatus(
      widget.projectId,
      sectionId,
      testId,
      newStatus,
    );

    // 2️⃣ UI locale
    setState(() {
      final section = _sections
          .firstWhere((s) => s['section_id'] == sectionId);
      for (final test in section['tests']) {
        if (test['id'] == testId) {
          test['status'] = newStatus;
        }
      }

      // 🔁 Auto calcul du statut parent
      final allDone =
      section['tests'].every((t) => t['status'] == 'terminé');

      section['status'] = allDone ? 'terminé' : 'en cours';
    });
  }
  Future<void> _loadUserRole() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final result = await sl<AuthFirebaseService>().getUserProfile(userId);

    result.fold(
          (err) => null,
          (data) {
        if (!mounted) return;
        setState(() {
          _userRole = (data['role'] as String?)?.toLowerCase();
        });
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:  [
              Text(
                "🧪 اختبارات التشغيل",
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              ElevatedButton.icon(
                onPressed: () {
                  GlobalSectionPdfGenerator(
                    projectId: widget.projectId,
                    section: finalCommissioningTests,
                  ).generate(context);
                },
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 22),
                label: const Text("تقرير شامل"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
              ),

            ],
          ),
          const SizedBox(height: 20),

          if (_sections.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.science_outlined,
                      color: Colors.grey.shade400, size: 70),
                  const SizedBox(height: 8),
                  const Text(
                    "لم تتم إضافة أي اختبارات بعد",
                    style: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

          ..._sections.asMap().entries.map((entry) {
            final index = entry.key;
            final section = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ExpansionTile(
                maintainState: true,
                title: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: TColor.primary.withOpacity(0.2),
                      child: Icon(Icons.science, color: TColor.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "القسم ${index + 1} : ${section['section_name']}",
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        Checkbox(
                          value: section['status'] == 'terminé',
                          onChanged: (value) async {
                            final newStatus = value! ? 'terminé' : 'en cours';

                            await sl<ProjectsFirebaseService>()
                                .updateTestSectionStatus(
                              widget.projectId,
                              section['section_id'],
                              newStatus,
                            );

                            setState(() {
                              section['status'] = newStatus;
                              for (final test in section['tests']) {
                                test['status'] = newStatus;
                              }
                            });
                          },
                        ),

                        /// 📄 PDF ICON (SECTION)
                        IconButton(
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                            size: 26,
                          ),
                          tooltip: "تقرير الاختبار",
                          onPressed: () async {
                            final generator = OperationalTestPdfGenerator(
                              projectId: widget.projectId,
                              section: section,
                            );

                            await generator.generate(context);
                          },
                        ),
                      ],
                    ),

                  ],
                ),

                /// 🔽 TESTS
                children: section['tests'].map<Widget>((test) {
                  final done = test['status'] == 'terminé';

                  return Container(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          const Icon(Icons.biotech,
                              color: Colors.orange),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              test['name'],
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          Checkbox(
                            value: done,
                            onChanged: (value) {
                              _onTestStatusChanged(
                                section['section_id'],
                                test['id'],
                                value! ? 'terminé' : 'en cours',
                              );
                            },
                          ),
                          const SizedBox(width: 5),
                          IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.green,
                        size: 26,
                      ),
                      tooltip: "إضافة اختبار",
                      onPressed: () {
                        final fakeSubTest = SubTest(
                          operationalsTestId: test['id'],
                          subTestName: test['name'],
                          status: 'en cours',
                        );

                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                          ),
                          builder: (_) => AddTaskTestDialog(
                            testId: test['id'],
                            testName: test['name'],
                            projectId: widget.projectId,
                            onTaskAdded: () {
                              setState(() {});
                            },
                          ),
                        );
                      },
                    ),
                        ],
                      ),
                      children: [
                        TasksTestsList(
                          key: ValueKey('${widget.projectId}_${test['id']}'),
                          subTestId: test['id'],
                          projectId: widget.projectId,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }



}
