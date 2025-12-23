import 'package:flutter/material.dart';
import 'package:app_bhb/common/color_extension.dart';

enum DialogType { info, warning, error, success, confirm }

class CustomDialog {
  /// Affiche un dialog moderne
  static Future<bool?> show(
      BuildContext context, {
        required String title,
        required String message,
        DialogType type = DialogType.info,
        String confirmText = "تأكيد",
        String cancelText = "إلغاء",
        bool showCancel = true,
      }) {
    Color iconColor;
    IconData icon;

    switch (type) {
      case DialogType.success:
        iconColor = Colors.green.shade600;
        icon = Icons.check_circle_outline;
        break;
      case DialogType.error:
        iconColor = Colors.red.shade600;
        icon = Icons.error_outline;
        break;
      case DialogType.warning:
        iconColor = Colors.orange.shade700;
        icon = Icons.warning_amber_rounded;
        break;
      case DialogType.confirm:
        iconColor = TColor.primary;
        icon = Icons.help_outline;
        break;
      case DialogType.info:
      default:
        iconColor = Colors.blue.shade600;
        icon = Icons.info_outline;
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl, // ← important pour l’arabe
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        content: Directionality(
          textDirection: TextDirection.rtl, // ← pour le texte arabe du contenu
          child: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actions: [
          if (showCancel)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: TColor.secondary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "إلغاء",
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              ),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TColor.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),

    );
  }
}
