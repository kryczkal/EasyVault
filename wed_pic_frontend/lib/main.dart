import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wed_pic_frontend/screens/HomePage.dart';
import 'package:wed_pic_frontend/screens/SessionPage.dart';
import 'package:wed_pic_frontend/services/ApiSettings.dart';
import 'package:wed_pic_frontend/services/ApiClient.dart';
import 'package:wed_pic_frontend/services/IApiClient.dart';
import 'package:wed_pic_frontend/states/SessionManager.dart';

void main() {
  String bucketId = '413080d0c8851bf75327ec72a76388d9078f7cfd';
  IApiClient client = ApiClient(ApiSettings.apiUrl);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SessionManager()),
      ],
      child: MaterialApp(
        title: 'WedPics',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
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
            return MaterialPageRoute(
                builder: (context) => SessionPage(
                      sessionId: sessionId,
                      client: client,
                    ));
          }
          return null;
        },
      ),
    ),
  );
}
