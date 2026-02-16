
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/customers_model.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_projects.dart';
import 'package:app_bhb/presentation/pages/customers/select_location_map.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/data/auth/models/engineers_model.dart';
import 'package:app_bhb/data/auth/models/projects_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_customers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_engineers.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import '../../../service_locator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';



class AddCustomerModal extends StatefulWidget {
  final void Function(Map<String, dynamic>) onAdd;
  final String title;
  final String submitButtonText;
  final BuildContext parentContext;
  final Function(Project project) onSubmit;
  const AddCustomerModal({
    super.key,
    required this.onAdd,
    this.title = "إضافة عميل جديد",
    this.submitButtonText = "إضافة",
    required this.parentContext,
    required this.onSubmit
  });

  @override
  State<AddCustomerModal> createState() => _AddCustomerModalState();
}

class _AddCustomerModalState extends State<AddCustomerModal> {
  double? selectedLat;
  double? selectedLng;
  bool _isSubmitting = false;

  late final CreateNotificationUseCase _createNotificationUseCase;
  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadEngineers();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
  }
  List<Customers> customers = [];
  List<Engineer> engineers = [];
  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());

  int _currentStep = 0;
  final List<Map<String, dynamic>> _steps = [
    {"icon": Icons.person, "label": "العميل"},
    {"icon": Icons.work, "label": "المشروع"},
    {"icon": Icons.description, "label": "الملكية"},
    {"icon": Icons.engineering, "label": "الجهات"},
  ];
  Future<void> _sendNotification({
    required String title,
    required String message,
    String? route,
    String? userId,
    String? targetRole,
  }) async {
    final notif = NotificationsModel(
      title: title,
      message: message,
      createdAt: DateTime.now(),
      userId: userId,
      route: route,
      targetRole: targetRole,
      isRead: false,
    );

    await _createNotificationUseCase.call(notification: notif);
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
    "email": TextEditingController(),
    "type": TextEditingController(),
  };

  void _nextStep() async {
    // 🔹 Empêche le double clic
    if (_isSubmitting) return;

    final form = _formKeys[_currentStep].currentState;

    if (form != null && form.validate()) {
      if (_currentStep < 3) {
        setState(() => _currentStep++);
      } else {
        // 🔹 Début de soumission
        setState(() => _isSubmitting = true);

        /// 🔹 1️⃣ Création du Customer
        final newCustomer = Customers(
          firstName: _controllers["ownerName"]!.text,
          email: _controllers["email"]!.text,
          phone: _controllers["phoneNumber"]!.text,
          type: _controllers["type"]!.text,
          role: "customer",
          latitude: selectedLat,
          longitude: selectedLng,
        );

        final customerResult =
        await sl<AddCustomerUseCase>().call(params: newCustomer);

        customerResult.fold(
              (failure) {
            // 🔹 Erreur : réactive le bouton
            setState(() => _isSubmitting = false);

            Navigator.pop(context);
            CustomSnackBar.show(
              widget.parentContext,
              message: failure.toString(),
              type: SnackBarType.error,
            );
          },
              (customerId) async {
            /// 🔹 2️⃣ Création du Project lié au customer
            final project = Project(
              ownerName: newCustomer.firstName,
              municipality: _controllers["municipality"]!.text,
              district: _controllers["district"]!.text,
              projectName: _controllers["projectName"]!.text,
              projectAddress: _controllers["projectAddress"]!.text,
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
              latitude: selectedLat,
              longitude: selectedLng,
            );

            final projectResult =
            await sl<AddProjectUseCase>().call(params: project);

            projectResult.fold(
                  (failure) {
                // 🔹 Erreur projet : réactive le bouton
                setState(() => _isSubmitting = false);

                Navigator.pop(context);
                CustomSnackBar.show(
                  widget.parentContext,
                  message: "تم إنشاء العميل لكن فشل إنشاء المشروع",
                  type: SnackBarType.error,
                );
              },
                  (_) {
                // 🔹 Succès : reset le bouton et montrer success
                setState(() => _isSubmitting = false);

                CustomSnackBar.show(
                  context,
                  message: "تم إضافة العميل والمشروع بنجاح",
                  type: SnackBarType.success,
                );

                _sendNotification(
                  title: "إضافة عميل",
                  message: "تم إضافة العميل: ${newCustomer.firstName ?? ""}",
                  route: "/home",
                  targetRole: "admin",
                  userId: null,
                );

                _sendNotification(
                  title: "إضافة المشروع",
                  message:
                  "تم إضافة المشروع ${project.projectName ?? ""} وصاحب المشروع هو العميل ${newCustomer.firstName ?? ""}",
                  route: "/home",
                  targetRole: "admin",
                  userId: null,
                );

                Navigator.pop(context);
              },
            );
          },
        );
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

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      if (kIsWeb) {
        final url = Uri.parse(
            "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1&accept-language=ar");
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data["display_name"] ?? "غير معروف";
        } else {
          return "غير معروف";
        }
      }
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return "غير معروف";
      final p = placemarks.first;
      final locality = p.locality ?? "";
      final street = p.street ?? "";
      final country = p.country ?? "";
      if (locality.isEmpty && street.isEmpty && country.isEmpty) return "غير معروف";
      return "$locality - $street - $country".trim();
    } catch (e) {
      print("Reverse Geocoding Error: $e");
      return "غير معروف";
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
              _buildStepTitle("معلومات العميل"),
              _buildInput(Icons.person, "اسم العميل", _controllers["ownerName"]!),
              _buildInput(Icons.email, "البريد الإلكتروني", _controllers["email"]!),
              _buildInput(Icons.phone, "رقم العميل", _controllers["phoneNumber"]!),
              NewRoundSelectField(
                hintText: "نوع العميل",
                controller: _controllers["type"],
                rightIcon: const Icon(Icons.category),
                options: ["فردي", "شركة"],
                enableSearch:true,

              ),
              const SizedBox(height: 10),
              _buildInput(
                Icons.map,
                "عنوان المشروع",
                _controllers["projectAddress"]!,
                keyboard: TextInputType.text,
                onTap: () async {
                  final result = await Navigator.push(
                    widget.parentContext,
                    MaterialPageRoute(
                      builder: (_) => SelectLocationMap(
                        initialLat: selectedLat,
                        initialLng: selectedLng,
                      ),
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      selectedLat = result["lat"];
                      selectedLng = result["lng"];
                      _controllers["projectAddress"]!.text = result["address"];
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
              _buildStepTitle("معلومات المشروع"),
              _buildInput(Icons.work, "اسم المشروع", _controllers["projectName"]!),
              NewRoundSelectField(
                hintText: "نوع البناء",
                options: ["سكني", "تجاري", "صناعي","أماكن عامة"],
                controller: _controllers["buildingType"],
                rightIcon: Icon(Icons.home_work, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              _buildInput(Icons.description, "وصف البناء", _controllers["buildingDescription"]! ,  minLines: 1, maxLines: 10, ),
              _buildInput(Icons.stairs, "عدد الأدوار", _controllers["floorsCount"]!, keyboard: TextInputType.number),
            ],
          ),
        );

      case 2:
        return Form(
          key: _formKeys[2],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepTitle("تفاصيل الملكية"),
              _buildInput(Icons.confirmation_number, "رقم رخصة البناء", _controllers["licenseNumber"]!),
              _buildInput(Icons.numbers, "رقم قطعة الأرض", _controllers["plotNumber"]!),
              _buildInput(Icons.pin, "رقم المخطط", _controllers["planNumber"]!),
              _buildInput(Icons.calendar_today, "تاريخ التقرير", _controllers["reportDate"]!, keyboard: TextInputType.datetime, isDate: true),
            ],
          ),
        );

      case 3:
        return Form(
          key: _formKeys[3],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepTitle("الجهات المشرفة"),
              _buildInput(Icons.design_services, "مكتب المصمم المعتمد", _controllers["designerOffice"]!),
              _buildInput(Icons.architecture, "المكتب الهندسي المشرف", _controllers["supervisorOffice"]!,maxLines: 5,),
              _buildInput(Icons.business, "مقاول البناء", _controllers["contractor"]!),
              NewRoundSelectField(
                hintText: "اسم المهندس المشرف",
                options: engineers.map((e) => e.firstName ?? "").toList(),
                controller: _controllers["engineerName"],
                rightIcon: const Icon(Icons.person),
              ),
              const SizedBox(height: 10),

              NewRoundSelectField(
                hintText: "نتيجة فحص المرحلة",
                options: ["مطابق", "غير مطابق"],
                controller: _controllers["phaseResult"],
                rightIcon: Icon(Icons.fact_check, color: Colors.grey),
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
        bool isDate = false,VoidCallback? onTap,  int minLines = 1,
        int maxLines = 5, }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NewRoundTextField(
        hintText: hint,
        controller: controller,
        validator: validator != null ? (v) => v!.isEmpty ? validator : null : null,
        keyboardType: keyboard,
        readOnly: onTap != null ? true : false,

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
                  "  إضافة عميل جديد",
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: TColor.secondary,
                  ),
                ),
                const SizedBox(height: 20),
                _buildProfessionalStepper(),
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
                        onPressed: _isSubmitting ? null : _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColor.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          _currentStep == 3 ? "إضافة" : "التالي",
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
  Widget _buildProfessionalStepper() {
    return Row(
      children: List.generate(_steps.length, (index) {
        final isActive = index <= _currentStep;

        return Expanded(
          child: Row(
            children: [
              /// الخط قبل الدائرة (ما عدا أول عنصر)
              if (index != 0)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 3,
                    color: index <= _currentStep
                        ? TColor.primary
                        : Colors.grey.shade300,
                  ),
                ),

              /// الدائرة
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? TColor.primary : Colors.white,
                  border: Border.all(
                    color: isActive
                        ? TColor.primary
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: Icon(
                  _steps[index]["icon"],
                  size: 18,
                  color: isActive ? Colors.white : Colors.grey,
                ),
              ),

              /// الخط بعد الدائرة (ما عدا الأخير)
              if (index != _steps.length - 1)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 3,
                    color: index < _currentStep
                        ? TColor.primary
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

}
