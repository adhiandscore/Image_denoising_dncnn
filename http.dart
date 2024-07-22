// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// void main() => runApp(MyApp());

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: Text('Flutter & Docker ML Integration'),
//         ),
//         body: Center(
//           child: FutureBuilder(
//             future: fetchData(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return CircularProgressIndicator();
//               } else if (snapshot.hasError) {
//                 return Text('Error: ${snapshot.error}');
//               } else {
//                 return Text('Prediction: ${snapshot.data}');
//               }
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Future<String> fetchData() async {
//     final response = await http.post(
//       Uri.parse(
//           'http://localhost:5000/predict'), // Adjust with Docker container IP if needed
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'input': [1.0, 2.0, 3.0]
//       }), // Example input
//     );

//     if (response.statusCode == 200) {
//       Map<String, dynamic> data = jsonDecode(response.body);
//       return data['output'].toString();
//     } else {
//       throw Exception('Failed to load prediction');
//     }
//   }
// }
