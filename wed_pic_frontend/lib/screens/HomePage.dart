import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/services/BackendService.dart';
import 'package:wed_pic_frontend/services/BackendSettings.dart';
import 'package:wed_pic_frontend/services/IClientService.dart';

class HomePage extends StatefulWidget {
  static const String route = '/';

  IClientService client = BackendService(BackendConstants().apiUrl);

  HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();

  void _navigateToSession() {
    if (_controller.text.isNotEmpty) {
      final sessionId = _controller.text;
      Navigator.pushNamed(context, '/session/$sessionId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'WedPics',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Input a session ID',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24),
                onSubmitted: (value) => _navigateToSession(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _navigateToSession,
                child: const Text(
                  'Go to Session',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
