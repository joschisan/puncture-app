import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

class NotificationUtils {
  static void _showNotification(
    String message,
    Color textColor,
    Duration duration,
  ) {
    showSimpleNotification(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      background: Colors.transparent,
      duration: duration,
      slideDismissDirection: DismissDirection.up,
      context: null,
    );
  }

  static void showSuccess(String message) {
    _showNotification(
      message,
      Colors.green.shade200,
      const Duration(seconds: 3),
    );
  }

  static void showError(String message) {
    _showNotification(message, Colors.red.shade200, const Duration(seconds: 3));
  }

  static void showInfo(String message) {
    _showNotification(
      message,
      Colors.deepPurple.shade200,
      const Duration(seconds: 2),
    );
  }
}
