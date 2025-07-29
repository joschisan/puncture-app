import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:overlay_support/overlay_support.dart';

class NotificationUtils {
  static void _showNotification(
    String message,
    IconData icon,
    Color textColor,
    Duration duration,
  ) {
    showOverlayNotification(
      (context) => SafeArea(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(icon, color: textColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
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
          ),
        ),
      ),
      duration: duration,
      position: NotificationPosition.top,
    );
  }

  static void showError(String message) {
    _showNotification(
      message,
      Icons.error,
      Colors.red.shade200,
      const Duration(seconds: 3),
    );
  }

  static void showCopy(String message) {
    _showNotification(
      message,
      Icons.copy,
      Colors.deepPurple.shade200,
      const Duration(seconds: 2),
    );
  }

  static void showReceive(int amountSat) {
    HapticFeedback.mediumImpact();
    
    _showNotification(
      'You received ${NumberFormat('#,###').format(amountSat)} sats!',
      Icons.bolt,
      Colors.deepPurple.shade200,
      const Duration(seconds: 3),
    );
  }
}
