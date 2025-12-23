import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/daily_tasks_model.dart';
import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:app_bhb/data/auth/source/notification_service.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_check_in.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_daily_tasks.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_engineers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/presentation/pages/engineers_evaluation/engineer_evaluation_pdf.dart';
import 'package:flutter/material.dart';
import '../../../service_locator.dart';
class EngineerEvaluationPage extends StatefulWidget {
  final String selectedType;

  const EngineerEvaluationPage({super.key, required this.selectedType});

  @override
  State<EngineerEvaluationPage> createState() => _EngineerEvaluationPageState();
}

class _EngineerEvaluationPageState extends State<EngineerEvaluationPage> {
  int _selectedIndex = 0;
  List<Engineer> engineers = [];
  List<DailyTasks> dailyTasks = [];
  String? selectedEngineer;

  late final NotificationService _notificationService;
  final TextEditingController engineerCtrl = TextEditingController();
  final TextEditingController tasksCountCtrl = TextEditingController();
  final TextEditingController completedTasksCtrl = TextEditingController();
  final TextEditingController extraHoursCtrl = TextEditingController();
  final TextEditingController estimatedDaysCtrl = TextEditingController();
  final TextEditingController dateCtrl = TextEditingController();
  final TextEditingController totalHoursCtrl = TextEditingController();
  final TextEditingController overtimeHoursCtrl = TextEditingController();
  final TextEditingController totalDaysCtrl = TextEditingController();
  final TextEditingController totalDurationCtrl = TextEditingController();

  final List<String> arabicMonths = ["يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو", "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر",];

  @override
  void initState() {
    super.initState();
    _loadEngineers();
    _loadDailyTasks();
    _notificationService = NotificationService(sl<CreateNotificationUseCase>());
  }

  Future<void> _loadEngineers() async {
    final result = await sl<GetEngineersUseCase>().call();
    result.fold( (error) => debugPrint("Error loading engineers"),
          (list) => setState(() => engineers = List<Engineer>.from(list)), ); }
  Future<void> _loadDailyTasks() async {
    final result =  await sl<GetAllDailyTasksUseCase>().call();
    result.fold( (error) => debugPrint("Error loading DailyTasks"),
          (list) => setState(() => dailyTasks = List<DailyTasks>.from(list)), ); }

  int _getMonthNumber(String arabicMonth) {
    final index = arabicMonths.indexOf(arabicMonth);
    return index >= 0 ? index + 1 : 1;

  }

  Future<void> _loadStatsForEngineerAndMonth({required String engineerId, required int year, required int month,}) async {
    // 1️⃣ Nombre total de tâches
    final totalTasksResult = await sl<CountTasksByEngineerPerMonthUseCase>()
        .call(engineerId: engineerId, year: year, month: month);
    totalTasksResult.fold(
          (error) => tasksCountCtrl.text = "0",
          (count) => tasksCountCtrl.text = count.toString(),
    );

    // 2️⃣ Nombre de tâches complétées
    final completedTasksResult =
    await sl<CountCompletedTasksByEngineerPerMonthUseCase>()
        .call(engineerId: engineerId, year: year, month: month);
    completedTasksResult.fold(
          (error) => completedTasksCtrl.text = "0",
          (count) => completedTasksCtrl.text = count.toString(),
    );

    // 3️⃣ Total des heures
    final totalHoursResult = await sl<GetTotalHoursByEngineerAndMonthUseCase>()
        .call(params: {'engineerId': engineerId, 'year': year, 'month': month});
    totalHoursResult.fold(
          (error) => totalHoursCtrl.text = "0",
          (hours) => totalHoursCtrl.text = hours.toStringAsFixed(2),
    );

    // 4️⃣ Heures supplémentaires
    final overtimeResult = await sl<GetOvertimeHoursByEngineerAndMonthUseCase>()
        .call(params: {'engineerId': engineerId, 'year': year, 'month': month});
    overtimeResult.fold(
          (error) => overtimeHoursCtrl.text = "0",
          (hours) => overtimeHoursCtrl.text = hours.toStringAsFixed(2),
    );

    // 5️⃣ Nombre total de jours
    final totalDaysResult = await sl<GetTotalDaysByEngineerAndMonthUseCase>()
        .call(params: {'engineerId': engineerId, 'year': year, 'month': month});
    totalDaysResult.fold(
          (error) => totalDaysCtrl.text = "0",
          (days) => totalDaysCtrl.text = days.toString(),
    );
  // 5️⃣ Nombre total de jours estime par tous les taches
    final totalDaysEstimatedResult = await sl<GetTotalDurationByEngineerAndMonthUseCase>()
        .call(params: {'engineerId': engineerId, 'year': year, 'month': month});
    totalDaysEstimatedResult.fold(
          (error) => totalDurationCtrl.text = "0",
          (days) => totalDurationCtrl.text = days.toString(),
    );

    setState(() {});
  }


  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _generatePDF() async {
    if (selectedEngineer == null || dateCtrl.text.isEmpty) {
      CustomSnackBar.show(context,
          message: "يرجى اختيار المهندس والشهر أولاً",
          type: SnackBarType.error);
      return;
    }

    await EngineerEvaluationPDF.generate(
      engineerName: engineerCtrl.text,
      month: dateCtrl.text,
      tasksCount: tasksCountCtrl.text,
      completedTasks: completedTasksCtrl.text,
      totalHours: totalHoursCtrl.text,
      overtimeHours: overtimeHoursCtrl.text,
      totalDays: totalDaysCtrl.text,
      estimatedDuration: totalDurationCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget buildLabel(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF2F4F3),

        appBar: AppBar(
          backgroundColor: TColor.primary,
          elevation: 0,
          title: const SizedBox(),
        ),

        body: SingleChildScrollView(
          child: Column(
            children: [

              // 🟦 HEADER
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
                    "لوحة تقييم المهندسين",
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ⭐ CARD 1 : FILTRES
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "معلومات التصفية",
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // 🔵 Label + Champ ingénieur
                        buildLabel("المهندس"),
                        NewRoundSelectField(
                          hintText: "اختيار المهندس",
                          options: engineers.map((e) => e.firstName ?? "").toList(),
                          controller: engineerCtrl,
                          rightIcon: const Icon(Icons.engineering),
                          onChanged: (value) async {
                            final eng = engineers.firstWhere((e) => e.firstName == value);
                            selectedEngineer = eng.id;

                            if (dateCtrl.text.isEmpty) return;

                            final month = _getMonthNumber(dateCtrl.text);
                            final year = DateTime.now().year;
                            await _loadStatsForEngineerAndMonth(
                              engineerId: eng.id!,
                              year: year,
                              month: month,
                            );
                            await _notificationService.send(
                              title: "تقييم المهندس",
                              message: "تم تحديث تقييم المهندس ${engineerCtrl.text} لشهر ${dateCtrl.text}",
                              route: "/home",
                              userId: "123",
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // 🔵 Label + Champ mois
                        buildLabel("الشهر"),
                        NewRoundSelectField(
                          hintText: "اختيار الشهر",
                          options: arabicMonths,
                          controller: dateCtrl,
                          rightIcon: const Icon(Icons.calendar_month),
                          onChanged: (value) async {
                            final month = _getMonthNumber(value!);
                            final year = DateTime.now().year;

                            if (selectedEngineer != null) {
                              await _loadStatsForEngineerAndMonth(
                                engineerId: selectedEngineer!,
                                year: year,
                                month: month,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ⭐ CARD 2 : STATISTIQUES
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "الإحصائيات",
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 🟨 ligne 1 : عدد المهام + عدد المكتملة
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  buildLabel("عدد المهام"),
                                  NewRoundTextField(
                                    hintText: "عدد المهام",
                                    controller: tasksCountCtrl,
                                    keyboardType: TextInputType.number,
                                    right: const Icon(Icons.list_alt, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  buildLabel("عدد المهام المكتملة"),
                                  NewRoundTextField(
                                    hintText: "عدد المهام المكتملة",
                                    controller: completedTasksCtrl,
                                    keyboardType: TextInputType.number,
                                    right: const Icon(Icons.check_circle, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        // 🟨 ligne 2 : عدد ساعات + الإضافية
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  buildLabel("عدد ساعات العمل"),
                                  NewRoundTextField(
                                    hintText: "عدد ساعات العمل",
                                    controller: totalHoursCtrl,
                                    keyboardType: TextInputType.number,
                                    right: const Icon(Icons.access_time, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  buildLabel("عدد الساعات الإضافية"),
                                  NewRoundTextField(
                                    hintText: "عدد الساعات الإضافية",
                                    controller: overtimeHoursCtrl,
                                    keyboardType: TextInputType.number,
                                    right: const Icon(Icons.timer, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        // 🟨 ligne 3 : الأيام + المدة التقديرية
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  buildLabel("عدد أيام العمل"),
                                  NewRoundTextField(
                                    hintText: "عدد أيام العمل",
                                    controller: totalDaysCtrl,
                                    keyboardType: TextInputType.number,
                                    right: const Icon(Icons.calendar_today, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  buildLabel("المدة التقديرية"),
                                  NewRoundTextField(
                                    hintText: "المدة التقديرية",
                                    controller: totalDurationCtrl,
                                    keyboardType: TextInputType.number,
                                    right: const Icon(Icons.timelapse, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ⭐ PDF BUTTON
              SizedBox(
                width: 240,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _generatePDF,
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: const Text(
                    "توليد ملف PDF",
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),

        /******************/
        floatingActionButton: FloatingActionButton(
          backgroundColor: TColor.primary,
          shape: const CircleBorder(),
          onPressed: () {
            CustomSnackBar.show(context,
                message: "زر مخصص لإضافة محتوى جديد",
                type: SnackBarType.info);
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


  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

}

