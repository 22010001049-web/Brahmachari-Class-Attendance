import 'package:flutter/material.dart';
import 'new_session_screen.dart';
import 'history_screen.dart';
import 'manage_speakers_screen.dart';
import 'manage_brahmacharis_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'dashboard_screen.dart';
import 'global_search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brahmachari Class Attendance'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                'Brahmachari Class Attendance',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your attendance easily',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _DashboardButton(
                      icon: Icons.play_circle_fill,
                      label: 'Start New Session',
                      color: Colors.deepPurple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NewSessionScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DashboardButton(
                      icon: Icons.history,
                      label: 'Attendance History',
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HistoryScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DashboardButton(
                      icon: Icons.person,
                      label: 'Manage Speakers',
                      color: Colors.indigo,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ManageSpeakersScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DashboardButton(
                      icon: Icons.people,
                      label: 'Manage Brahmacharis',
                      color: Colors.teal,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ManageBrahmacharisScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DashboardButton(
                      icon: Icons.assessment,
                      label: 'Export Reports',
                      color: Colors.purple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ReportsScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DashboardButton(
                      icon: Icons.dashboard,
                      label: 'Dashboard',
                      color: Colors.lightBlue.shade700,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DashboardScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DashboardButton(
                      icon: Icons.search,
                      label: 'Global Search',
                      color: Colors.cyan.shade700,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GlobalSearchScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DashboardButton(
                      icon: Icons.settings,
                      label: 'Settings',
                      color: Colors.grey.shade700,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DashboardButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          shadowColor: color.withAlpha(80),
        ),
        child: Row(
          children: [
            Icon(icon, size: 36),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 20),
          ],
        ),
      ),
    );
  }
}
