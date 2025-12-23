import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';

class NewRoundSelectField extends StatefulWidget {
  final String hintText;
  final List<String> options;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool isPadding;
  final Widget? rightIcon;
  final IconData? icon;
  final bool readOnly;
  final void Function(String?)? onChanged;

  const NewRoundSelectField({
    super.key,
    required this.hintText,
    required this.options,
    this.controller,
    this.validator,
    this.isPadding = true,
    this.rightIcon,
    this.icon,
    this.readOnly = false,
    this.onChanged,
  });

  @override
  State<NewRoundSelectField> createState() => _NewRoundSelectFieldState();
}

class _NewRoundSelectFieldState extends State<NewRoundSelectField> {
  String? _selectedValue;
  late VoidCallback _controllerListener;

  bool _isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  @override
  void initState() {
    super.initState();

    if (widget.controller != null && widget.controller!.text.isNotEmpty) {
      if (widget.options.contains(widget.controller!.text)) {
        _selectedValue = widget.controller!.text;
      }
    }

    _controllerListener = () {
      final text = widget.controller!.text;
      if (text.isNotEmpty && widget.options.contains(text)) {
        if (_selectedValue != text) {
          setState(() {
            _selectedValue = text;
          });
        }
      }
    };

    widget.controller?.addListener(_controllerListener);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_controllerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isHintArabic = _isArabic(widget.hintText);

    final backgroundColor = widget.readOnly ? Colors.grey.shade200 : Colors.white;
    final borderColor = widget.readOnly ? Colors.grey.shade400 : Colors.black12;

    return FormField<String>(
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (state) {
        final bool hasError = state.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              margin: EdgeInsets.symmetric(horizontal: widget.isPadding ? 20 : 0),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: hasError ? Colors.red : borderColor),
                boxShadow: widget.readOnly ? null : const [BoxShadow(color: Colors.black12, blurRadius: 2)],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedValue,
                  hint: Directionality(
                    textDirection: isHintArabic ? TextDirection.rtl : TextDirection.ltr,
                    child: Align(
                      alignment: isHintArabic ? Alignment.centerRight : Alignment.centerLeft,
                      child: Text(
                        widget.hintText,
                        style: TextStyle(
                          color: widget.readOnly ? Colors.grey.shade500 : Colors.black54,
                          fontSize: 17,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                  ),
                  items: widget.options.map((option) {
                    final bool isArabic = _isArabic(option);
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Directionality(
                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                        child: Align(
                          alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                          child: Text(
                            option,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              color: widget.readOnly ? Colors.grey.shade700 : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: widget.readOnly
                      ? null
                      : (value) {
                    setState(() {
                      _selectedValue = value;
                      widget.controller?.text = value ?? '';
                    });
                    state.didChange(value); // 🔥 notifier le FormField
                    if (widget.onChanged != null) {
                      widget.onChanged!(value);
                    }
                  },
                  icon: Padding(
                    padding: const EdgeInsets.only(left:0),
                    child: Icon(
                      widget.rightIcon != null ? (widget.rightIcon as Icon).icon : Icons.arrow_drop_down,
                      color: widget.readOnly ? Colors.grey.shade500 : Colors.grey,
                    ),
                  ),
                ),

              ),
            ),

            // 🔥 Message d’erreur sous le champ
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(right: 25, top: 4),
                child: Text(
                  state.errorText!,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

}


