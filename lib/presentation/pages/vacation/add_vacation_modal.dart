import 'package:app_bhb/common_widget/CustomSnackBar.dart';
import 'package:app_bhb/common_widget/generic_form_modal.dart';
import 'package:app_bhb/data/auth/models/vacation_model.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_notification.dart';
import 'package:app_bhb/domain/auth/usecases/uses_cases_vacation.dart';
import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';
import 'package:app_bhb/common_widget/round_textfield.dart';

import '../../../service_locator.dart';

class AddVacationModal extends StatefulWidget {
  final String title;
  final String submitButtonText;
  final Function(Map<String, dynamic>) onAdd;

  const AddVacationModal({
    super.key,
    required this.title,
    required this.submitButtonText,
    required this.onAdd,
  });

  @override
  State<AddVacationModal> createState() => _AddVacationModalState();
}

class _AddVacationModalState extends State<AddVacationModal> {
  final _createNotificationUseCase = sl<CreateNotificationUseCase>();

  // Pour le champ date
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _controllers["name"] = TextEditingController();
    _controllers["date"] = TextEditingController();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
      locale: const Locale("ar", "SA"),
      builder: (BuildContext context, Widget? child) {
        return Directionality(
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

  @override
  Widget build(BuildContext context) {
    final fields = <FormFieldConfig>[
      FormFieldConfig(
        key: "name",
        hint: "اسم العطلة",
        icon: const Icon(Icons.beach_access, color: Colors.grey),
        validator: (v) => (v == null || v.isEmpty) ? "الرجاء إدخال اسم العطلة" : null,
      ),
      FormFieldConfig(
        key: "date",
        hint: "تاريخ العطلة",
        icon: const Icon(Icons.calendar_today, color: Colors.grey),
        validator: (v) => (v == null || v.isEmpty) ? "الرجاء تحديد التاريخ" : null,
      ),
    ];

    return GenericFormModal(
      title: widget.title,
      fields: fields,

      extraFieldBuilders: {
        "date": (field, controller) {
          return GestureDetector(
            onTap: () => _selectDate(controller),
            child: AbsorbPointer(
              child: NewRoundTextField(
                hintText: field.hint,
                controller: controller,
                right: const Icon(Icons.calendar_today, color: Colors.grey),
              ),
            ),
          );
        },
      },

      onSubmit: (values) async {
        final newVacation = Vacation(
          id: "",
          nameVacation: values["name"].trim(),
          dateVacation: DateTime.tryParse(values["date"].trim()),
        );

        final result = await sl<AddVacationUseCase>().call(params: newVacation);

        result.fold(
              (error) {
            CustomSnackBar.show(context, message: error, type: SnackBarType.error);
          },
              (addedVac) {
            Navigator.pop(context);
            CustomSnackBar.show(
              context,
              message: "تمت إضافة العطلة بنجاح",
              type: SnackBarType.success,
            );

            widget.onAdd({
              "id": addedVac.id,
              "nameVacation": addedVac.nameVacation,
              "dateVacation": addedVac.dateVacation,
            });
          },
        );
      },
    );
  }
}


