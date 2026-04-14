import 'package:flutter/material.dart';

class Room {
  String name;
  List<String> devices;

  Room({required this.name, required this.devices});
}

class RoomsScreen extends StatefulWidget {
  final bool isStandalone;
  const RoomsScreen({super.key, this.isStandalone = true});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final List<Room> _rooms = [
    Room(name: "Living Room", devices: ["Lights", "TV", "AC"]),
    Room(name: "Bedroom", devices: ["Lights", "Fan", "Curtains"]),
    Room(name: "Kitchen", devices: ["Lights", "Coffee Maker"]),
  ];

  final Color gradientStart = const Color(0xFF1E293B);
  final Color gradientEnd = const Color(0xFF5270A1);
  final Color accentCyan = const Color(0xFF00F0FF);
  final Color cardColor = const Color(0xFF161E2E);

  void _addRoom() {
    String newRoomName = "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text("Add New Room", style: TextStyle(color: Colors.white)),
        content: TextField(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (newRoomName.isNotEmpty) {
                setState(() {
                  _rooms.add(Room(name: newRoomName, devices: []));
                });
                Navigator.pop(context);
              }
            },
            child: Text("Add", style: TextStyle(color: accentCyan)),
          ),
        ],
      ),
    );
  }

  void _editRoom(int index) {
    String updatedName = _rooms[index].name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text("Edit Room", style: TextStyle(color: Colors.white)),
        content: TextField(
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
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _rooms.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (updatedName.isNotEmpty) {
                setState(() {
                  _rooms[index].name = updatedName;
                });
                Navigator.pop(context);
              }
            },
            child: Text("Save", style: TextStyle(color: accentCyan)),
          ),
        ],
      ),
    );
  }

  void _showRoomControls(int roomIndex) {
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
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(room.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: accentCyan),
                      onPressed: () => _addDeviceToRoom(roomIndex, setModalState),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: room.devices.length,
                    itemBuilder: (context, index) {
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
                                Icon(_getDeviceIcon(room.devices[index]), color: accentCyan),
                                const SizedBox(width: 15),
                                Text(room.devices[index], style: const TextStyle(color: Colors.white, fontSize: 16)),
                              ],
                            ),
                            Row(
                              children: [
                                Switch(
                                  value: true, // Placeholder for state
                                  activeColor: accentCyan,
                                  onChanged: (val) {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    setModalState(() {
                                      room.devices.removeAt(index);
                                    });
                                    setState(() {});
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

  void _addDeviceToRoom(int roomIndex, Function setModalState) {
    final availableDevices = ["Lights", "TV", "AC", "Curtains", "Fan", "Door", "Coffee Maker"];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text("Add Device", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableDevices.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(availableDevices[index], style: const TextStyle(color: Colors.white)),
                onTap: () {
                  setState(() {
                    _rooms[roomIndex].devices.add(availableDevices[index]);
                  });
                  setModalState(() {});
                  Navigator.pop(context);
                },
              );
            },
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
                child: Theme(
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
                        key: ValueKey(_rooms[index].name + index.toString()),
                        onTap: () => _showRoomControls(index),
                        // Removed onLongPress here to let LongPressDraggable handle it
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                                      _rooms[index].name,
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text("${_rooms[index].devices.length} Devices", style: TextStyle(color: Colors.grey[400], fontSize: 14)),
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

// Simple Reorderable Grid Implementation if package not available
// Since I can't add new packages easily, I will implement a manual drag-and-drop or use ReorderableListView if preferred.
// For now, I'll use a ReorderableListView for simplicity and stability.
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
        childAspectRatio: 1.0, // Perfect Squares
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
