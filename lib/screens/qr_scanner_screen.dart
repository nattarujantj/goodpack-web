import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../widgets/responsive_layout.dart';
import 'product_detail_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController? controller;
  bool _isScanning = true;
  String _lastScannedCode = '';

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    // Load products if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      if (provider.allProducts.isEmpty) {
        provider.loadProducts();
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: 'สแกน QR Code',
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleScanning,
            tooltip: _isScanning ? 'หยุดสแกน' : 'เริ่มสแกน',
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanner View
          Expanded(
            flex: 3,
            child: _buildScannerView(),
          ),
          
          // Instructions
          Expanded(
            flex: 1,
            child: _buildInstructions(),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: MobileScanner(
          controller: controller!,
          onDetect: _onDetect,
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          ResponsiveText(
            'สแกน QR Code ของสินค้า',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ResponsiveText(
            'วาง QR Code ไว้ในกรอบสี่เหลี่ยมเพื่อสแกน',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (!_isScanning)
            ElevatedButton.icon(
              onPressed: _toggleScanning,
              icon: const Icon(Icons.play_arrow),
              label: const Text('เริ่มสแกน'),
            ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code != _lastScannedCode) {
        _lastScannedCode = code;
        _handleScannedCode(code);
      }
    }
  }

  void _handleScannedCode(String code) {
    // Stop scanning temporarily
    setState(() {
      _isScanning = false;
    });

    // Parse the QR code data
    final productId = _extractProductIdFromQrCode(code);
    
    if (productId != null) {
      _navigateToProduct(productId);
    } else {
      _showInvalidQrCodeDialog(code);
    }
  }

  String? _extractProductIdFromQrCode(String qrCode) {
    // Expected format: goodpack://product/{productId}
    if (qrCode.startsWith('goodpack://product/')) {
      return qrCode.substring('goodpack://product/'.length);
    }
    
    // If it's just a product ID, return it directly
    if (qrCode.isNotEmpty && qrCode.length > 10) {
      return qrCode;
    }
    
    return null;
  }

  void _navigateToProduct(String productId) {
    final product = context.read<ProductProvider>().getProductById(productId);
    
    if (product != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(productId: productId),
        ),
      ).then((_) {
        // Resume scanning when returning from product detail
        setState(() {
          _isScanning = true;
          _lastScannedCode = '';
        });
      });
    } else {
      _showProductNotFoundDialog(productId);
    }
  }

  void _showInvalidQrCodeDialog(String code) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('QR Code ไม่ถูกต้อง'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('QR Code ที่สแกนไม่ใช่ของสินค้าในระบบ'),
              const SizedBox(height: 8),
              Text(
                'รหัสที่สแกน: $code',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isScanning = true;
                  _lastScannedCode = '';
                });
              },
              child: const Text('ลองใหม่'),
            ),
          ],
        );
      },
    );
  }

  void _showProductNotFoundDialog(String productId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ไม่พบสินค้า'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ไม่พบสินค้าที่มีรหัสนี้ในระบบ'),
              const SizedBox(height: 8),
              Text(
                'รหัสสินค้า: $productId',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isScanning = true;
                  _lastScannedCode = '';
                });
              },
              child: const Text('ลองใหม่'),
            ),
          ],
        );
      },
    );
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
      if (_isScanning) {
        _lastScannedCode = '';
      }
    });
  }
}
