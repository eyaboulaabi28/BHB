import 'package:app_bhb/common/color_extension.dart';
import 'package:flutter/material.dart';

class RoundTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final double radius;
  final bool obscureText;
  final Widget? right;
  final bool isPadding;

  const RoundTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.keyboardType,
    this.radius = 25,
    this.obscureText = false,
    this.right,
    this.isPadding = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: EdgeInsets.symmetric(horizontal: isPadding ? 20 : 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: TColor.placeholder.withOpacity(0.5), width: 0.5),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Directionality( // ✅ Force la direction à droite
        textDirection: TextDirection.rtl,
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          textAlign: TextAlign.right, // ✅ Texte aligné à droite
          obscureText: obscureText,
          style: TextStyle(color: TColor.primaryText, fontSize: 17),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: hintText,
            suffixIcon: right,
            hintStyle: TextStyle(color: TColor.placeholder, fontSize: 17),
            alignLabelWithHint: true,
          ),
        ),
      ),
    );
  }
}

class NewRoundTextField extends StatelessWidget {
  final String? initialValue;
  final String hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? right;
  final bool isPadding;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool readOnly;
  final void Function(String)? onChanged;
  final int minLines;
  final VoidCallback? onTap;

  const NewRoundTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.right,
    this.isPadding = true,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.onChanged,
    this.minLines = 1,
    this.onTap,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: validator,
      key:key,
      initialValue: initialValue,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (state) {
        final bool hasError = state.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: maxLines > 1 ? null : 60,
              margin: EdgeInsets.symmetric(horizontal: isPadding ? 20 : 0),
              decoration: BoxDecoration(
                color: readOnly ? Colors.grey.shade200 : Colors.white,
                // 🔥 ICI : BORDER PASSE EN ROUGE SI ERREUR
                border: Border.all(
                  color: hasError ? Colors.red : Colors.black12,
                  width: 1.5,
                ),

                borderRadius: BorderRadius.circular(30),
                boxShadow: readOnly
                    ? null
                    : const [BoxShadow(color: Colors.black12, blurRadius: 2)],
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textAlign: TextAlign.right,
                  obscureText: obscureText,
                  readOnly: readOnly,
                  minLines: minLines,
                  maxLines: maxLines,
                  onTap: onTap,
                  onChanged: (value) {
                    onChanged?.call(value);
                    state.didChange(value);
                  },
                  decoration: InputDecoration(
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),

                    // Supprimer erreurs Flutter (ligne rouge)
                    border: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,

                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: readOnly
                          ? Colors.grey.shade500
                          : Colors.grey.shade400,
                      fontSize: 17,
                    ),
                    suffixIcon: right,
                  ),
                ),
              ),
            ),

            // 🔥 Message d’erreur propre sous le champ (optionnel)
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




