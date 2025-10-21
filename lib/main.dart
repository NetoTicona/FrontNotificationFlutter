import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Solicitar permisos al inicio
  await _requestPermissions();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DatabaseService()),
        Provider(create: (_) => StorageService()), // Simple provider, not ChangeNotifier
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _requestPermissions() async {
  // Solicitar permisos de cámara, audio y almacenamiento
  Map<Permission, PermissionStatus> statuses = await [
    Permission.camera,
    Permission.microphone, // Agregado permiso de micrófono
    Permission.storage,
    Permission.manageExternalStorage,
  ].request();

  // Verificar si los permisos fueron concedidos
  if (statuses[Permission.camera] != PermissionStatus.granted) {
    print('Permiso de cámara denegado');
  }

  if (statuses[Permission.microphone] != PermissionStatus.granted) {
    print('Permiso de micrófono denegado');
  }

  if (statuses[Permission.storage] != PermissionStatus.granted) {
    print('Permiso de almacenamiento denegado');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}