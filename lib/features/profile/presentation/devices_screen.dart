import 'package:flutter/material.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/theme/app_theme.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final List<Map<String, String>> _devices = [
    {
      'id': '1',
      'name': 'Google Pixel 8 Pro',
      'platform': 'Android 14',
      'lastActive': 'Active Now',
    },
    {
      'id': '2',
      'name': 'iPad Pro 11-inch',
      'platform': 'iOS 17',
      'lastActive': '2 hours ago',
    },
    {
      'id': '3',
      'name': 'Chrome Browser (Mac OS)',
      'platform': 'Web Dashboard',
      'lastActive': 'Yesterday',
    },
  ];

  void _revokeDevice(int index) {
    final name = _devices[index]['name'];
    setState(() {
      _devices.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Revoked session access token for $name.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Device Management',
            style: TextStyle(fontWeight: FontWeight.bold, color: context.textColor),
          ),
          iconTheme: IconThemeData(color: context.textColor),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Text(
              'View and revoke logged-in device access tokens. Revoking will log out that session immediately.',
              style: TextStyle(color: context.subtextColor, fontSize: 12),
            ),
            const SizedBox(height: 20),
            ...List.generate(_devices.length, (idx) {
              final dev = _devices[idx];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GlassContainer(
                  child: Row(
                    children: [
                      Icon(
                        Icons.devices_rounded,
                        color: context.subtextColor,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dev['name']!,
                              style: TextStyle(
                                color: context.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${dev['platform']} • ${dev['lastActive']}',
                              style: TextStyle(
                                color: context.mutedTextColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (dev['lastActive'] != 'Active Now')
                        IconButton(
                          icon: const Icon(
                            Icons.delete_forever_rounded,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _revokeDevice(idx),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
