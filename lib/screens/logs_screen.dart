import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LogsScreen extends StatefulWidget {
  final bool isStandalone;
  const LogsScreen({super.key, this.isStandalone = true});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    final logs = await _apiService.getLogs();
    setState(() {
      _logs = logs.reversed.toList(); // Newest logs first
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      color: const Color(0xFF181A20),
      child: Column(
        children: [
          AppBar(
            title: const Text("System Logs", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false, // Remove back button
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchLogs,
              )
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF)))
                : _logs.isEmpty
                    ? const Center(child: Text("No logs found", style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _logs.length,
                        separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.history, color: Color(0xFF00F0FF), size: 20),
                            title: Text(
                              log['message'] ?? "Empty log",
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            subtitle: Text(
                              log['timestamp'] ?? "Just now",
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );

    if (widget.isStandalone) {
      return Scaffold(body: content);
    } else {
      return content;
    }
  }
}
