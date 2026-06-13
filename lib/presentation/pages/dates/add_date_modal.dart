import 'package:app_bhb/data/auth/models/date_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_date.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/NewRoundSelectField.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:app_bhb/data/auth/models/customers_model.dart';
import 'package:app_bhb/data/auth/models/notifications_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_customers.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../service_locator.dart';

class FormFieldConfig {
  final String key;
  final String hint;
  final Widget? icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<String>? options;

  FormFieldConfig({
    required this.key,
    required this.hint,
    this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.options,
  });
}

class AddDateModal extends StatefulWidget {
  final Function(Map<String, dynamic> values) onAdd;
  final String title;
  final String submitButtonText;
  const AddDateModal({
    super.key,
    required this.onAdd,
    this.title = "إضافة موعد جديد",
    this.submitButtonText = "إضافة",
  });
  @override
  State<AddDateModal> createState() => _AddDateModalState();
}

class _AddDateModalState extends State<AddDateModal> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  List<Customers> customers = [];
  String? selectedCustomerId;
  late String? currentUserId;

  late final List<FormFieldConfig> fields;
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, bool> _obscureMap;

  final TextEditingController customerCtrl = TextEditingController();
  late final CreateNotificationUseCase _createNotificationUseCase;
  // Controller
  final TextEditingController dateCtrl = TextEditingController();
  DateTime? selectedDate;
  DateStatus selectedStatus = DateStatus.pending;
  final TextEditingController statusCtrl = TextEditingController();
  final TextEditingController typeCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();
    _createNotificationUseCase = sl<CreateNotificationUseCase>();
    _loadCustomers();
    statusCtrl.text = statusToText(selectedStatus);
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    fields = [
      FormFieldConfig(
        key: "date",
        hint: "تاريخ الموعد",
        icon: const Icon(Icons.date_range_outlined, color: Colors.grey),
        validator: (v) => (v == null || v.isEmpty) ? "الرجاء إدخال تاريخ الموعد" : null,
      ),
    ];
    _controllers = {for (var f in fields) f.key: TextEditingController()};
    _obscureMap = {for (var f in fields) f.key: f.isPassword};
  }
  DateStatus textToStatus(String text) {
    switch (text) {
      case "قيد الانتظار":
        return DateStatus.pending;
      case "مؤكد":
        return DateStatus.confirmed;
      case "منجز":
        return DateStatus.completed;
      case "ملغى":
        return DateStatus.cancelled;
      case "متأخر":
        return DateStatus.late;
      default:
        return DateStatus.pending;
    }
  }

  Future<void> _sendNotification({
    required String title,
    required String message,
    String? userId,
    String? route,
  }) async {
    final notif = NotificationsModel(
      title: title,
      message: message,
      userId: userId,
      route: route,
      createdAt: DateTime.now(),
      isRead: false,
    );
    await _createNotificationUseCase(notification: notif);
  }

  // ========== LOAD DATA ==========

  Future<void> _loadCustomers() async {
    final result = await sl<GetCustomerUseCase>().call();
    result.fold(
          (e) => debugPrint("Error customers"),
          (list) => setState(() => customers = List<Customers>.from(list)),
    );
  }

  String statusToText(DateStatus status) {
    switch (status) {
      case DateStatus.pending:
        return "قيد الانتظار";
      case DateStatus.confirmed:
        return "مؤكد";
      case DateStatus.completed:
        return "منجز";
      case DateStatus.cancelled:
        return "ملغى";
      case DateStatus.late:
        return "متأخر";

    }
  }

  // ========== BUILD ==========
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          constraints: const BoxConstraints(minHeight: 700),
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.title, style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 20),

                  // Select engineer / customer / employee
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child:
                      NewRoundSelectField(
                        hintText: "اختيار العميل",
                        enableSearch:true,
                        options: customers.map((c) => c.firstName ?? "").toList(),
                        controller: customerCtrl,
                        rightIcon: const Icon(Icons.person),
                        onChanged: (value) {
                          final customer = customers.firstWhere((c) => c.firstName == value);
                          selectedCustomerId = customer.id;
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: NewRoundTextField(
                      hintText: "تاريخ الموعد",
                      controller: _controllers["date"],
                      readOnly: true,
                      right: const Icon(Icons.date_range_outlined, color: Colors.grey),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          locale: const Locale('ar', 'AE'),
                          builder: (context, child) {
                            return Directionality(
                              textDirection: TextDirection.rtl,
                              child: child!,
                            );
                          },
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                            _controllers["date"]!.text =
                            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2,'0')}-${pickedDate.day.toString().padLeft(2,'0')}";
                          });
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: NewRoundSelectField(
                      hintText: "حالة الموعد",
                      controller: statusCtrl,
                      enableSearch: false,
                      rightIcon: const Icon(Icons.flag_outlined),
                      options: DateStatus.values
                          .map((e) => statusToText(e))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedStatus = textToStatus(value);
                        });
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: NewRoundSelectField(
                      hintText: "نوع الموعد",
                      controller: typeCtrl,
                      enableSearch: false,
                      rightIcon: const Icon(Icons.flag_outlined),
                      options: const [
                        "كهرباء",
                        "سباكة",
                      ],
                      onChanged: (String? value) {
                        if (value == null || value.isEmpty) return;

                        setState(() {
                          selectedStatus = textToStatus(value.trim());
                        });
                      },
                    ),
                  ),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: TColor.secondary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          child: Text(
                            "إلغاء",
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: TColor.secondary,
                            ),
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
                            if (!_formKey.currentState!.validate()) return;

                            setState(() => _isSubmitting = true);

                            try {
                              final date = Date(
                                customerName: customerCtrl.text.trim(),
                                uidCustomer: selectedCustomerId,
                                createdAt: selectedDate,
                                status: selectedStatus,
                                typeDate: typeCtrl.text.trim(),
                              );


                              final result = await sl<AddDateUseCase>()
                                  .call(params: date);

                              result.fold(
                                    (failure) {
                                  CustomSnackBar.show(
                                    context,
                                    message: failure.toString(),
                                    type: SnackBarType.error,
                                  );
                                },
                                    (docId) {
                                  CustomSnackBar.show(
                                    context,
                                    message: "تمت إضافة الموعد بنجاح",
                                    type: SnackBarType.success,
                                  );

                                  _sendNotification(
                                    title: "موعد جديد",
                                    message:
                                    "تم إضافة موعد جديد مع العميل: ${customerCtrl.text.trim()}",
                                    userId: currentUserId,
                                    route: "/home",
                                  );

                                  widget.onAdd({
                                    "customerName": customerCtrl.text.trim(),
                                    "uidCustomer": selectedCustomerId,
                                    "typeDate": typeCtrl.text.trim(),
                                    "createdAt":
                                    selectedDate ?? DateTime.now(),
                                  });

                                  Navigator.pop(context);
                                },
                              );
                            } catch (e) {
                              CustomSnackBar.show(
                                context,
                                message: "حدث خطأ غير متوقع",
                                type: SnackBarType.error,
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _isSubmitting = false);
                              }
                            }
                          },
                          child: _isSubmitting
                              ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Text(
                            widget.submitButtonText,
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}