import 'package:flutter/material.dart';

/// A reusable card widget that displays a brahmachari's name.
///
/// Used on the attendance screen to show each student with a
/// present/absent toggle.
class NameCard extends StatelessWidget {
  final String name;
  final bool isPresent;
  final ValueChanged<bool>? onChanged;

  const NameCard({
    super.key,
    required this.name,
    this.isPresent = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: isPresent
              ? Colors.green.shade100
              : Colors.red.shade100,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isPresent ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        trailing: Switch(
          value: isPresent,
          activeThumbColor: Colors.green,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
