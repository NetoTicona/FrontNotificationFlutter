import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:async';
import 'dart:io';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import 'video_iist_screen.dart';

class VideoRecordingScreen extends StatefulWidget {
  final Map<String, dynamic> config;

  const VideoRecordingScreen({
    super.key,
    required this.config,
  });

  @override
  State<VideoRecordingScreen> createState() => _VideoRecordingScreenState();
}

class _VideoRecordingScreenState extends State<VideoRecordingScreen> {
  CameraController? _controller;
  bool _isRecording = false;
  bool _isInitialized = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  String? _videoPath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Obtener las cámaras disponibles
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        _showError('No se encontraron cámaras disponibles');
        return;
      }

      // Buscar la cámara posterior
      CameraDescription? rearCamera;
      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          rearCamera = camera;
          break;
        }
      }

      // Si no hay cámara posterior, usar la primera disponible
      final selectedCamera = rearCamera ?? cameras.first;

      // Inicializar el controlador
      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: true, // CAMBIADO: Ahora habilitamos audio
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Iniciar grabación automáticamente después de inicializar
        _startRecording();
      }
    } catch (e) {
      _showError('Error al inicializar la cámara: $e');
    }
  }

  Future<void> _startRecording() async {
    if (!_isInitialized || _controller == null) return;

    try {
      // Crear directorio Documents si no existe
      final directory = await getApplicationDocumentsDirectory();
      final documentsDir = Directory('${directory.path}/Videos');
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }

      // Generar nombre del archivo con fecha y milisegundos
      final now = DateTime.now();
      final fileName = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}_${now.millisecond.toString().padLeft(3, '0')}.mp4';
      _videoPath = path.join(documentsDir.path, fileName);

      // Iniciar grabación
      await _controller!.startVideoRecording();

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
      });

      // Enviar notificación al backend
      _sendNotificationToBackend();

      // Iniciar timer para contar duración
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });
      });

      // Configurar duración automática
      final videoDuration = int.tryParse(widget.config['videoDuration'] ?? '30') ?? 30;
      Timer(Duration(seconds: videoDuration), () {
        if (_isRecording) {
          _stopRecording();
        }
      });

    } catch (e) {
      _showError('Error al iniciar grabación: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _controller == null) return;

    try {
      final videoFile = await _controller!.stopVideoRecording();

      // Mover el archivo al directorio Documents con el nombre correcto
      if (_videoPath != null) {
        await videoFile.saveTo(_videoPath!);
      }

      _recordingTimer?.cancel();

      setState(() {
        _isRecording = false;
      });

      // Navegar a la lista de videos después de un breve delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const VideoListScreen(),
            ),
          );
        }
      });

    } catch (e) {
      _showError('Error al detener grabación: $e');
    }
  }

  void _sendNotificationToBackend() {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    if (widget.config['usersSequences'] != null &&
        (widget.config['usersSequences'] as List).isNotEmpty) {

      final req = {
        'date': DateTime.now().toString(),
        'cicles': widget.config['cycles'] ?? '',
        'transitionTime': widget.config['transitionTime'] ?? '',
        'usersSequences': widget.config['usersSequences'],
      };

      print("envioTest: $req");

      databaseService.sendNotificationsData(req).then((rpta) {
        if (rpta['code'] == "OK") {
          final stats = rpta['stats'];
          final msm = 'Se envió correctamente a ${stats['success']}/${stats['total']}';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msm)),
            );
          }
        }
      }).catchError((err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al enviar notificación")),
          );
        }
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Inicializando cámara...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vista previa de la cámara
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // Overlay con información de grabación
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicador de grabación
                if (_isRecording)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'REC',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Duración de grabación
                if (_isRecording)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatDuration(_recordingDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Botón de parada manual (opcional)
          if (_isRecording)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _stopRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const Icon(
                      Icons.stop,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}