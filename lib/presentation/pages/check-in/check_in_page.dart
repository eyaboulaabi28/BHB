
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/data/auth/models/check_in.dart';
import 'package:app_bhb/data/auth/models/daily_tasks_model.dart';
import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_check_in.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_daily_tasks.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_engineers.dart';
import 'package:app_bhb/presentation/pages/check-in/add_check_in_modal.dart';
import 'package:flutter/material.dart';

import '../../../service_locator.dart';

class CheckInPage extends StatefulWidget {
  final String selectedType;

  const CheckInPage({super.key, required this.selectedType});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  int _selectedIndex = 0;
  List<DailyCheckIn> dailyCheckIns = [];
  List<Engineer> engineers = [];
  List<DailyTasks> dailyTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDailyCheckIns();
    _loadEngineers();
    _loadDailyTasks();
  }

  Future<void> _loadEngineers() async {
    final result = await sl<GetEngineersUseCase>().call();
    result.fold( (error) => debugPrint("Error loading engineers"),
          (list) => setState(() => engineers = List<Engineer>.from(list)), ); }

  Future<void> _loadDailyTasks() async {
    final result = await sl<GetAllDailyTasksUseCase>().call();

    result.fold(
          (error) => debugPrint("Error loading DailyTasks"),
          (list) {
        setState(() {
          dailyTasks = list != null ? List<DailyTasks>.from(list) : [];
        });
      },
    );
  }


  Future<void> _fetchDailyCheckIns() async {
    final result = await sl<GetAllDailyCheckInUseCase>().call();
    result.fold(
          (error) {
        setState(() {
          _isLoading = false;
        });
        CustomSnackBar.show(
          context,
          message: "خطأ في جلب بيانات الحضور: $error",
          type: SnackBarType.error,
        );
      },
          (list) {
        setState(() {
          dailyCheckIns = list;
          _isLoading = false;
        });
      },
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _togglePresence(int index) {
    setState(() {
      final checkIn = dailyCheckIns[index];
      checkIn.presence = (checkIn.presence == "حاضر") ? "غائب" : "حاضر";
      if (checkIn.presence == "غائب") {
        checkIn.hoursTotal = "0";
      }
    });
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
            // Header
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
                  "تسجيل الحضور اليومي",
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : dailyCheckIns.isEmpty
                  ? const Center(child: Text("لا يوجد سجلات حضور اليوم"))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: dailyCheckIns.length,
                itemBuilder: (context, index) {
                  final checkIn = dailyCheckIns[index];

                  final engineerName = engineers.firstWhere(
                        (e) => e.id?.trim() == checkIn.engineerId?.trim(),
                    orElse: () => Engineer(id: null, firstName: "مهندس مجهول"),
                  ).firstName;
                  final taskName = dailyTasks.firstWhere((t)=>t.id?.trim()==checkIn.tasks?.trim(),
                      orElse:()=> DailyTasks(id:null,titleTask:"مهمة غير معروفة"),).titleTask;

                  // Calcul du pourcentage basé sur 8 heures
                  double hoursTotal = double.tryParse(checkIn.hoursTotal ?? "0") ?? 0;
                  int numberDay = int.tryParse(checkIn.numberDay ?? "1") ?? 1;
                  // Progress basé sur 8 heures par jour
                  double progress = (hoursTotal / (8 * numberDay)).clamp(0.0, 1.0);
                  // Heures supplémentaires = totalHeures - (8 * nombreDeJours)
                  double extraHours = hoursTotal - (8 * numberDay);
                  if (extraHours < 0) extraHours = 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ligne principale: avatar + nom + switch présence
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: TColor.primary.withOpacity(0.2),
                                child: Icon(Icons.person, color: TColor.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      engineerName ?? "",
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "المهمة: $taskName",
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),


                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => AddDailyCheckInModal(
                                      title: "تعديل الحضور",
                                      submitButtonText: "تحديث",
                                      existingData: dailyCheckIns[index],
                                      //onAdd: (data) => _refreshAfterEdit(data),
                                    ),
                                  ).then((_) {
                                    // ✅ Recharge la liste après la fermeture du modal
                                    _fetchDailyCheckIns();
                                  });
                                },
                              ),


                              Switch(
                                value: checkIn.presence == "حاضر",
                                onChanged: (_) => _togglePresence(index),
                                activeColor: TColor.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Ligne heures + tâches
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    "عدد ساعات اليوم: ${checkIn.hoursTotal}" +
                                        (extraHours > 0 ? " (+${extraHours.toStringAsFixed(1)})" : ""),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),

                            ],
                          ),

                          const SizedBox(height: 8),

                          // Barre de progression avec couleur selon heures supplémentaires
                          LinearProgressIndicator(
                            value: progress > 1 ? 1.0 : progress, // max 1 pour la barre normale
                            color: extraHours > 0 ? Colors.redAccent : TColor.primary,
                            backgroundColor: Colors.grey[300],
                            minHeight: 8,
                          ),
                          const SizedBox(height: 8),

                          if (extraHours > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "ساعات إضافية: ${extraHours.toStringAsFixed(1)}",
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent),
                              ),
                            ),

                          const SizedBox(height: 12),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  attributeItem(Icons.play_arrow, "ساعة الانطلاق", checkIn.hoursStart ?? "-"),
                                ],
                              ),
                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  attributeItem(Icons.stop, "ساعة النهاية", checkIn.hoursEnd ?? "-"),
                                ],
                              ),
                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  attributeItem(Icons.timer, "عدد الساعات", checkIn.hoursTotal ?? "-"),
                                ],
                              ),
                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  attributeItem(Icons.calendar_today, "أيام العمل", checkIn.numberDay ?? "-"),
                                ],
                              ),
                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  attributeItem(
                                    Icons.date_range,
                                    "تاريخ التسجيل",
                                    checkIn.createdAt != null
                                        ? "${checkIn.createdAt!.day}/${checkIn.createdAt!.month}/${checkIn.createdAt!.year}"
                                        : "-",
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  statusItem(checkIn.status),
                                ],
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
        floatingActionButton: FloatingActionButton(
          backgroundColor: TColor.primary,
          shape: const CircleBorder(),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddDailyCheckInModal(
                title: "تسجيل حضور اليوم",
                submitButtonText: "حفظ",


              ),
            )  .then((_) {
              // ✅ Recharge la liste après la fermeture du modal
              _fetchDailyCheckIns();
            });
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
  Widget attributeItem(IconData icon, String title, String value) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: TColor.primary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              "$title: $value",
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  Widget statusItem(String? status) {
    IconData icon;
    Color color;

    switch (status) {
      case "قيد الإنجاز":
        icon = Icons.timelapse;
        color = Colors.orange;
        break;
      case "مكتملة":
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case "متأخرة":
        icon = Icons.error;
        color = Colors.red;
        break;
      case "مازالت لم تبدأ":
        icon = Icons.pause_circle;
        color = Colors.grey;
        break;
      default:
        icon = Icons.help;
        color = Colors.blueGrey;
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          status ?? "-",
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),

        ),
        const SizedBox(width: 160),

      ],
    );
  }


}


