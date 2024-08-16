import 'package:flutter/material.dart';
import 'package:wed_pic_frontend/screens/HomePage.dart';
import 'package:wed_pic_frontend/screens/SessionPage.dart';
import 'package:wed_pic_frontend/services/BackendSettings.dart';
import 'package:wed_pic_frontend/services/BackendService.dart';
import 'package:wed_pic_frontend/services/IClientService.dart';

void main() {
  String bucketId = '413080d0c8851bf75327ec72a76388d9078f7cfd';
  IClientService client = BackendService(BackendConstants().apiUrl);

  runApp(MaterialApp(
    title: 'WedPics',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    // Define routes
    initialRoute: HomePage.route,
    routes: {
      HomePage.route: (context) => HomePage(),
      SessionPage.route: (context) => SessionPage(
            client: client,
            sessionId: bucketId,
          ),
    },
    onGenerateRoute: (settings) {
      if (settings.name!.startsWith('/session/')) {
        final sessionId = settings.name!.replaceFirst('/session/', '');
        print('Running session/$sessionId');
        return MaterialPageRoute(
            builder: (context) => SessionPage(
                  sessionId: sessionId,
                  client: client,
                ));
      }
      return null;
    },
  ));
}
