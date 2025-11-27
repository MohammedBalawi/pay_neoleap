// import 'package:flutter/material.dart';
//
// import '../main.dart';
// import '../services/neoleap_payment_service.dart';
//
// class VipSubscribeButton extends StatelessWidget {
//   const VipSubscribeButton({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     // عدّل الـ baseUrl حسب مذكور فوق
//     final paymentService =
//     // NeoleapPaymentService('http://10.0.2.2:3000'); // Android emulator
//
//    NeoleapPaymentService('http://localhost:3000'); // iOS
//
//     return ElevatedButton(
//       onPressed: () async {
//         try {
//           // مثال: 1 ريال
//           final paymentUrl = await paymentService.createPayment(amount: 1.0);
//
//           await Navigator.of(context).push(
//             MaterialPageRoute(
//               builder: (_) => NeoleapPaymentWebView(   html:  paymentUrl,),
//             ),
//           );
//
//           // بعد ما يرجع من صفحة الدفع:
//           // هنا تقدر:
//           // 1) تنادي API عندك تسأل: هل الطلب الفلاني دفعه المستخدم؟
//           // 2) لو نعم -> تحدّث Cubit/BLoC: isVip = true
//         } catch (e) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('حدث خطأ في بدء عملية الدفع: $e'),
//             ),
//           );
//         }
//       },
//       child: const Text('اشترك VIP'),
//     );
//   }
// }
