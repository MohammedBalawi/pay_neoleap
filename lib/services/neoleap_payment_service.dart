import 'dart:convert';
import 'package:http/http.dart' as http;

class NeoleapPaymentService {
  // عدّل العنوان حسب مكان سيرفرك
  // لو على نفس الجهاز أثناء التطوير:
  // - Android Emulator: http://10.0.2.2:3000
  // - iOS Simulator: http://localhost:3000
  final String baseUrl;

  NeoleapPaymentService(this.baseUrl);

  Future<String> createPayment({
    required double amount,
  }) async {
    final uri = Uri.parse('$baseUrl/neoleap/create-payment');

    final response = await http.post(
      uri,
      headers: {
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
      throw Exception('Payment URL not found in response');
    }

    return url;
  }
}
