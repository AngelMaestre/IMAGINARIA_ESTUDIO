import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'theme.dart';
import 'services/push_service.dart';
import 'screens/home_screen.dart';

// Importa firebase_options solo si existe
// Si no tienes este archivo, comenta la línea siguiente
import 'firebase_options.dart';

// Clave global de navegación para notificaciones/deep links
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicializa Firebase con las opciones por plataforma
    await Firebase.initializeApp(
      // Si no tienes firebase_options.dart, comenta la línea siguiente
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Inicializa el servicio de notificaciones push
    await PushService.init();
  } catch (e) {
    print('Error inicializando Firebase: $e');
    // La app puede continuar sin Firebase si es necesario
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Imaginaria',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
