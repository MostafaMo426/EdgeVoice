import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RoomsScreen extends StatefulWidget {
  final bool isStandalone;
  const RoomsScreen({super.key, this.isStandalone = true});

  @override
  State<RoomsScreen> createState() => RoomsScreenState();
}

class RoomsScreenState extends State<RoomsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _rooms = [];
  bool _isLoading = true;

  final Color gradientStart = const Color(0xFF1E293B);
  final Color gradientEnd = const Color(0xFF5270A1);
  final Color accentCyan = const Color(0xFF00F0FF);
  final Color cardColor = const Color(0xFF161E2E);

  Future<void> fetchRooms() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final rooms = await _apiService.getRooms();
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching rooms: ${e.toString()}")),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRooms();
  }

  void _addRoom() {
    String newRoomName = "";
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardColor,
          title: const Text("Add New Room", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Room Name",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: accentCyan),
                  ),
                ),
                onChanged: (val) => newRoomName = val,
              ),
              if (isSubmitting)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: LinearProgressIndicator(color: accentCyan, backgroundColor: Colors.white24),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (newRoomName.trim().isEmpty) return;

                      setDialogState(() => isSubmitting = true);
                      try {
                        final success = await _apiService.addRoom(newRoomName.trim());
                        if (success) {
                          await fetchRooms();
                          if (mounted) Navigator.pop(context);
                        } else {
                          setDialogState(() => isSubmitting = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Failed to add room. Please try again.")),
                            );
                          }
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: ${e.toString()}")),
                          );
                        }
                      }
                    },
              child: Text(isSubmitting ? "Adding..." : "Add", style: TextStyle(color: accentCyan)),
            ),
          ],
        ),
      ),
    );
  }

  void _editRoom(int index) {
    String updatedName = _rooms[index]['name'] ?? "";
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardColor,
          title: const Text("Edit Room", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: updatedName),
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Room Name",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: accentCyan),
                  ),
                ),
                onChanged: (val) => updatedName = val,
              ),
              if (isProcessing)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: LinearProgressIndicator(color: accentCyan, backgroundColor: Colors.white24),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      setDialogState(() => isProcessing = true);
                      final roomId = _rooms[index]['id'];
                      final success = await _apiService.deleteRoom(roomId);
                      if (success) {
                        fetchRooms();
                        if (mounted) Navigator.pop(context);
                      } else {
                        setDialogState(() => isProcessing = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Failed to delete room.")),
                          );
                        }
                      }
                    },
              child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      if (updatedName.trim().isEmpty) return;
                      setDialogState(() => isProcessing = true);
                      final roomId = _rooms[index]['id'];
                      final success = await _apiService.updateRoom(roomId, updatedName.trim());
                      if (success) {
                        fetchRooms();
                        if (mounted) Navigator.pop(context);
                      } else {
                        setDialogState(() => isProcessing = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Failed to update room.")),
                          );
                        }
                      }
                    },
              child: Text(isProcessing ? "Saving..." : "Save", style: TextStyle(color: accentCyan)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRoomControls(int roomIndex) async {
    final roomId = _rooms[roomIndex]['id'];
    List<dynamic> roomDevices = [];
    
    // Show loading indicator or handle it before modal
    try {
      roomDevices = await _apiService.getRoomDevices(roomId);
    } catch (e) {
      print("Error loading room devices: $e");
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final room = _rooms[roomIndex];
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1115),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(room['name'] ?? "Room", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: accentCyan),
                      onPressed: () => _addDeviceToRoom(roomIndex, setModalState, roomDevices),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: roomDevices.length,
                    itemBuilder: (context, index) {
                      final device = roomDevices[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(_getDeviceIcon(device['type'] ?? ""), color: accentCyan),
                                const SizedBox(width: 15),
                                Text(device['name'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 16)),
                              ],
                            ),
                            Row(
                              children: [
                                Switch(
                                  value: device['isOn'] ?? device['status'] ?? false,
                                  activeThumbColor: accentCyan,
                                  onChanged: (val) async {
                                    final success = await _apiService.updateDeviceStatus(device['id'], val);
                                    if (success) {
                                      setModalState(() {
                                        device['isOn'] = val;
                                        device['status'] = val;
                                      });
                                      _apiService.addLog("User turned ${device['name']} ${val ? 'ON' : 'OFF'}");
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () async {
                                    final success = await _apiService.deleteDevice(device['id']);
                                    if (success) {
                                      setModalState(() {
                                        roomDevices.removeAt(index);
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addDeviceToRoom(int roomIndex, Function setModalState, List<dynamic> currentDevices) {
    final availableDevices = [
      "Lights", "TV", "AC", "Curtains", "Fan", "Door", 
      "Coffee Maker", "Fridge", "Air Fryer", "Washing Machine", "Dryer"
    ];
    bool isAdding = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardColor,
          title: const Text("Add Device", style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAdding)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableDevices.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: Icon(_getDeviceIcon(availableDevices[index]), color: accentCyan, size: 20),
                          title: Text(availableDevices[index], style: const TextStyle(color: Colors.white)),
                          onTap: () async {
                            setDialogState(() => isAdding = true);
                            final roomId = _rooms[roomIndex]['id'];
                            final deviceName = availableDevices[index];
                            try {
                              final success = await _apiService.addDevice(roomId, deviceName, availableDevices[index]);
                              if (success) {
                                final updatedDevices = await _apiService.getRoomDevices(roomId);
                                setModalState(() {
                                  currentDevices.clear();
                                  currentDevices.addAll(updatedDevices);
                                });
                                if (mounted) Navigator.pop(context);
                              } else {
                                setDialogState(() => isAdding = false);
                              }
                            } catch (e) {
                              setDialogState(() => isAdding = false);
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String device) {
    switch (device) {
      case "Lights": return Icons.lightbulb_outline;
      case "TV": return Icons.tv;
      case "AC": return Icons.ac_unit;
      case "Curtains": return Icons.curtains;
      case "Fan": return Icons.air;
      case "Door": return Icons.door_front_door;
      case "Fridge": return Icons.kitchen;
      case "Air Fryer": return Icons.outdoor_grill;
      case "Washing Machine": return Icons.local_laundry_service;
      case "Dryer": return Icons.dry;
      default: return Icons.device_hub;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [gradientStart, gradientEnd],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("My Rooms", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.add_box_rounded, color: accentCyan, size: 30),
                        onPressed: _addRoom,
                      ),
                    ],
                  ),
                ],
              ),
              const Text(
                "Long press to edit/delete. Drag to reorder.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF)))
                : Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                  child: ReorderableGridView(
                    itemCount: _rooms.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        final item = _rooms.removeAt(oldIndex);
                        _rooms.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        key: ValueKey(_rooms[index]['id']?.toString() ?? index.toString()),
                        onTap: () => _showRoomControls(index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 5,
                                right: 5,
                                child: IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                                  onPressed: () => _editRoom(index),
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.room_preferences, color: accentCyan, size: 50),
                                    const SizedBox(height: 10),
                                    Text(
                                      _rooms[index]['name'] ?? "",
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text("Tap to manage", style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.isStandalone) {
      return Scaffold(body: content);
    } else {
      return content;
    }
  }
}

class ReorderableGridView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final ReorderCallback onReorder;

  const ReorderableGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorder,
  });

  @override
  State<ReorderableGridView> createState() => _ReorderableGridViewState();
}

class _ReorderableGridViewState extends State<ReorderableGridView> {
  int? draggingIndex;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: widget.itemCount,
      padding: const EdgeInsets.only(bottom: 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        return DragTarget<int>(
          onWillAccept: (data) => data != index,
          onAccept: (data) {
            widget.onReorder(data, index);
          },
          builder: (context, candidateData, rejectedData) {
            return LongPressDraggable<int>(
              data: index,
              feedback: SizedBox(
                width: (MediaQuery.of(context).size.width - 55) / 2,
                height: (MediaQuery.of(context).size.width - 55) / 2,
                child: Material(
                  color: Colors.transparent,
                  child: widget.itemBuilder(context, index),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: widget.itemBuilder(context, index),
              ),
              onDragStarted: () => setState(() => draggingIndex = index),
              onDragEnd: (_) => setState(() => draggingIndex = null),
              child: widget.itemBuilder(context, index),
            );
          },
        );
      },
    );
  }
}
