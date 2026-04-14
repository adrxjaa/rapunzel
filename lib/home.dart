import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:table_calendar/table_calendar.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  late Box box;

  final Color lavender = const Color(0xFFCE93D8);

  @override
  void initState() {
    super.initState();
    box = Hive.box('washBox');
  }

  String _key(DateTime d) => "${d.year}-${d.month}-${d.day}";

  // 🔹 GET FREQUENCY
  int _getFrequency() {
    return box.get('frequency', defaultValue: 3);
  }

  // 🔹 SET FREQUENCY DIALOG
  void _showFrequencyDialog() {
    int temp = _getFrequency();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("How often do you wash your hair?"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (temp > 1) {
                        setStateDialog(() => temp--);
                      }
                    },
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    "$temp days",
                    style: const TextStyle(fontSize: 18),
                  ),
                  IconButton(
                    onPressed: () {
                      setStateDialog(() => temp++);
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                box.put('frequency', temp);
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // 🔹 ADD / REMOVE WASH
  void _showWashDialog(DateTime day) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Wash Type"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Water Wash"),
                onTap: () {
                  setState(() {
                    box.put(_key(day), "water");
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Shampoo + Conditioner"),
                onTap: () {
                  setState(() {
                    box.put(_key(day), "shampoo");
                  });
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                title: const Text("Remove Entry"),
                onTap: () {
                  setState(() {
                    box.delete(_key(day));
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔹 COLOR DAYS
  Color? _getDayColor(DateTime day) {
    final type = box.get(_key(day));
    if (type == "water") return const Color.fromARGB(255, 158, 163, 255);
    if (type == "shampoo") return const Color.fromARGB(255, 254, 181, 252);
    return null;
  }

  // 🔹 MONTH COUNT
  int _monthlyCount() {
    final now = DateTime.now();
    int count = 0;

    for (var key in box.keys) {
      if (key == 'frequency') continue;

      final parts = key.toString().split("-");
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      if (date.month == now.month && date.year == now.year) {
        count++;
      }
    }

    return count;
  }

  // 🔹 NEXT WASH LOGIC (UPDATED)
  DateTime? _nextWashDay() {
    List<DateTime> shampooDays = [];

    for (var key in box.keys) {
      if (key == 'frequency') continue;

      if (box.get(key) == "shampoo") {
        final parts = key.toString().split("-");
        shampooDays.add(DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        ));
      }
    }

    if (shampooDays.isEmpty) return null;

    shampooDays.sort();

    final freq = _getFrequency();

    return shampooDays.last.add(Duration(days: freq));
  }

  @override
  Widget build(BuildContext context) {
    final count = _monthlyCount();
    final next = _nextWashDay();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: lavender,
        title: const Text(
          "rapunzel",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          children: [
            const SizedBox(height: 10),

            // 📊 MONTH SUMMARY
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "MONTH SUMMARY",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$count Washes",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 🔮 NEXT WASH (CLICKABLE NOW)
            GestureDetector(
              onTap: _showFrequencyDialog,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lavender,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "NEXT WASH DAY",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Every ${_getFrequency()} days",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      next == null
                          ? "No data"
                          : "${next.day}/${next.month}/${next.year}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 📅 CALENDAR
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                selectedDayPredicate: (day) =>
                    isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _showWashDialog(selectedDay);
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final color = _getDayColor(day);

                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text('${day.day}'),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}