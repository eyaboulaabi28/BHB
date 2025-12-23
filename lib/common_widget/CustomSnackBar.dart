import 'package:flutter/material.dart';

enum SnackBarType { success, error, warning, info, loading }

class CustomSnackBar {
  static void show(
      BuildContext context, {
        required String message,
        bool textAlignRight = false,
        required SnackBarType type,
        Duration duration = const Duration(seconds: 5),
      }) {
    String emoji;
    Color backgroundColor;

    switch (type) {
      case SnackBarType.success:
        emoji = "✅";
        backgroundColor = Colors.green.shade600;
        break;
      case SnackBarType.error:
        emoji = "❌";
        backgroundColor = Colors.red.shade600;
        break;
      case SnackBarType.warning:
        emoji = "⚠️";
        backgroundColor = Colors.orange.shade700;
        break;
      case SnackBarType.info:
        emoji = "ℹ️";
        backgroundColor = Colors.blue.shade600;
        break;
      case SnackBarType.loading:
        emoji = "⏳";
        backgroundColor = Colors.blueGrey.shade700;
        break;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 8,
      backgroundColor: Colors.transparent,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                textAlign: textAlignRight ? TextAlign.right : TextAlign.left,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (type == SnackBarType.loading)
              const Padding(
                padding: EdgeInsets.only(left: 10),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
      duration: duration,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    );

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(snackBar);
  }
}
