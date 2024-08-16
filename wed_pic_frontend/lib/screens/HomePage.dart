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

  // Set the title font size depending on the screen size
  double _getTitleFontSize(double screenWidth) {
    if (screenWidth < 600) {
      return 48;
    } else if (screenWidth < 900) {
      return 60;
    } else {
      return 72;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'WedPics',
                style: TextStyle(
                  fontSize:
                      _getTitleFontSize(MediaQuery.of(context).size.width),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                  height: 50), // Spacing between title and input field
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Enter session ID',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 20.0),
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                        onSubmitted: (value) => _navigateToSession(),
                      ),
                    ),
                    const SizedBox(width: 10), // Space between input and button
                    ElevatedButton(
                      onPressed: _navigateToSession,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 24.0),
                      ),
                      child: const Text(
                        'Go',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
