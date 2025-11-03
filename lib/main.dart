import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Умный Аквариум',
      home: const AquariumControl(),
    );
  }
}

class AquariumControl extends StatefulWidget {
  const AquariumControl({super.key});

  @override
  State<AquariumControl> createState() => _AquariumControlState();
}

class _AquariumControlState extends State<AquariumControl> {
  final String _espIp = "192.168.0.105";
  String _ledState = "unknown";
  String _temperature = "---";
  String _humidity = "---";
  String _status = "Нажми 'Обновить данные'";

  Future<void> _getState() async {
    setState(() {
      _status = "Подключаемся...";
    });

    try {
      final client = http.Client();
      final response = await client.get(
        Uri.parse('http://$_espIp/getState'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _ledState = data['ledState'] ?? 'unknown';
          _temperature = data['temperature']?.toString() ?? '---';
          _humidity = data['humidity']?.toString() ?? '---';
          _status = "Данные получены!";
        });
      } else {
        setState(() {
          _status = "HTTP ошибка: ${response.statusCode}";
        });
      }
      
      client.close();
    } catch (e) {
      setState(() {
        _status = "Ошибка: ${e.toString()}";
      });
    }
  }

  Future<void> _toggleLight() async {
    try {
      final client = http.Client();
      final response = await client.get(
        Uri.parse('http://$_espIp/toggle'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _getState();
      }
      client.close();
    } catch (e) {
      print("Toggle error: $e");
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Умный Аквариум"),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              color: _status.contains("Ошибка") ? Colors.red[100] : Colors.green[100],
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _status.contains("Ошибка") ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildDataCard("💡 Свет", _ledState),
            _buildDataCard("🌡️ Температура", "$_temperature °C"),
            _buildDataCard("💧 Влажность", "$_humidity %"),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _getState,
                  child: const Text("🔄 Обновить"),
                ),
                ElevatedButton(
                  onPressed: _toggleLight,
                  child: const Text("⚡ Свет"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _openSettings,
              child: const Text("⚙️ Настройки"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}