import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/responsive_layout.dart';

class QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color? foregroundColor;
  final Color? backgroundColor;

  const QrCodeWidget({
    Key? key,
    required this.data,
    this.size = 200,
    this.foregroundColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size,
        foregroundColor: foregroundColor ?? Colors.black,
        backgroundColor: backgroundColor ?? Colors.white,
        errorStateBuilder: (context, error) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[400],
                  size: 32,
                ),
                const SizedBox(height: 8),
                ResponsiveText(
                  'ไม่สามารถสร้าง QR Code ได้',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
