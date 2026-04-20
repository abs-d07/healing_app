import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(HealingApp());
}

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

class HealingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> tasks = [];
  String today = "";
  Random random = Random();

  @override
  void initState() {
    super.initState();
    initApp();
    initNotifications();
  }

  void initApp() async {
    today = DateTime.now().toString().split(" ")[0];
    generateTasks();
    await loadData();
    setState(() {});
  }

  // 🔔 Notifications
  void initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await notifications.initialize(settings);

    scheduleReminder(9, 0, "Good morning ❤️ Take your meds & banana");
    scheduleReminder(13, 30, "Lunch time 🍽️ Don’t skip!");
    scheduleReminder(21, 30, "Night meds 🌙 Take care ❤️");
  }

  void scheduleReminder(int hour, int min, String msg) async {
    await notifications.showDailyAtTime(
      hour,
      msg,
      msg,
      Time(hour, min, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminder',
        ),
      ),
    );
  }

  void generateTasks() {
    tasks = [
      {"name": "Dates", "done": false, "type": "vitamin"},
      {"name": "Banana", "done": false, "type": "vitamin"},
      {"name": "Apple", "done": false, "type": "vitamin"},
      {"name": "Pomegranate", "done": false, "type": "vitamin"},
      {"name": "Almond", "done": false, "type": "protein"},
      {"name": "Pista", "done": false, "type": "protein"},
      {"name": "Raisin", "done": false, "type": "mineral"},
      {"name": "Pumpkin seeds", "done": false, "type": "mineral"},
      {"name": "Breakfast", "done": false, "type": "protein"},
      {"name": "Lunch", "done": false, "type": "protein"},
      {"name": "Dinner", "done": false, "type": "protein"},
      {"name": "Eggs", "done": false, "type": "protein"},
      {"name": "Gas tablet", "done": false, "type": "other"},
      {"name": "Morning tablet", "done": false, "type": "other"},
      {"name": "Night tablet", "done": false, "type": "other"},
      {"name": "Water (2-3L)", "done": false, "type": "other"},
    ];
  }

  double get progress {
    int done = tasks.where((t) => t["done"]).length;
    return done / tasks.length;
  }

  String getGoalMessage() {
    if (progress > 0.8) return "Goal achieved today ❤️";
    if (progress > 0.5) return "Almost there 💪";
    return "Let’s improve today 🌱";
  }

  String getCuteMessage() {
    List<String> msgs = [
      "I made this for you ❤️",
      "I’m proud of you 💖",
      "Take care please 🌱",
      "I’m always with you ❤️",
      "You matter to me 💕",
    ];
    return msgs[random.nextInt(msgs.length)];
  }

  Map<String, double> getNutrition() {
    double p = 0, v = 0, m = 0;
    for (var t in tasks) {
      if (t["done"]) {
        if (t["type"] == "protein") p++;
        if (t["type"] == "vitamin") v++;
        if (t["type"] == "mineral") m++;
      }
    }
    return {"Protein": p, "Vitamins": v, "Minerals": m};
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    int percent = (progress * 100).toInt();

    prefs.setString(today, jsonEncode({
      "tasks": tasks,
      "progress": percent,
    }));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(getCuteMessage())),
    );
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(today)) {
      var data = jsonDecode(prefs.getString(today)!);
      tasks = List<Map<String, dynamic>>.from(data["tasks"]);
    }
  }

  @override
  Widget build(BuildContext context) {
    var nutrition = getNutrition();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [

              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hi ❤️"),
                      Text(today),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.bar_chart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DashboardPage()),
                      );
                    },
                  )
                ],
              ),

              SizedBox(height: 10),

              LinearProgressIndicator(value: progress),
              Text("${(progress * 100).toInt()}%"),
              Text(getGoalMessage()),

              SizedBox(height: 10),

              Expanded(
                child: ListView.builder(
                  physics: BouncingScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (_, i) {
                    return Card(
                      child: CheckboxListTile(
                        title: Text(tasks[i]["name"]),
                        value: tasks[i]["done"],
                        onChanged: (val) {
                          setState(() {
                            tasks[i]["done"] = val;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

              SizedBox(
                height: 150,
                child: PieChart(
                  PieChartData(
                    sections: nutrition.entries.map((e) {
                      return PieChartSectionData(
                        value: e.value,
                        title: e.key,
                      );
                    }).toList(),
                  ),
                ),
              ),

              ElevatedButton(
                onPressed: saveData,
                child: Text("Save ❤️"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// 📊 DASHBOARD
class DashboardPage extends StatelessWidget {
  Future<Map<String, dynamic>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> history = {};

    for (var key in prefs.getKeys()) {
      if (key.contains("-")) {
        history[key] = jsonDecode(prefs.getString(key)!);
      }
    }
    return history;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Progress Dashboard 📊")),
      body: FutureBuilder(
        future: loadHistory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          var history = snapshot.data as Map<String, dynamic>;

          return ListView(
            children: history.keys.map((date) {
              var d = history[date];

              return ListTile(
                title: Text(date),
                subtitle: Text("${d["progress"]}%"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DayDetailPage(date, d),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// 📅 DETAIL PAGE
class DayDetailPage extends StatelessWidget {
  final String date;
  final Map data;

  DayDetailPage(this.date, this.data);

  @override
  Widget build(BuildContext context) {
    List tasks = data["tasks"];

    return Scaffold(
      appBar: AppBar(title: Text(date)),
      body: ListView(
        children: tasks.map((t) {
          return ListTile(
            leading: Icon(
              t["done"] ? Icons.check_circle : Icons.cancel,
              color: t["done"] ? Colors.green : Colors.red,
            ),
            title: Text(t["name"]),
          );
        }).toList(),
      ),
    );
  }
}