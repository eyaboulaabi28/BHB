
import 'dart:async';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/attendance_model.dart';
import 'package:app_bhb/data/auth/models/customers_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_attendance.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_attendance_time.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_customers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../../service_locator.dart';
import 'dart:typed_data';

/// ================== FORM FIELD CONFIG ==================
class FormFieldConfig {
  final String key;
  final String hint;
  final Widget? icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  FormFieldConfig({
    required this.key,
    required this.hint,
    this.icon,
    this.keyboardType,
    this.validator,
  });
}

/// ================== ADD ATTENDANCE MODAL ==================


class AddAttendanceModal extends StatefulWidget {
  final Function(Map<String, dynamic> values) onAdd;
  final String title;
  final String submitButtonText;
  final String? initialEmployeeName;
  final String employeeId;
  final String? userRole;
  final String? initialStartTime;
  final String? initialEndTime;
  final bool isEditWorkHoursMode;

  const AddAttendanceModal({
    super.key,
    required this.onAdd,
    this.title = "إضافة حضور و الانصراف جديد للموظف",
    this.submitButtonText = "إضافة",
    this.initialEmployeeName,
    required this.employeeId,
    this.userRole,
    this.initialStartTime,
    this.initialEndTime,
    this.isEditWorkHoursMode = false,
  });

  @override
  State<AddAttendanceModal> createState() => _AddAttendanceModalState();
}

class _AddAttendanceModalState extends State<AddAttendanceModal> {

  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSubmitting = false;
  Timer? _hoursTimer;
  String? selectedHoursType;
  late final Map<String, TextEditingController> _controllers;
  List<Customers> customers = [];
  final TextEditingController customerCtrl = TextEditingController();
  String? selectedCustomerId;
  String? signatureUrl;
  String? hoursErrorMessage;
  bool get isAdmin => widget.userRole == "admin";

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  @override
  void initState() {
    super.initState();

    _loadCustomers();
    _hoursTimer?.cancel();

    // 🔥 1. إنشاء controllers أولاً
    _controllers = {
      "employeeName": TextEditingController(text: widget.initialEmployeeName ?? ""),
      "date": TextEditingController(text: _formatDate(DateTime.now())),
      "startTime": TextEditingController(),
      "endTime": TextEditingController(),
      "waitingHours": TextEditingController(),
      "overtimeHours": TextEditingController(),
      "customerName": TextEditingController(),
      "notes": TextEditingController(),
    };

    // 🔥 2. ثم تحميل من Firebase
    _loadAttendanceTime();
  }


  String _formatDate(DateTime date) =>
      "${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}";

  String _twoDigits(int n) => n >= 10 ? "$n" : "0$n";

  Future<void> _loadCustomers() async {
    final result = await sl<GetCustomerUseCase>().call();
    if (!mounted) return;
    result.fold(
          (e) => debugPrint("Error customers"),
          (list) => setState(() => customers = List<Customers>.from(list)),
    );
  }

  Future<void> _loadAttendanceTime() async {
    final result = await sl<GetAttendanceTimeUseCase>().call();

    if (!mounted) return;

    result.fold(
          (failure) {
        debugPrint("Error loading attendance time: $failure");

        setState(() {
          _controllers["startTime"]!.text = "06:30";
          _controllers["endTime"]!.text = "16:30";
        });
      },
          (attendance) {
        if (attendance != null &&
            attendance.startTime != null &&
            attendance.endTime != null) {

          final start = attendance.startTime!;
          final end = attendance.endTime!;

          setState(() {
            _controllers["startTime"]!.text =
            "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}";

            _controllers["endTime"]!.text =
            "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}";
          });
        } else {
          setState(() {
            _controllers["startTime"]!.text = "06:30";
            _controllers["endTime"]!.text = "16:30";
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _hoursTimer?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }
  Future<String?> _uploadSignatureToFirebase(Uint8List bytes) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('signatures/attendance_${DateTime.now().millisecondsSinceEpoch}.png');
      final task = await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
      return await task.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Signature upload error: $e");
      return null;
    }
  }
  Widget _buildSignatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "التوقيع الإلكتروني",
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Signature(
              controller: _signatureController,
              backgroundColor: Colors.grey.shade100,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _signatureController.clear(),
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text("مسح التوقيع"),
          ),
        ),
      ],
    );
  }

  List<Step> _buildSteps() {

    if (widget.isEditWorkHoursMode) {
      return [
        Step(
          title: const Text("أوقات الدوام"),
          isActive: true,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text("بداية الدوام",
                  style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(height: 5),
              NewRoundTextField(
                hintText: "08:30",
                controller: _controllers["startTime"],
                right: const Icon(Icons.login),
              ),

              const SizedBox(height: 12),

              const Text("نهاية الدوام",
                  style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(height: 5),
              NewRoundTextField(
                hintText: "16:30",
                controller: _controllers["endTime"],
                right: const Icon(Icons.logout),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      Step(
        title: const Text("الموظف"),
        isActive: _currentStep >= 0,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("اسم الموظف",
                style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 5),
            NewRoundTextField(
              hintText: "اسم الموظف",
              controller: _controllers["employeeName"],
              right: const Icon(Icons.person),
              readOnly: true,
            ),
            const SizedBox(height: 12),
            const Text("التاريخ",
                style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 5),
            NewRoundTextField(
              hintText: "التاريخ",
              controller: _controllers["date"],
              right: const Icon(Icons.date_range),
              readOnly: true,
            ),
            const SizedBox(height: 17),
            const Text("اسم العميل",
                style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 5),
            NewRoundSelectField(
              hintText: "اختيار العميل",
              enableSearch: true,
              options: customers.map((c) => c.firstName ?? "").toList(),
              controller: customerCtrl,
              rightIcon: const Icon(Icons.person),
              onChanged: (value) {
                final customer = customers.firstWhere(
                        (c) => c.firstName == value,
                    orElse: () => Customers(id: "", firstName: ""));
                selectedCustomerId =
                (customer.id ?? "").isEmpty ? null : customer.id;
              },
            ),
          ],
        ),
      ),

      Step(
        title: const Text("الدوام"),
        isActive: _currentStep >= 1,
        content: StatefulBuilder(
          builder: (context, setStepState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text("بداية الدوام",
                    style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 5),
                NewRoundTextField(
                  hintText: "بداية الدوام",
                  controller: _controllers["startTime"],
                  right: const Icon(Icons.login),
                  readOnly: true,
                ),

                const SizedBox(height: 12),

                const Text("نهاية الدوام",
                    style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 5),
                NewRoundTextField(
                  hintText: "نهاية الدوام",
                  controller: _controllers["endTime"],
                  right: const Icon(Icons.logout),
                  readOnly: true,
                ),

                const SizedBox(height: 12),

                const Text("نوع الساعات",
                    style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),

                const SizedBox(height: 5),

                FormField<String>(
                  validator: (_) =>
                  (selectedHoursType == null)
                      ? "الرجاء اختيار نوع الساعات"
                      : null,
                  builder: (state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        NewRoundSelectField(
                          hintText: "اختيار نوع الساعات",
                          options: const [
                            "عدد ساعات الانتظار",
                            "عدد الساعات الإضافية"
                          ],
                          controller: TextEditingController(
                            text: selectedHoursType == "waiting"
                                ? "عدد ساعات الانتظار"
                                : selectedHoursType == "overtime"
                                ? "عدد الساعات الإضافية"
                                : "",
                          ),
                          rightIcon: const Icon(Icons.access_time),
                          onChanged: (value) {
                            setState(() {
                              selectedHoursType = value == "عدد ساعات الانتظار"
                                  ? "waiting"
                                  : "overtime";
                            });
                            state.didChange(value);
                          },
                        ),

                        if (state.hasError)
                          Padding(
                            padding:
                            const EdgeInsets.only(top: 5, right: 20),
                            child: Text(
                              state.errorText!,
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontFamily: 'Tajawal',
                                  fontSize: 12),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),

      Step(
        title: const Text("العميل والتوقيع"),
        isActive: _currentStep >= 2,
        content: SizedBox(
          height: 400,
          child: _buildSignatureSection(),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final modalHeight = MediaQuery.of(context).size.height * 0.9;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: modalHeight,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(widget.title, style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 15),
              Expanded(
                child: Stepper(
                  currentStep: _currentStep,
                  type: StepperType.horizontal,
                  controlsBuilder: (_, __) => const SizedBox(),
                  steps: _buildSteps(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: TColor.secondary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () {
                        if (_currentStep == 0) {
                          Navigator.pop(context);
                        } else {
                          setState(() => _currentStep--);
                        }
                      },
                      child: Text(
                        _currentStep == 0 ? "إلغاء" : "السابق",
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold, color: TColor.secondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColor.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () async {

                        // ⭐ ===== MODE SETTINGS (SANS STEPPER) =====
                        if (widget.isEditWorkHoursMode) {
                          final start = _controllers["startTime"]!.text.trim();
                          final end = _controllers["endTime"]!.text.trim();

                          // ✅ validation simple
                          if (start.isEmpty || end.isEmpty) {
                            CustomSnackBar.show(
                              context,
                              message: "يرجى إدخال أوقات صحيحة",
                              type: SnackBarType.error,
                            );
                            return;
                          }

                          // ✅ envoyer vers SettingsPage
                          widget.onAdd({
                            "startTime": start,
                            "endTime": end,
                          });

                          Navigator.pop(context);
                          return; // 🚨 مهم جدا
                        }

                        // 🔻 ===== MODE NORMAL (STEPPER) =====
                        setState(() => _isSubmitting = true);

                        try {
                          bool stepValid = true;

                          // ✅ validation step 0
                          if (_currentStep == 0) {
                            if ((_controllers["employeeName"]?.text.trim().isEmpty ?? true) ||
                                customerCtrl.text.trim().isEmpty) {
                              stepValid = false;
                            }
                          }

                          // ✅ validation step 1
                          else if (_currentStep == 1) {
                            if (selectedHoursType == null) {
                              stepValid = false;
                            } else {
                              final controller = _controllers[
                              selectedHoursType == "waiting"
                                  ? "waitingHours"
                                  : "overtimeHours"];

                              if (controller == null || controller.text.trim().isEmpty) {
                                stepValid = false;
                              }
                            }
                          }

                          // ❌ إذا غير صالح
                          if (!stepValid) {
                            setState(() => _isSubmitting = false);
                            return;
                          }

                          // ✅ الانتقال بين الخطوات
                          if (_currentStep < _buildSteps().length - 1) {
                            setState(() {
                              _currentStep++;
                              _isSubmitting = false;
                            });
                            return;
                          }

                          // ✅ آخر step → حفظ

                          // 🔹 signature
                          String? signatureUrl;
                          if (!_signatureController.isEmpty) {
                            final bytes = await _signatureController.toPngBytes();
                            if (bytes != null) {
                              signatureUrl = await _uploadSignatureToFirebase(bytes);
                            }
                          }

                          // 🔹 ساعات
                          final waitingHours = selectedHoursType == "waiting"
                              ? _controllers["waitingHours"]!.text.trim()
                              : null;

                          final overtimeHours = selectedHoursType == "overtime"
                              ? _controllers["overtimeHours"]!.text.trim()
                              : null;

                          // 🔹 object
                          final attendance = Attendance(
                            employeeId: widget.employeeId,
                            employeeName:
                            _controllers["employeeName"]?.text.trim(),
                            startTime: DateTime.tryParse(
                                "${_controllers["date"]?.text} ${_controllers["startTime"]?.text}"),
                            endTime: DateTime.tryParse(
                                "${_controllers["date"]?.text} ${_controllers["endTime"]?.text}"),
                            waitingHours: waitingHours,
                            overtimeHours: overtimeHours,
                            customerName: customerCtrl.text.trim(),
                            signatureUrl: signatureUrl,
                            notes: _controllers["notes"]?.text.trim(),
                            status: "present",
                          );

                          // 🔹 Firebase
                          final result = await sl<AddAttendanceUseCase>()
                              .call(params: attendance);

                          result.fold(
                                (l) {
                              Navigator.pop(context);
                              CustomSnackBar.show(
                                context,
                                message: l.toString(),
                                type: SnackBarType.error,
                              );
                            },
                                (r) {
                              CustomSnackBar.show(
                                context,
                                message: "تم إضافة الحضور بنجاح",
                                type: SnackBarType.success,
                              );
                              Navigator.pop(context);
                            },
                          );
                        } catch (e) {
                          debugPrint("Erreur onPressed: $e");
                          setState(() => _isSubmitting = false);
                        }
                      },

                      // ✅ TEXT BUTTON FIX
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
                        widget.isEditWorkHoursMode
                            ? "حفظ التعديل" // 🔥 أفضل UX
                            : (_currentStep < _buildSteps().length - 1
                            ? "التالي"
                            : widget.submitButtonText),
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}


