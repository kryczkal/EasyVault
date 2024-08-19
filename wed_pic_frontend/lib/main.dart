import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wed_pic_frontend/screens/HomePage.dart';
import 'package:wed_pic_frontend/screens/SessionPage.dart';
import 'package:wed_pic_frontend/services/ApiSettings.dart';
import 'package:wed_pic_frontend/services/ApiClient.dart';
import 'package:wed_pic_frontend/services/IApiClient.dart';
import 'package:wed_pic_frontend/states/SessionManager.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SessionManager()),
      ],
      child: MaterialApp(
        title: 'ShareVault',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: HomePage.route,
        routes: {
          HomePage.route: (context) => HomePage(),
        },
        onGenerateRoute: (settings) {
          if (settings.name!.startsWith('/session/')) {
            final sessionId = settings.name!.replaceFirst('/session/', '');
            return MaterialPageRoute(
                builder: (context) => SessionPage(
                      sessionId: sessionId,
                      client: ApiSettings.client,
                    ));
          }
          return null;
        },
      ),
    ),
  );
}
