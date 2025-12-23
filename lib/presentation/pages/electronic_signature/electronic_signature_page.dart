import 'dart:convert';

import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/common_widget/custom_bottom_nav.dart';
import 'package:app_bhb/data/auth/models/ElectronicSignatureModel.dart';
import 'package:app_bhb/data/auth/models/employees_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_signature.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_employees.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:signature/signature.dart';

import '../../../service_locator.dart';

class ElectronicSignaturePage extends StatefulWidget {
  final String selectedType;

  const ElectronicSignaturePage({super.key, required this.selectedType});

  @override
  State<ElectronicSignaturePage> createState() => _ElectronicSignaturePageState();
}

class _ElectronicSignaturePageState extends State<ElectronicSignaturePage> {
  int _selectedIndex = 0;
  List<Employees> employees = [];
  final TextEditingController engineerCtrl = TextEditingController();
  Key _selectKey = UniqueKey();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  Future<void> _saveSignature() async {
    if (_signatureController.isEmpty) {
      CustomSnackBar.show(context,
          message: "الرجاء التوقيع أولاً",
          type: SnackBarType.warning);
      return;
    }

    if (engineerCtrl.text.isEmpty) {
      CustomSnackBar.show(context,
          message: "الرجاء اختيار المستخدم",
          type: SnackBarType.warning);
      return;
    }

    try {
      final Uint8List? signatureBytes = await _signatureController.toPngBytes();
      if (signatureBytes == null) throw Exception("لا يمكن تحويل التوقيع إلى صورة");

      final String signatureBase64 = base64Encode(signatureBytes);

      final selectedEmployee = employees.firstWhere((e) => e.firstName == engineerCtrl.text);

      final model = ElectronicSignatureModel(
        userId: selectedEmployee.id ?? "",
        signatureImage: signatureBase64,
        createdAt: DateTime.now(),
      );

      await sl<AddElectronicSignatureUseCase>().call(model);

      CustomSnackBar.show(context,
          message: "✔ تم حفظ التوقيع بنجاح",
          type: SnackBarType.success);

      // Clear signature
      _signatureController.clear();

      // Clear controller et forcer le rebuild du select
      setState(() {
        engineerCtrl.clear();
        _selectKey = UniqueKey();
      });

    } catch (e) {
      CustomSnackBar.show(context,
          message: "حدث خطأ أثناء الحفظ",
          type: SnackBarType.error);
    }
  }
 // Déclaré dans l'état


  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  Future<void> _loadUsers() async {
    final result = await sl<GetUsersUseCase>().call();
    result.fold( (error) => debugPrint("Error loading Employees"),
          (list) => setState(() => employees = List<Employees>.from(list)), ); }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }



  void _clearSignature() {
    _signatureController.clear();
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
        body: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER (inchangé)
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
                    "التوقيع الإلكتروني",
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

              /// --- 🟦 Section : Choix utilisateur ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "اختيار المستخدم",
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      NewRoundSelectField(
                        key: _selectKey,
                        hintText: "اختار المستخدم",
                        options: employees.map((e) => e.firstName ?? "").toList(),
                        controller: engineerCtrl,
                        rightIcon: Icon(Icons.person,
                            color: Colors.grey.shade600, size: 26),
                        validator: (v) =>
                        (v == null || v.isEmpty) ? "الرجاء اختيار المستخدم" : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              /// --- ✒️ Section : Zone de signature ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 14),

                      const Text(
                        "قم بإضافة توقيعك",
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        height: 290,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 1.2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Signature(
                            controller: _signatureController,
                            backgroundColor: Colors.grey.shade100,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              /// --- 🟩 Section : Boutons modernes ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  children: [
                    /// Effacer
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _clearSignature,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          "مسح",
                          style: TextStyle(
                            fontFamily: "Tajawal",
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    /// Sauvegarder
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveSignature,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColor.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          "حفظ",
                          style: TextStyle(
                            fontFamily: "Tajawal",
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),


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
}



