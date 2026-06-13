import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LogsScreen extends StatefulWidget {
  final bool isStandalone;
  const LogsScreen({super.key, this.isStandalone = true});

  @override
  State<LogsScreen> createState() => LogsScreenState();
}

class LogsScreenState extends State<LogsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    refreshLogs();
  }

  Future<void> refreshLogs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final logs = await _apiService.getLogs();
    if (mounted) {
      setState(() {
        _logs = List.from(logs);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color gradientStart = Color(0xFF1E293B);
    const Color gradientEnd = Color(0xFF5270A1);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [gradientStart, gradientEnd],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 50),
          const Text("System Logs", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF)))
                : RefreshIndicator(
                    onRefresh: refreshLogs,
                    color: const Color(0xFF00F0FF),
                    backgroundColor: const Color(0xFF1E293B),
                    child: _logs.isEmpty
                        ? const Center(child: Text("No logs found", style: TextStyle(color: Colors.grey)))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            itemCount: _logs.length,
                            separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              
                              // Extract timestamp from multiple possible keys
                              String rawTime = log['timestamp'] ?? 
                                               log['Timestamp'] ?? 
                                               log['createdAt'] ?? 
                                               log['CreatedAt'] ?? 
                                               "";
                              
                              String formattedTime = "Just now";
                              
                              if (rawTime.isNotEmpty) {
                                try {
                                  DateTime dt = DateTime.parse(rawTime).toLocal();
                                  // Simple formatting: HH:mm:ss | yyyy-MM-dd
                                  String hour = dt.hour.toString().padLeft(2, '0');
                                  String min = dt.minute.toString().padLeft(2, '0');
                                  String sec = dt.second.toString().padLeft(2, '0');
                                  String day = dt.day.toString().padLeft(2, '0');
                                  String month = dt.month.toString().padLeft(2, '0');
                                  formattedTime = "$hour:$min:$sec  |  $day/$month/${dt.year}";
                                } catch (e) {
                                  formattedTime = rawTime; // Fallback to raw if parse fails
                                }
                              }

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.history, color: Color(0xFF00F0FF), size: 20),
                                title: Text(
                                  log['message'] ?? "Empty log",
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                                subtitle: Text(
                                  formattedTime,
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
