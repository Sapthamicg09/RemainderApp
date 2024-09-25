import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;

void main() {
  runApp(ReminderApp());
}

class ReminderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reminder App',
      home: ReminderHome(),
    );
  }
}

class ReminderHome extends StatefulWidget {
  @override
  _ReminderHomeState createState() => _ReminderHomeState();
}

class _ReminderHomeState extends State<ReminderHome> {
  String? selectedDay;
  TimeOfDay? selectedTime;
  String? selectedActivity;

  final List<String> days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday'
  ];
  final List<String> activities = [
    'Wake up', 'Go to gym', 'Breakfast',
    'Meetings', 'Lunch', 'Quick nap',
    'Go to library', 'Dinner', 'Go to sleep'
  ];

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    initializeNotifications();
  }

  void initializeNotifications() async {
    var initializationSettingsAndroid = AndroidInitializationSettings('app_icon'); // Use your app icon name
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Initialize timezone database
    tzData.initializeTimeZones();
  }

  void showTimePickerDialog() async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        selectedTime = time; // Update selected time
      });
    }
  }

  Future<void> scheduleNotification(String day, TimeOfDay time, String activity) async {
    DateTime scheduledDateTime = DateTime.now();

    // Set the time for the notification based on user input
    scheduledDateTime = DateTime(
      scheduledDateTime.year,
      scheduledDateTime.month,
      scheduledDateTime.day,
      time.hour,
      time.minute,
    );

    // If the selected time is in the past, schedule for the next day
    if (scheduledDateTime.isBefore(DateTime.now())) {
      scheduledDateTime = scheduledDateTime.add(Duration(days: 1));
    }

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'reminder_channel',
      'Reminder Notifications',
      channelDescription: 'Channel for reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    var platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // Notification ID
      'Reminder: $activity', // Title
      'Time to $activity on $day!', // Body
      tz.TZDateTime.from(scheduledDateTime, tz.local), // Schedule time
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void scheduleReminder() {
    if (selectedDay != null && selectedTime != null && selectedActivity != null) {
      scheduleNotification(selectedDay!, selectedTime!, selectedActivity!);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminder set for $selectedDay at ${selectedTime!.format(context)} for $selectedActivity')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select all fields!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Simple Reminder App')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              hint: Text('Select Day'),
              value: selectedDay,
              items: days.map((String day) {
                return DropdownMenuItem(value: day, child: Text(day));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDay = value;
                });
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: showTimePickerDialog,
              child: Text('Select Time'),
            ),
            SizedBox(height: 16),
            DropdownButton<String>(
              hint: Text('Select Activity'),
              value: selectedActivity,
              items: activities.map((String activity) {
                return DropdownMenuItem(value: activity, child: Text(activity));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedActivity = value;
                });
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: scheduleReminder,
              child: Text('Set Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}
