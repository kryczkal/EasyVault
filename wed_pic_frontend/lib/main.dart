import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wed_pic_frontend/screens/home_page.dart';
import 'package:wed_pic_frontend/screens/session_page.dart';
import 'package:wed_pic_frontend/services/api_settings.dart';
import 'package:wed_pic_frontend/states/session_manager.dart';

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
          HomePage.route: (context) => const HomePage(),
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
