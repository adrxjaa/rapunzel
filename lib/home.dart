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

  int _getFrequency() {
    return box.get('frequency', defaultValue: 3);
  }

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
                      if (temp > 1) setStateDialog(() => temp--);
                    },
                    icon: const Icon(Icons.remove),
                  ),
                  Text("$temp days", style: const TextStyle(fontSize: 18)),
                  IconButton(
                    onPressed: () => setStateDialog(() => temp++),
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
                  setState(() => box.put(_key(day), "water"));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Shampoo + Conditioner"),
                onTap: () {
                  setState(() => box.put(_key(day), "shampoo"));
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                title: const Text("Remove Entry"),
                onTap: () {
                  setState(() => box.delete(_key(day)));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color? _getDayColor(DateTime day) {
    final type = box.get(_key(day));
    if (type == "water") return const Color.fromARGB(255, 158, 163, 255);
    if (type == "shampoo") return const Color.fromARGB(255, 254, 181, 252);
    return null;
  }

  // 🔹 Now takes a `month` parameter instead of hardcoding DateTime.now()
  Map<String, int> _monthlyCounts(DateTime month) {
    int water = 0;
    int shampoo = 0;

    for (var key in box.keys) {
      if (key == 'frequency') continue;

      final parts = key.toString().split("-");
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      if (date.month == month.month && date.year == month.year) {
        final type = box.get(key);
        if (type == "water") water++;
        if (type == "shampoo") shampoo++;
      }
    }

    return {"water": water, "shampoo": shampoo};
  }

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
    final computed = shampooDays.last.add(Duration(days: freq));

    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    if (computed.isBefore(todayNormalized)) return todayNormalized;

    return computed;
  }

  String _monthName(DateTime d) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[d.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    // Pass _focusedDay so summary always reflects the visible calendar month
    final counts = _monthlyCounts(_focusedDay);
    final next = _nextWashDay();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: lavender,
        title: const Text(
          "rapunzel",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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

            // 📊 MONTH SUMMARY — label updates to match the visible month
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
                  Text(
                    "${_monthName(_focusedDay).toUpperCase()} SUMMARY",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${counts['water']! + counts['shampoo']!} Washes Total",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 158, 163, 255)
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.water_drop_outlined,
                                size: 14,
                                color: Color.fromARGB(255, 100, 108, 255)),
                            const SizedBox(width: 4),
                            Text(
                              "${counts['water']} Water",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color.fromARGB(255, 80, 88, 200),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 254, 181, 252)
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bubble_chart_outlined,
                                size: 14,
                                color: Color.fromARGB(255, 180, 80, 180)),
                            const SizedBox(width: 4),
                            Text(
                              "${counts['shampoo']} Shampoo",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color.fromARGB(255, 160, 60, 160),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 🔮 NEXT WASH (CLICKABLE)
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
                    const Text("NEXT WASH DAY",
                        style: TextStyle(color: Colors.white70)),
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
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                // 🔹 This is the key: update _focusedDay when user swipes months
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
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
                          color: color, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text('${day.day}'),
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final color =
                        _getDayColor(day) ?? const Color.fromARGB(255, 205, 151, 246);
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text('${day.day}',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    final isToday = isSameDay(day, DateTime.now());
                    final color = _getDayColor(day) ??
                        (isToday
                            ? const Color.fromARGB(255, 205, 151, 246)
                            : const Color.fromARGB(255, 249, 164, 174));
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color.fromARGB(255, 249, 164, 174), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text('${day.day}',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
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