import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

/// تطبيق بسيط فيه زر واحد لبدء عملية الدفع
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neoleap Payment Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const PaymentHomePage(),
    );
  }
}

/// الصفحة الرئيسية فيها زر "اشترك VIP"
class PaymentHomePage extends StatefulWidget {
  const PaymentHomePage({super.key});

  @override
  State<PaymentHomePage> createState() => _PaymentHomePageState();
}

class _PaymentHomePageState extends State<PaymentHomePage> {
  bool _isLoading = false;

  // على iOS Simulator:
  final String _baseUrl = 'http://localhost:3000';
  // على Android Emulator استخدم بدل السطر فوق:
  // final String _baseUrl = 'http://10.0.2.2:3000';

  /// يستدعي السيرفر ويرجع رابط صفحة الدفع (redirectUrl من Neoleap)
  Future<String> _createPayment({required double amount}) async {
    final uri = Uri.parse('$_baseUrl/neoleap/create-payment');

    final response = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': amount,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error creating payment: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = data['url'] as String?;

    if (url == null || url.isEmpty) {
      throw Exception('Payment URL not found or invalid format: $data');
    }

    debugPrint('Neoleap payment URL: $url');
    return url;
  }

  Future<void> _startPayment() async {
    setState(() => _isLoading = true);

    try {
      // مبلغ الاشتراك (1 ريال كمثال)
      final paymentUrl = await _createPayment(amount: 1.0);

      if (!mounted) return;

      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => NeoleapPaymentWebView(paymentUrl: paymentUrl),
        ),
      );

      if (!mounted) return;

      if (result == true) {
        // ✅ اعتبر المستخدم صار VIP هنا
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الدفع بنجاح ✅')),
        );
        // TODO: عدّل حالة المستخدم لـ VIP (SharedPrefs / Cubit / API إلخ)
      } else if (result == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشلت عملية الدفع ❌')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في بدء عملية الدفع: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بوابة الدفع - Neoleap'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
          onPressed: _startPayment,
          child: const Text('اشترك VIP (1 ريال)'),
        ),
      ),
    );
  }
}

/// شاشة WebView لعرض صفحة الدفع (Bank Hosted)
class NeoleapPaymentWebView extends StatefulWidget {
  final String paymentUrl;

  const NeoleapPaymentWebView({
    super.key,
    required this.paymentUrl,
  });

  @override
  State<NeoleapPaymentWebView> createState() => _NeoleapPaymentWebViewState();
}

class _NeoleapPaymentWebViewState extends State<NeoleapPaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  /// نفس الروابط اللي في ملف .env في السيرفر:
  /// SUCCESS_URL=http://localhost:3000/neoleap/success
  /// ERROR_URL=http://localhost:3000/neoleap/error
  final String successUrlPrefix = 'http://localhost:3000/neoleap/success';
  final String errorUrlPrefix = 'http://localhost:3000/neoleap/error';

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          // نستخدم onNavigationRequest عشان نمنع فتح صفحة النجاح/الفشل
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            debugPrint('WEBVIEW navigating to: $url');

            // ✅ نجاح الدفع
            if (url.startsWith(successUrlPrefix)) {
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent; // ما نفتح الصفحة
            }

            // ❌ فشل الدفع
            if (url.startsWith(errorUrlPrefix)) {
              Navigator.of(context).pop(false);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إتمام عملية الدفع'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
