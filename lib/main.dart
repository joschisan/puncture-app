import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:path_provider/path_provider.dart';
import 'screens/base_screen.dart';
import 'bridge_generated.dart/frb_generated.dart';
import 'bridge_generated.dart/lib.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RustLib.init();

  final dir = await getApplicationDocumentsDirectory();

  final punctureClient = await PunctureClientWrapper.newInstance(
    dataDir: dir.path,
  );

  runApp(MyApp(punctureClient: punctureClient));
}

class MyApp extends StatelessWidget {
  final PunctureClientWrapper punctureClient;

  const MyApp({super.key, required this.punctureClient});

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        title: 'Puncture App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.dark,
        home: BaseScreen(punctureClient: punctureClient),
      ),
    );
  }
}
