import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/common_widget/custom_dialog.dart';
import 'package:app_bhb/common_widget/custom_search_bar.dart';
import 'package:app_bhb/common_widget/generic_form_modal.dart';
import 'package:app_bhb/data/auth/models/vacation_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_vacation.dart';
import 'package:app_bhb/presentation/pages/vacation/add_vacation_modal.dart';

import 'package:flutter/material.dart';

import '../../../service_locator.dart';


class VacationPage extends StatefulWidget {
  final String selectedType;

  const VacationPage({super.key, required this.selectedType});

  @override
  State<VacationPage> createState() => _VacationPageState();
}

class _VacationPageState extends State<VacationPage> {
  int _selectedIndex = 0;
  List<Vacation> vacations = [];
  bool isLoading = true;

  final getAllVacationsUC = sl<GetAllVacationUseCase>();
  final addVacationUC = sl<AddVacationUseCase>();
  final deleteVacationUC = sl<DeleteVacationUseCase>();

  @override
  void initState() {
    super.initState();
    _loadVacations();
  }
  Future<void> _loadVacations() async {
    setState(() => isLoading = true);

    final result = await getAllVacationsUC();

    result.fold(
          (error) {
        CustomSnackBar.show(context, message: error, type: SnackBarType.error);
      },
          (data) {
        setState(() {
          vacations = data;
        });
      },
    );

    setState(() => isLoading = false);
  }
  Future<void> _deleteVacation(String id) async {
    final result = await sl<DeleteVacationUseCase>().call(params: id);

    result.fold(
          (error) {
        CustomSnackBar.show(context, message: error, type: SnackBarType.error);
      },
          (_) {
        CustomSnackBar.show(context,
            message: "تم حذف العطلة", type: SnackBarType.success);

        _loadVacations(); // refresh
      },
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
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
                  "إعدادات العطل",
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "العطل الأسبوعية",
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: TColor.primary,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.red),
                title: const Text(
                  "يوم الجمعة",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // --- العطل الرسمية ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "العطل الرسمية",
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: TColor.primary,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : vacations.isEmpty
                  ? const Center(
                child: Text(
                  "لا توجد عطل",
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 18),
                ),
              )
                  : ListView.builder(
                itemCount: vacations.length,
                itemBuilder: (context, index) {
                  final vac = vacations[index];

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: TColor.primary.withOpacity(0.2),
                        child: Icon(Icons.schedule, color: TColor.primary),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 18), // <-- espace entre le titre et la date

                          Text(
                            vac.nameVacation ?? '',
                            style: const TextStyle(
                                fontFamily: 'Tajawal', fontSize: 18, fontWeight: FontWeight.w600
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            vac.dateVacation != null
                                ? "${vac.dateVacation!.day}/${vac.dateVacation!.month}/${vac.dateVacation!.year}"
                                : '',
                            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _deleteVacation(vac.id!);
                        },
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
              builder: (context) =>AddVacationModal(
                title: "إضافة عطلة جديدة",
                submitButtonText: "إضافة",
                onAdd: (values) {
                  setState(() {
                    vacations.add(
                      Vacation(
                        id: values["id"],
                        nameVacation: values["nameVacation"],
                        dateVacation: values["dateVacation"],
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

}


