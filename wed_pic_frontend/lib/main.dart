import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easyvault/screens/home_page.dart';
import 'package:easyvault/screens/session_page.dart';
import 'package:easyvault/services/api_settings.dart';
import 'package:easyvault/states/session_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SessionManager()),
      ],
      child: MaterialApp(
        title: 'EasyVault',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('pl', 'PL'),
        ],
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
