import 'package:app_bhb/data/auth/models/customers_model.dart';
import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:app_bhb/data/auth/models/projects_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_customers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_engineers.dart';
import 'package:app_bhb/presentation/pages/customers/select_location_map.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';

import '../../../service_locator.dart';

class AddProjectModal extends StatefulWidget {

  final Function(Project project) onSubmit;

  const AddProjectModal({super.key, required this.onSubmit});

  @override
  State<AddProjectModal> createState() => _AddProjectModalState();
}

class _AddProjectModalState extends State<AddProjectModal> {
  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadEngineers();
  }
  List<Customers> customers = [];
  List<Engineer> engineers = [];
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>()
  ];
  int _currentStep = 0;

  Future<void> _selectReportDate(TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale("ar", "SA"), // 🔹 locale arabe
      builder: (BuildContext context, Widget? child) {
        return Directionality( // 🔹 pour forcer la direction RTL
          textDirection: TextDirection.rtl,
          child: Theme(
            data: Theme.of(context),
            child: child!,
          ),
        );
      },
      useRootNavigator: true,
    );

    if (pickedDate != null) {
      controller.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
    }
  }

  final Map<String, TextEditingController> _controllers = {
    "municipality": TextEditingController(),
    "district": TextEditingController(),
    "projectName": TextEditingController(),
    "projectAddress": TextEditingController(),
    "ownerName": TextEditingController(),
    "licenseNumber": TextEditingController(),
    "plotNumber": TextEditingController(),
    "planNumber": TextEditingController(),
    "buildingType": TextEditingController(),
    "buildingDescription": TextEditingController(),
    "floorsCount": TextEditingController(),
    "designerOffice": TextEditingController(),
    "supervisorOffice": TextEditingController(),
    "contractor": TextEditingController(),
    "engineerName": TextEditingController(),
    "reportDate": TextEditingController(),
    "phaseResult": TextEditingController(),
    "phoneNumber": TextEditingController(),
  };

  void _nextStep() async {
    if (_formKeys[_currentStep].currentState!.validate()) {
      if (_currentStep < 2) {
        setState(() => _currentStep++);
      } else {
        // Création de l'objet Project à partir des controllers
        final project = Project(
          municipality: _controllers["municipality"]!.text,
          district: _controllers["district"]!.text,
          projectName: _controllers["projectName"]!.text,
          projectAddress: _controllers["projectAddress"]!.text,
          ownerName: _controllers["ownerName"]!.text,
          licenseNumber: _controllers["licenseNumber"]!.text,
          plotNumber: _controllers["plotNumber"]!.text,
          planNumber: _controllers["planNumber"]!.text,
          buildingType: _controllers["buildingType"]!.text,
          buildingDescription: _controllers["buildingDescription"]!.text,
          floorsCount: _controllers["floorsCount"]!.text,
          designerOffice: _controllers["designerOffice"]!.text,
          supervisorOffice: _controllers["supervisorOffice"]!.text,
          contractor: _controllers["contractor"]!.text,
          engineerName: _controllers["engineerName"]!.text,
          reportDate: _controllers["reportDate"]!.text,
          phaseResult: _controllers["phaseResult"]!.text,
          phoneNumber: _controllers["phoneNumber"]!.text,
        );

        widget.onSubmit(project); // 🔹 On renvoie le Project
        Navigator.pop(context);
      }
    }
  }
  Future<void> _loadEngineers() async {
    final result = await sl<GetEngineersUseCase>().call();

    if (!mounted) return;

    result.fold(
          (error) => debugPrint("Error loading engineers"),
          (list) => setState(() => engineers = List<Engineer>.from(list)),
    );
  }
  Future<void> _loadCustomers() async {
    final result = await sl<GetCustomerUseCase>().call();

    if (!mounted) return;

    result.fold(
          (error) => debugPrint("Error loading customers"),
          (list) => setState(() => customers = List<Customers>.from(list)),
    );
  }
  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }


  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return Form(
          key: _formKeys[0],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepTitle("معلومات أساسية"),
              _buildInput(Icons.location_city, "المدينة", _controllers["municipality"]!,
                  validator: "الرجاء إدخال المدينة"),
              _buildInput(Icons.apartment, "الحي", _controllers["district"]!,
                  validator: "الرجاء إدخال الحي"),
              _buildInput(Icons.work, "اسم المشروع", _controllers["projectName"]!,
                  validator: "الرجاء إدخال اسم المشروع"),
              _buildInput(
                Icons.map,
                "عنوان المشروع",
                _controllers["projectAddress"]!,
                onTap: () async {
                  final selected = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SelectLocationMap(),
                    ),
                  );

                  if (selected != null) {
                    setState(() {
                      _controllers["projectAddress"]!.text = selected["address"];
                    });
                  }
                },
              ),
            ],
          ),
        );

      case 1:
        return Form(
          key: _formKeys[1],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepTitle("تفاصيل الملكية"),
             // _buildInput(Icons.person, "اسم المالك", _controllers["ownerName"]!),
              NewRoundSelectField(
                hintText: "اسم المالك",
                options: customers.map((e) => e.firstName ?? "").toList(),
                controller: _controllers["ownerName"],
                rightIcon: const Icon(Icons.person),
                validator: (v) =>
                (v == null || v.isEmpty) ? "الرجاء اختيار اسم المالك" : null,
                onChanged: (value) {
                  final selectedCustomer = customers.firstWhere(
                        (c) => c.firstName == value,
                    orElse: () => Customers(),
                  );
                  _controllers["phoneNumber"]!.text =
                      selectedCustomer.phone ?? "";
                },
              ),

              const SizedBox(height: 10),
              _buildInput(
                Icons.phone,
                "رقم هاتف المالك",
                _controllers["phoneNumber"]!,
                keyboard: TextInputType.phone,
              ),
              _buildInput(Icons.confirmation_number, "رقم رخصة البناء",
                  _controllers["licenseNumber"]!),
              _buildInput(Icons.numbers, "رقم قطعة الأرض", _controllers["plotNumber"]!),
              _buildInput(Icons.pin, "رقم المخطط", _controllers["planNumber"]!),
              NewRoundSelectField(
                hintText: "نوع البناء",
                options: ["سكني", "تجاري", "صناعي","أماكن عامة"],
                controller: _controllers["buildingType"],
                rightIcon: Icon(Icons.home_work, color: Colors.grey), // icône à gauche gris
              ),
              const SizedBox(height: 10),
              _buildInput(Icons.description, "وصف البناء",
                  _controllers["buildingDescription"]!),
              _buildInput(Icons.stairs, "عدد الأدوار", _controllers["floorsCount"]!,
                  keyboard: TextInputType.number),
            ],
          ),
        );

      case 2:
        return Form(
          key: _formKeys[2],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepTitle("الجهات المشرفة"),
              _buildInput(Icons.design_services, "مكتب المصمم المعتمد",
                  _controllers["designerOffice"]!),
              _buildInput(Icons.architecture, "المكتب الهندسي المشرف",
                  _controllers["supervisorOffice"]!),
              _buildInput(Icons.business, "مقاول البناء", _controllers["contractor"]!),
              //_buildInput(Icons.engineering, "اسم المهندس المشرف", _controllers["engineerName"]!),
              NewRoundSelectField(
                hintText: "اسم المهندس المشرف",
                options: engineers.map((e) => e.firstName ?? "").toList(),
                controller: _controllers["engineerName"],
                rightIcon: const Icon(Icons.person),
                validator: (v) => (v == null || v.isEmpty) ? "الرجاء اختيار اسم المهندس المشرف" : null,
              ),
              const SizedBox(height: 10),
              _buildInput(Icons.calendar_today, "تاريخ التقرير",
                  _controllers["reportDate"]!,
               keyboard: TextInputType.datetime, isDate: true),

              NewRoundSelectField(
                hintText: "نتيجة فحص المرحلة",
                options: ["مطابق", "غير مطابق"],
                controller: _controllers["phaseResult"],
                rightIcon: Icon(Icons.fact_check, color: Colors.grey), // icône à gauche gris
              ),
            ],
          ),
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildStepTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: TColor.secondary,
        ),
      ),
    );
  }

  Widget _buildInput(IconData icon, String hint,
      TextEditingController controller,
      {String? validator,
        TextInputType keyboard = TextInputType.text,
        bool isDate = false,VoidCallback? onTap, }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NewRoundTextField(
        hintText: hint,
        controller: controller,
        validator: validator != null ? (v) => v!.isEmpty ? validator : null : null,
        keyboardType: keyboard,
        obscureText: false,
        onTap: onTap,
        right: isDate
            ? GestureDetector(
          onTap: () => _selectReportDate(controller),
          child: Icon(Icons.calendar_today, color: Colors.grey),
        )
            : Icon(icon, color: Colors.grey),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 850,
          ),
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "إضافة مشروع جديد",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: TColor.secondary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStepIcon(Icons.info, 0, "معلومات"),
                    _buildStepIcon(Icons.description, 1, "الملكية"),
                    _buildStepIcon(Icons.engineering, 2, "الجهات"),
                  ],
                ),
                const SizedBox(height: 25),
                _buildStepContent(_currentStep),
                const SizedBox(height: 25),
                Row(
                  children: [
                    // 🔹 Étape 0 : Afficher Annuler
                    if (_currentStep == 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: TColor.secondary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text(
                            "إلغاء",
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              color: TColor.secondary,
                            ),
                          ),
                        ),
                      ),
                    if (_currentStep == 0) const SizedBox(width: 10),

                    // 🔹 Étapes >0 : Bouton Précédent
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _prevStep,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: TColor.secondary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text(
                            "رجوع",
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              color: TColor.secondary,
                            ),
                          ),
                        ),
                      ),

                    if ((_currentStep > 0 || _currentStep == 0) ) const SizedBox(width: 10),

                    // 🔹 Bouton Suivant / Ajouter
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColor.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          _currentStep == 2 ? "إضافة" : "التالي",
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIcon(IconData icon, int step, String label) {
    final bool isActive = _currentStep == step;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive ? TColor.primary : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              color: isActive ? Colors.white : Colors.grey.shade700, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            color: isActive ? TColor.primary : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
