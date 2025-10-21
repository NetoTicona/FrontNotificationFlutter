import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'video_player_screen.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  List<FileSystemEntity> _videoFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideoFiles();
  }

  Future<void> _loadVideoFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${directory.path}/Videos');

      if (await videosDir.exists()) {
        final files = videosDir.listSync()
            .where((file) => file.path.toLowerCase().endsWith('.mp4'))
            .toList();

        // Ordenar por fecha de modificación (más reciente primero)
        files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

        setState(() {
          _videoFiles = files;
          _isLoading = false;
        });
      } else {
        setState(() {
          _videoFiles = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error al cargar videos: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatFileName(String fileName) {
    // Extraer la fecha del nombre del archivo
    // Formato esperado: YYYYMMDD_HHMMSS_mmm.mp4
    final nameWithoutExtension = fileName.replaceAll('.mp4', '');
    final parts = nameWithoutExtension.split('_');

    if (parts.length >= 3) {
      final datePart = parts[0]; // YYYYMMDD
      final timePart = parts[1]; // HHMMSS
      final millisPart = parts[2]; // mmm

      // Formatear fecha
      if (datePart.length == 8) {
        final year = datePart.substring(0, 4);
        final month = datePart.substring(4, 6);
        final day = datePart.substring(6, 8);

        // Formatear hora
        if (timePart.length == 6) {
          final hour = timePart.substring(0, 2);
          final minute = timePart.substring(2, 4);
          final second = timePart.substring(4, 6);

          return '$day/$month/$year $hour:$minute:$second.$millisPart';
        }
      }
    }

    // Si no se puede parsear, devolver el nombre original
    return fileName;
  }

  String _getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Duration _getVideoDuration(File file) {
    // Para obtener la duración real necesitarías usar video_player
    // Por simplicidad, retornamos una duración estimada basada en el tamaño
    final bytes = file.lengthSync();
    final estimatedSeconds = (bytes / (1024 * 1024)) * 10; // Estimación rough
    return Duration(seconds: estimatedSeconds.round());
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteVideo(File file) async {
    try {
      await file.delete();
      _loadVideoFiles(); // Recargar la lista
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video eliminado')),
      );
    } catch (e) {
      _showError('Error al eliminar video: $e');
    }
  }

  void _showDeleteDialog(File file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar video'),
          content: const Text('¿Estás seguro de que quieres eliminar este video?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteVideo(file);
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos Grabados'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadVideoFiles();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando videos...'),
          ],
        ),
      )
          : _videoFiles.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay videos grabados',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Los videos aparecerán aquí después de grabar',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _videoFiles.length,
        itemBuilder: (context, index) {
          final file = File(_videoFiles[index].path);
          final fileName = file.path.split('/').last;
          final formattedName = _formatFileName(fileName);
          final fileSize = _getFileSize(file);
          final duration = _getVideoDuration(file);
          final modifiedDate = file.statSync().modified;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.video_file,
                  color: Colors.blue,
                  size: 30,
                ),
              ),
              title: Text(
                formattedName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Tamaño: $fileSize • Duración: ${_formatDuration(duration)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Modificado: ${modifiedDate.day}/${modifiedDate.month}/${modifiedDate.year} ${modifiedDate.hour}:${modifiedDate.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteDialog(file);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar'),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(
                      videoPath: file.path,
                      videoTitle: formattedName,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.home),
      ),
    );
  }
}