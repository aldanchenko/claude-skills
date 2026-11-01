import 'package:flutter/material.dart';

void main() => runApp(const HabitApp());

class Habit {
  final String name;
  final int streak;
  bool doneToday;

  Habit(this.name, this.streak, {this.doneToday = false});
}

class HabitApp extends StatelessWidget {
  const HabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habits',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  final _habits = [
    Habit('Read 20 pages', 12, doneToday: true),
    Habit('Walk 8,000 steps', 4),
    Habit('No phone after 22:00', 0),
  ];

  void _addHabit() async {
    final controller = TextEditingController();
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New habit', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      setState(() => _habits.add(Habit(name.trim(), 0)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HabitsPage(habits: _habits, onToggle: (h) => setState(() => h.doneToday = !h.doneToday)),
      StatsPage(habits: _habits),
      SettingsPage(onReset: () => setState(() {
        for (final h in _habits) {
          h.doneToday = false;
        }
      })),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      body: pages[_tab],
      floatingActionButton: _tab == 0
          ? FloatingActionButton(onPressed: _addHabit, child: const Icon(Icons.add))
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.check_circle_outline), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class HabitsPage extends StatelessWidget {
  final List<Habit> habits;
  final ValueChanged<Habit> onToggle;

  const HabitsPage({super.key, required this.habits, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final habit in habits)
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(habit.name[0])),
              title: Text(habit.name),
              subtitle: Text('${habit.streak} day streak'),
              trailing: Checkbox(
                value: habit.doneToday,
                onChanged: (_) => onToggle(habit),
              ),
            ),
          ),
      ],
    );
  }
}

class StatsPage extends StatelessWidget {
  final List<Habit> habits;

  const StatsPage({super.key, required this.habits});

  @override
  Widget build(BuildContext context) {
    final done = habits.where((h) => h.doneToday).length;
    final progress = habits.isEmpty ? 0.0 : done / habits.length;
    final best = habits.fold(0, (m, h) => h.streak > m ? h.streak : m);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('$done of ${habits.length} done',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: progress),
              ],
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.local_fire_department, color: Colors.orange),
            title: const Text('Best streak'),
            trailing: Text('$best days', style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
      ],
    );
  }
}

class SettingsPage extends StatefulWidget {
  final VoidCallback onReset;

  const SettingsPage({super.key, required this.onReset});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _reminders = true;

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset today?'),
        content: const Text('All habits will be marked as not done.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok == true && mounted) {
      widget.onReset();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Today was reset')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.notifications),
          title: const Text('Daily reminder'),
          value: _reminders,
          onChanged: (v) => setState(() => _reminders = v),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.restart_alt, color: Colors.red),
          title: const Text('Reset today'),
          onTap: _confirmReset,
        ),
      ],
    );
  }
}
