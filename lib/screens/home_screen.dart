import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _espIp = "192.168.0.105"; // IP по умолчанию
  String _ledState = "unknown";
  String _temperature = "---";
  String _humidity = "---";
  String _status = "Нажми 'Обновить данные'";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Загружаем IP из памяти телефона
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _espIp = prefs.getString('esp_ip') ?? "192.168.0.105";
    });
  }

  /// Сохраняем новый IP в память телефона
  Future<void> _saveSettings(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('esp_ip', ip);
    setState(() {
      _espIp = ip;
    });
  }

  Future<void> _getState() async {
    setState(() {
      _status = "Подключаемся...";
    });

    try {
      final client = http.Client();
      final response = await client
          .get(Uri.parse('http://$_espIp/getState'))
          .timeout(const Duration(seconds: 10));

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
      final response = await client
          .get(Uri.parse('http://$_espIp/toggle'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _getState();
      }
      client.close();
    } catch (e) {
      debugPrint("Toggle error: $e");
    }
  }

  /// Открытие окна с настройками (с возможностью изменить IP)
  void _openSettings() async {
    final newIp = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );

    // если пользователь вернулся и ввёл IP — сохранить
    if (newIp != null && newIp is String) {
      _saveSettings(newIp);
    }
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
              color: _status.contains("Ошибка")
                  ? Colors.red[100]
                  : Colors.green[100],
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
