
import 'dart:async';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/attendance_model.dart';
import 'package:app_bhb/data/auth/models/customers_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_attendance.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_customers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  const AddAttendanceModal({
    super.key,
    required this.onAdd,
    this.title = "إضافة حضور و الانصراف جديد للموظف",
    this.submitButtonText = "إضافة",
    this.initialEmployeeName,
    required this.employeeId,
    this.userRole,
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
    _loadAttendanceTime();
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
  }



  Future<void> _loadAttendanceTime() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('AttendanceTime')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();

        final start = DateTime.parse(data['startTime']);
        final end = DateTime.parse(data['endTime']);

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
    } catch (e) {
      debugPrint("Error loading attendance time: $e");
    }
  }
  String _calculateDiffFromStartToEndDecimal() {
    try {
      final startParts = _controllers["startTime"]!.text.split(":");
      final endParts = _controllers["endTime"]!.text.split(":");

      if (startParts.length != 2 || endParts.length != 2) return "0.00";

      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes =
          int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      int diffMinutes = endMinutes - startMinutes;

      if (diffMinutes <= 0) return "0.00";

      final decimal = diffMinutes / 60.0;
      return decimal.toStringAsFixed(2);
    } catch (_) {
      return "0.00";
    }
  }

  double _parseHoursTextToDecimal(String text) {
    try {
      final regex = RegExp(r"(\d+)\s*ساعة\s*و\s*(\d+)\s*دقيقة");
      final match = regex.firstMatch(text);
      if (match != null) {
        final hours = int.parse(match.group(1)!);
        final minutes = int.parse(match.group(2)!);
        return hours + minutes / 60.0;
      }
    } catch (_) {}
    return 0.0;
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

  String _calculateDiffFromNowToEndTime() {
    try {
      final now = DateTime.now();

      final parts = _controllers["endTime"]!.text.split(":");
      if (parts.length != 2) return "0 ساعة";

      final endTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      final diffMinutes = now.difference(endTime).inMinutes.abs();
      if (diffMinutes <= 0) return "0 ساعة";

      final hours = diffMinutes ~/ 60;
      final minutes = diffMinutes % 60;

      return "$hours ساعة و $minutes دقيقة";
    } catch (_) {
      return "0 ساعة";
    }
  }



  void _startHoursTimer() {
    _hoursTimer?.cancel();

    _hoursTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted || selectedHoursType == null) return;

      final diff = _calculateDiffFromNowToEndTime();

      setState(() {
        _controllers[selectedHoursType == "waiting"
            ? "waitingHours"
            : "overtimeHours"]!
            .text = "$diff ";
      });
    });
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
        content: StatefulBuilder(
          builder: (context, setStepState) {

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "بداية الدوام",
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      const Text(
                        "(الرجاء إدخال الوقت بصيغة: ساعة:دقيقة مثل 08:30)",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 5),
                NewRoundTextField(
                  hintText: "بداية الدوام",
                  controller: _controllers["startTime"],
                  right: const Icon(Icons.login),
                  readOnly: !isAdmin,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      "نهاية الدوام",
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      const Text(
                        "(الرجاء إدخال الوقت بصيغة: ساعة:دقيقة مثل 08:30)",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 5),
                NewRoundTextField(
                  hintText: "نهاية الدوام",
                  controller: _controllers["endTime"],
                  right: const Icon(Icons.logout),
                  readOnly: !isAdmin,
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
                  (selectedHoursType == null) ? "الرجاء اختيار نوع الساعات" : null,
                  builder: (state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NewRoundSelectField(
                          hintText: "اختيار نوع الساعات",
                          options: const ["عدد ساعات الانتظار", "عدد الساعات الإضافية"],
                          controller: TextEditingController(
                            text: selectedHoursType == "waiting"
                                ? "عدد ساعات الانتظار"
                                : selectedHoursType == "overtime"
                                ? "عدد الساعات الإضافية"
                                : "",
                          ),
                          rightIcon: const Icon(Icons.access_time),
                          onChanged: (value) {
                            final now = DateTime.now();

                            final endParts = _controllers["endTime"]!.text.split(":");
                            if (endParts.length != 2) return;

                            final endTime = DateTime(
                              now.year,
                              now.month,
                              now.day,
                              int.parse(endParts[0]),
                              int.parse(endParts[1]),
                            );

                            if (now.isBefore(endTime)) {

                              setState(() {
                                hoursErrorMessage = "الوقت المحدد للإنصراف لم يحن بعد";
                              });
                              return;
                            }

                            setState(() {
                              hoursErrorMessage = null;
                              selectedHoursType = value == "عدد ساعات الانتظار" ? "waiting" : "overtime";

                              final diff = _calculateDiffFromNowToEndTime();

                              _controllers[selectedHoursType == "waiting"
                                  ? "waitingHours"
                                  : "overtimeHours"]!
                                  .text = "$diff ";

                              _startHoursTimer();
                              state.didChange(value);
                            });
                          },
                        ),
                        if (hoursErrorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 5, right: 20),
                            child: Text(
                              hoursErrorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontFamily: 'Tajawal',
                                fontSize: 12,
                              ),
                            ),
                          ),

                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 5, right: 20),
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
                const SizedBox(height: 15),
                if (selectedHoursType != null)
                  NewRoundTextField(
                    hintText: selectedHoursType == "waiting"
                        ? "عدد ساعات الانتظار"
                        : "عدد الساعات الإضافية",
                    controller: _controllers[selectedHoursType == "waiting"
                        ? "waitingHours"
                        : "overtimeHours"],
                    right: const Icon(Icons.access_time_filled),
                    readOnly: true,
                  ),
              ],
            );
          },
        ),
      ),





      Step(
        title: const Text("العميل والتوقيع"),
        isActive: _currentStep >= 2,
        content: SizedBox(height: 400, child: _buildSignatureSection()),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                        setState(() => _isSubmitting = true);

                        try {
                          bool stepValid = true;

                          // Vérification du step actuel
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

                          // Passer au step suivant si ce n'est pas le dernier
                          if (_currentStep < _buildSteps().length - 1) {
                            setState(() {
                              _currentStep++;
                              _isSubmitting = false;
                            });
                            return;
                          }

                          // 🔹 Charger le signature
                          String? signatureUrl;
                          if (!_signatureController.isEmpty) {
                            final bytes = await _signatureController.toPngBytes();
                            if (bytes != null) {
                              signatureUrl = await _uploadSignatureToFirebase(bytes);
                            }
                          }

                          // 🔹 Calculer les heures en décimal
                          final decimalHours = double.tryParse(
                            _calculateDiffFromStartToEndDecimal().replaceAll(',', '.'),
                          ) ??
                              0.0;

                          final waitingHours = selectedHoursType == "waiting"
                              ? _controllers["waitingHours"]!.text.trim()
                              : null;

                          final overtimeHours = selectedHoursType == "overtime"
                              ? _controllers["overtimeHours"]!.text.trim()
                              : null;

                          // 🔹 Créer l'objet Attendance
                          final attendance = Attendance(
                            employeeId: widget.employeeId,
                            employeeName: _controllers["employeeName"]?.text.trim(),
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

                          // 🔹 Ajouter dans Firebase
                          final result =
                          await sl<AddAttendanceUseCase>().call(params: attendance);

                          result.fold(
                                (l) {
                              Navigator.pop(context);
                              CustomSnackBar.show(
                                context,
                                message: l.toString(),
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
                          debugPrint("Erreur onPressed: $e");
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

