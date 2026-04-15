
import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:flutter/material.dart';


class EditWorkHoursModal extends StatefulWidget {
  final String start;
  final String end;
  final Function(String start, String end) onSave;

  const EditWorkHoursModal({
    super.key,
    required this.start,
    required this.end,
    required this.onSave,
  });

  @override
  State<EditWorkHoursModal> createState() => _EditWorkHoursModalState();
}

class _EditWorkHoursModalState extends State<EditWorkHoursModal> {
  late TextEditingController startCtrl;
  late TextEditingController endCtrl;

  @override
  void initState() {
    super.initState();
    startCtrl = TextEditingController(text: widget.start);
    endCtrl = TextEditingController(text: widget.end);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("تعديل أوقات الدوام"),

          const SizedBox(height: 15),

          NewRoundTextField(
            hintText: "بداية الدوام",
            controller: startCtrl,
            right: const Icon(Icons.login),
          ),

          const SizedBox(height: 10),

          NewRoundTextField(
            hintText: "نهاية الدوام",
            controller: endCtrl,
            right: const Icon(Icons.logout),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              widget.onSave(
                startCtrl.text,
                endCtrl.text,
              );
              Navigator.pop(context);
            },
            child: const Text("حفظ"),
          )
        ],
      ),
    );
  }
}