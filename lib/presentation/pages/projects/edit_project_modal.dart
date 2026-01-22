
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

class EditProjectModal extends StatefulWidget {
  final Project project;
  final void Function(Project updatedProject) onSubmit;

  const EditProjectModal({
    super.key,
    required this.project,
    required this.onSubmit,
  });

  @override
  State<EditProjectModal> createState() => _EditProjectModalState();
}

class _EditProjectModalState extends State<EditProjectModal> {
  late final Map<String, TextEditingController> _controllers;
  double? selectedLat;
  double? selectedLng;

  List<Customers> customers = [];
  List<Engineer> engineers = [];
  int _currentStep = 0;
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>()
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadEngineers();
    _controllers = {
      "municipality": TextEditingController(text: widget.project.municipality),
      "district": TextEditingController(text: widget.project.district),
      "projectName": TextEditingController(text: widget.project.projectName),
      "projectAddress": TextEditingController(text: widget.project.projectAddress),
      "ownerName": TextEditingController(text: widget.project.ownerName),
      "licenseNumber": TextEditingController(text: widget.project.licenseNumber),
      "plotNumber": TextEditingController(text: widget.project.plotNumber),
      "planNumber": TextEditingController(text: widget.project.planNumber),
      "buildingType": TextEditingController(text: widget.project.buildingType),
      "buildingDescription": TextEditingController(text: widget.project.buildingDescription),
      "floorsCount": TextEditingController(text: widget.project.floorsCount),
      "designerOffice": TextEditingController(text: widget.project.designerOffice),
      "supervisorOffice": TextEditingController(text: widget.project.supervisorOffice),
      "contractor": TextEditingController(text: widget.project.contractor),
      "engineerName": TextEditingController(text: widget.project.engineerName),
      "reportDate": TextEditingController(text: widget.project.reportDate),
      "phaseResult": TextEditingController(text: widget.project.phaseResult),
    };
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
  void _nextStep() {
    final form = _formKeys[_currentStep].currentState;
    if (form != null && form.validate()) {
      if (_currentStep < 2) {
        setState(() => _currentStep++);
      } else {
        final updatedProject = Project(
          id: widget.project.id,
          phoneNumber: widget.project.phoneNumber,
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

          // ✅ latitude / longitude
          latitude: selectedLat ?? widget.project.latitude,
          longitude: selectedLng ?? widget.project.longitude,
        );

        widget.onSubmit(updatedProject);
        Navigator.pop(context);
      }
    } else {
      debugPrint("Formulaire non prêt ou invalide");
    }
  }


  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }
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

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return Form(
          key: _formKeys[0],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepTitle("معلومات أساسية"),
              _buildInput(Icons.location_city, "الأمانة", _controllers["municipality"]!,
                  validator: "الرجاء إدخال الأمانة"),
              _buildInput(Icons.apartment, "البلدية", _controllers["district"]!,
                  validator: "الرجاء إدخال البلدية"),
              _buildInput(Icons.work, "اسم المشروع", _controllers["projectName"]!,
                  validator: "الرجاء إدخال اسم المشروع"),
              _buildInput(
                Icons.map,
                "عنوان المشروع",
                _controllers["projectAddress"]!,
                maxLines: 5,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SelectLocationMap(
                        initialLat: widget.project.latitude,
                        initialLng: widget.project.longitude,
                      ),
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      _controllers["projectAddress"]!.text = result["address"];
                      selectedLat = result["lat"];
                      selectedLng = result["lng"];
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
              const SizedBox(height: 10),
              _buildInput(Icons.confirmation_number, "رقم رخصة البناء",
                  _controllers["licenseNumber"]!),
              _buildInput(Icons.numbers, "رقم قطعة الأرض", _controllers["plotNumber"]!),
              _buildInput(Icons.pin, "رقم المخطط", _controllers["planNumber"]!),
              NewRoundSelectField(
                hintText: "نوع البناء",
                options: ["سكني", "تجاري", "صناعي","أماكن عامة"],
                controller: _controllers["buildingType"],
                rightIcon: Icon(Icons.home_work, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              _buildInput(
                Icons.description,
                "وصف البناء",
                _controllers["buildingDescription"]!,
                minLines: 5,
                maxLines: 10,
              ),
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
                _controllers["supervisorOffice"]!,maxLines: 5,),
              _buildInput(Icons.business, "مقاول البناء", _controllers["contractor"]!),
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
  Widget _buildInput(
      IconData icon,
      String hint,
      TextEditingController controller, {
        String? validator,
        VoidCallback? onTap,
        TextInputType keyboard = TextInputType.text,
        bool isDate = false,
        int minLines = 1, // 🔹 nombre de lignes par défaut
        int maxLines = 5, // 🔹 nombre max de lignes
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NewRoundTextField(
        hintText: hint,
        controller: controller,
        validator: validator != null
            ? (v) {
          if (v == null || v.isEmpty) return validator;
          return null;
        }
            : null,
        keyboardType: keyboard,
        obscureText: false,
        onTap: onTap,
        minLines: minLines,
        maxLines: maxLines,
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
                  "تعديل المشروع",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: TColor.secondary,
                  ),
                ),
                const SizedBox(height: 20),
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
}
