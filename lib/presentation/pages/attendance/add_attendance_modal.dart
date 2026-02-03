
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/attendance_model.dart';
import 'package:app_bhb/data/auth/models/customers_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_attendance.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_customers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../../service_locator.dart';

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

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
  const AddAttendanceModal({
    super.key,
    required this.onAdd,
    this.title = "إضافة حضور و الانصراف جديد للموظف",
    this.submitButtonText = "إضافة",
    this.initialEmployeeName,
    required this.employeeId,
  });

  @override
  State<AddAttendanceModal> createState() => _AddAttendanceModalState();
}

class _AddAttendanceModalState extends State<AddAttendanceModal> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSubmitting = false;

  String? selectedHoursType;
  late final Map<String, TextEditingController> _controllers;
  List<Customers> customers = [];
  final TextEditingController customerCtrl = TextEditingController();
  String? selectedCustomerId;
  String? signatureUrl;
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    _loadCustomers();

    _controllers = {
      "employeeName": TextEditingController(text: widget.initialEmployeeName ?? ""),
      "date": TextEditingController(text: _formatDate(DateTime.now())),
      "startTime": TextEditingController(text: "06:30"),
      "endTime": TextEditingController(text: "16:30"),
      "waitingHours": TextEditingController(),
      "overtimeHours": TextEditingController(),
      "customerName": TextEditingController(),
      "notes": TextEditingController(),
    };
  }
  String _calculateDiffFromEndTime() {
    final endTimeText = _controllers["endTime"]?.text;
    final dateText = _controllers["date"]?.text;

    if (endTimeText == null || dateText == null) return "";

    final endDateTime = DateTime.tryParse("$dateText $endTimeText");
    if (endDateTime == null) return "";

    final now = DateTime.now();

    if (now.isBefore(endDateTime)) return "00:00";

    final diff = now.difference(endDateTime);

    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);

    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
  }

  String _formatDate(DateTime date) =>
      "${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}";

  String _twoDigits(int n) => n >= 10 ? "$n" : "0$n";

  Future<void> _loadCustomers() async {
    final result = await sl<GetCustomerUseCase>().call();
    result.fold(
          (e) => debugPrint("Error customers"),
          (list) => setState(() => customers = List<Customers>.from(list)),
    );
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
    return [
      Step(
        title: const Text("الموظف"),
        isActive: _currentStep >= 0,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("اسم الموظف", style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 5),
            NewRoundTextField(
              hintText: "اسم الموظف",
              controller: _controllers["employeeName"],
              right: const Icon(Icons.person),
              readOnly: true,
            ),
            const SizedBox(height: 12),
            const Text("التاريخ", style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 5),
            NewRoundTextField(
              hintText: "التاريخ",
              controller: _controllers["date"],
              right: const Icon(Icons.date_range),
              readOnly: true,
            ),
            const SizedBox(height: 17),
            const Text("اسم العميل", style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 5),
            NewRoundSelectField(
              hintText: "اختيار العميل",
              enableSearch: true,
              options: customers.map((c) => c.firstName ?? "").toList(),
              controller: customerCtrl,
              rightIcon: const Icon(Icons.person),
              onChanged: (value) {
                final customer = customers.firstWhere((c) => c.firstName == value, orElse: () => Customers(id: "", firstName: ""));
                selectedCustomerId = (customer.id ?? "").isEmpty ? null : customer.id;
              },
            ),
          ],
        ),
      ),
      Step(
        title: const Text("الدوام"),
        isActive: _currentStep >= 1,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("بداية الدوام", style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 5),
            NewRoundTextField(
              hintText: "بداية الدوام",
              controller: _controllers["startTime"],
              right: const Icon(Icons.login),
              readOnly: true,
            ),
            const SizedBox(height: 12),
            const Text("نهاية الدوام", style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 5),
            NewRoundTextField(
              hintText: "نهاية الدوام",
              controller: _controllers["endTime"],
              right: const Icon(Icons.logout),
              readOnly: true,
            ),
            const SizedBox(height: 12),
            const Text("نوع الساعات", style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 5),
            FormField<String>(
              validator: (_) => (selectedHoursType == null) ? "الرجاء اختيار نوع الساعات" : null,
              builder: (state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NewRoundSelectField(
                      hintText: "اختيار نوع الساعات",
                      options: const ["عدد ساعات الانتظار", "عدد الساعات الإضافية"],
                      controller: TextEditingController(
                        text: selectedHoursType == "waiting" ? "عدد ساعات الانتظار" : selectedHoursType == "overtime" ? "عدد الساعات الإضافية" : "",
                      ),
                      rightIcon: const Icon(Icons.access_time),
                      onChanged: (value) {
                        setState(() {
                          if (value == "عدد ساعات الانتظار") {
                            selectedHoursType = "waiting";
                            _controllers["overtimeHours"]?.clear();
                            _controllers["waitingHours"]?.text = _calculateDiffFromEndTime();
                          } else if (value == "عدد الساعات الإضافية") {
                            selectedHoursType = "overtime";
                            _controllers["waitingHours"]?.clear();
                            _controllers["overtimeHours"]?.text = _calculateDiffFromEndTime();
                          }
                          state.didChange(value);
                        });
                      },

                    ),
                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 5, right: 20),
                        child: Text(state.errorText!, style: const TextStyle(color: Colors.red, fontFamily: 'Tajawal', fontSize: 12)),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 15),
            if (selectedHoursType != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedHoursType == "waiting" ? "عدد ساعات الانتظار" : "عدد الساعات الإضافية",
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  NewRoundTextField(
                    hintText: selectedHoursType == "waiting" ? "عدد ساعات الانتظار" : "عدد الساعات الإضافية",
                    controller: _controllers[selectedHoursType == "waiting" ? "waitingHours" : "overtimeHours"],
                    keyboardType: TextInputType.number,
                    right: const Icon(Icons.access_time_filled),
                    readOnly: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "مطلوب";
                      final regex = RegExp(r'^\d{1,2}:\d{2}$');
                      if (!regex.hasMatch(v)) return "الرجاء إدخال الوقت بصيغة hh:mm";
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "ملاحظات",
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 5),
                  NewRoundTextField(
                    hintText: "أدخل الملاحظات (اختياري)",
                    controller: _controllers["notes"],
                    maxLines: 3,
                    right: const Icon(Icons.notes),
                    minLines: 1,
                  ),
                ],
              ),
          ],
        ),
      ),
      Step(
        title: const Text("العميل والتوقيع"),
        isActive: _currentStep >= 2,
        content: SizedBox(height: 400, child: _buildSignatureSection()),
      ),
    ];
  }

  int? _timeToMinutes(String? value) {
    if (value == null || value.isEmpty) return null;

    final parts = value.split(":");
    if (parts.length != 2) return null;

    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);

    if (hours == null || minutes == null) return null;

    return hours * 60 + minutes;
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                        setState(() => _isSubmitting = true);

                        try {
                          bool stepValid = true;

                          // نفس التحقق متاعك
                          if (_currentStep == 0) {
                            if ((_controllers["employeeName"]?.text.trim().isEmpty ?? true) ||
                                (customerCtrl.text.trim().isEmpty)) {
                              stepValid = false;
                            }
                          } else if (_currentStep == 1) {
                            if (selectedHoursType == null) {
                              stepValid = false;
                            } else {
                              final controller = _controllers[selectedHoursType == "waiting"
                                  ? "waitingHours"
                                  : "overtimeHours"];
                              if (controller == null || controller.text.trim().isEmpty) {
                                stepValid = false;
                              }
                            }
                          }

                          if (!stepValid) {
                            setState(() => _isSubmitting = false);
                            return;
                          }

                          if (_currentStep < _buildSteps().length - 1) {
                            setState(() {
                              _currentStep++;
                              _isSubmitting = false;
                            });
                            return;
                          }

                          // 🔹 رفع التوقيع
                          String? signatureUrl;
                          if (!_signatureController.isEmpty) {
                            final bytes = await _signatureController.toPngBytes();
                            if (bytes != null) {
                              signatureUrl = await _uploadSignatureToFirebase(bytes);
                            }
                          }

                          final waitingMinutes = selectedHoursType == "waiting"
                              ? _timeToMinutes(_controllers["waitingHours"]?.text.trim())
                              : null;

                          final overtimeMinutes = selectedHoursType == "overtime"
                              ? _timeToMinutes(_controllers["overtimeHours"]?.text.trim())
                              : null;

                          final attendance = Attendance(
                            employeeId: widget.employeeId,
                            employeeName: _controllers["employeeName"]?.text.trim(),
                            startTime: DateTime.tryParse(
                                "${_controllers["date"]?.text} ${_controllers["startTime"]?.text}"),
                            endTime: DateTime.tryParse(
                                "${_controllers["date"]?.text} ${_controllers["endTime"]?.text}"),
                            waitingHours: waitingMinutes?.toDouble(),
                            overtimeHours: overtimeMinutes?.toDouble(),
                            customerName: customerCtrl.text.trim(),
                            signatureUrl: signatureUrl,
                            notes: _controllers["notes"]?.text.trim(),
                          );

                          final result =
                          await sl<AddAttendanceUseCase>().call(params: attendance);

                          result.fold(
                                (l) {
                              CustomSnackBar.show(
                                context,
                                message: "حدث خطأ: $l",
                                type: SnackBarType.error,
                              );
                              setState(() => _isSubmitting = false);
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
                          setState(() => _isSubmitting = false);
                        }
                      },


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
                        _currentStep < 2 ? "التالي" : widget.submitButtonText,
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


