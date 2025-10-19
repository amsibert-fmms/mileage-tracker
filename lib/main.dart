import 'dart:async';

import 'package:flutter/material.dart';

void main() => runApp(const MileageTrackerApp());

class MileageTrackerApp extends StatelessWidget {
  const MileageTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mileage Tracker',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool tripActive = false;
  DateTime? startTime;
  Duration elapsed = Duration.zero;
  Timer? _timer;
  String? lastTripSummary;

  void toggleTrip() {
    if (!tripActive) {
      final now = DateTime.now();
      _timer?.cancel();
      setState(() {
        tripActive = true;
        startTime = now;
        elapsed = Duration.zero;
        lastTripSummary = null;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || startTime == null) return;
        setState(() {
          elapsed = DateTime.now().difference(startTime!);
        });
      });
    } else {
      final stopTime = DateTime.now();
      final duration = stopTime.difference(startTime!);
      _timer?.cancel();
      setState(() {
        tripActive = false;
        elapsed = duration;
        startTime = null;
        lastTripSummary =
            "Trip stopped at ${_formatTime(stopTime)} (${_formatDuration(duration)})";
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final hoursLabel = hours > 0 ? '${hours}h ' : '';
    final minutesLabel = minutes > 0 || hours > 0 ? '${minutes}m ' : '';
    final secondsLabel = '${seconds}s';
    return '$hoursLabel$minutesLabel$secondsLabel'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final statusText = tripActive
        ? 'Trip started at ${_formatTime(startTime!)}\nElapsed: ${_formatDuration(elapsed)}'
        : lastTripSummary ?? 'No trip in progress';

    return Scaffold(
      appBar: AppBar(title: const Text('Mileage Tracker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: toggleTrip,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                backgroundColor: tripActive ? Colors.red : Colors.teal,
              ),
              icon: Icon(tripActive ? Icons.stop : Icons.play_arrow),
              label: Text(tripActive ? 'Stop Trip' : 'Start Trip',
                  style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
