import 'package:flutter/material.dart';

import 'package:polar_variety_sense_example/behavior/no_glow_on_scroll_behavior.dart';
import 'package:polar_variety_sense_example/pages/example.dart';
import 'package:polar_variety_sense_example/pages/polar_list_page.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Providing a restorationScopeId allows the Navigator built by the
      // MaterialApp to restore the navigation stack when a user leaves and
      // returns to the app after it has been killed while running in the
      // background.
      restorationScopeId: 'app',

      debugShowCheckedModeBanner: false,
      // Provide the generated AppLocalizations to the MaterialApp. This
      // allows descendant Widgets to display the correct translations
      // depending on the user's locale.
      supportedLocales: const [
        Locale('en', ''), // English, no country code
      ],

      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: Colors.amber,
        appBarTheme: const AppBarTheme(
          color: Colors.white,
          elevation: 0,
        ),
      ),

      home: const Example(),
      // Define a function to handle named routes in order to support
      // Flutter web url navigation and deep linking.
      onGenerateRoute: (RouteSettings routeSettings) {
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (BuildContext context) {
            switch (routeSettings.name) {
              case PolarListPage.routeName:
                return const PolarListPage();
              default:
                return const PolarListPage();
            }
          },
        );
      },
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: NoGlowOnScrollBehavior(),
          child: child!,
        );
      },
    );
  }
}
