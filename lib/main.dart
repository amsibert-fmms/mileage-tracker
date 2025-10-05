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
  String status = "No trip in progress";

  void toggleTrip() {
    setState(() {
      if (!tripActive) {
        startTime = DateTime.now();
        status = "Trip started at ${startTime!.hour}:${startTime!.minute.toString().padLeft(2, '0')}";
      } else {
        final stopTime = DateTime.now();
        final duration = stopTime.difference(startTime!);
        status =
            "Trip stopped at ${stopTime.hour}:${stopTime.minute.toString().padLeft(2, '0')} "
            "(${duration.inMinutes} min)";
      }
      tripActive = !tripActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mileage Tracker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(status,
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
