import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);

            // لو حاب تراقب success/error:
            // if (url.contains('/neoleap/success')) { ... }
            // if (url.contains('/neoleap/error')) { ... }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إتمام الدفع'),
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
