import 'package:flutter/material.dart';
import 'dart:async';
import 'video_recording_screen.dart';

class CounterScreen extends StatefulWidget {
  final Map<String, dynamic> recordingConfig;

  const CounterScreen({
    super.key,
    required this.recordingConfig,
  });

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen>
    with TickerProviderStateMixin {
  int _counter = 10;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animación
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_counter > 0) {
          _counter--;
          // Animar cada cambio de número
          _animationController.reset();
          _animationController.forward();
        } else {
          timer.cancel();
          _navigateToRecording();
        }
      });
    });
  }

  void _navigateToRecording() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => VideoRecordingScreen(
          config: widget.recordingConfig,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Grabación iniciará en:',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 50),
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _counter <= 3 ? Colors.red : Colors.blue,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_counter <= 3 ? Colors.red : Colors.blue)
                              .withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _counter == 0 ? '¡GO!' : _counter.toString(),
                        style: TextStyle(
                          fontSize: _counter == 0 ? 32 : 72,
                          fontWeight: FontWeight.bold,
                          color: _counter <= 3 ? Colors.red : Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 50),
            if (_counter <= 3 && _counter > 0)
              Text(
                '¡Prepárate!',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.red.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}