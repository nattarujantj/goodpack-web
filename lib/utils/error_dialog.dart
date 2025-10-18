import 'package:flutter/material.dart';

class ErrorDialog {
  static void show(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  static void showNetworkError(BuildContext context) {
    show(
      context,
      'เกิดข้อผิดพลาด',
      'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้\nกรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ตและลองใหม่อีกครั้ง',
    );
  }

  static void showServerError(BuildContext context, String errorMessage) {
    show(
      context,
      'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์',
      errorMessage,
    );
  }

  static void showValidationError(BuildContext context, String errorMessage) {
    show(
      context,
      'ข้อมูลไม่ถูกต้อง',
      errorMessage,
    );
  }
}
