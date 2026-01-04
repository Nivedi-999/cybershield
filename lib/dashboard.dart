// lib/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import 'vault_screen.dart';

/* ===================== DASHBOARD ===================== */

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String publicIp = 'Loading...';
  Map<String, String> deviceInfo = {
    'model': 'Loading...',
    'version': 'Loading...',
  };
  List<Map<String, String>> news = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    publicIp = await getPublicIp();
    deviceInfo = await getDeviceInfo();
    news = await fetchSecurityNews();
    if (mounted) setState(() {});
  }

  Future<String> getPublicIp() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      return response.statusCode == 200 ? response.body : 'Unknown';
    } catch (_) {
      return 'Error';
    }
  }

  Future<Map<String, String>> getDeviceInfo() async {
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      return {'model': info.model, 'version': info.version.release};
    }
    if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      return {'model': info.name, 'version': info.systemVersion};
    }
    return {'model': 'Unknown', 'version': 'Unknown'};
  }

  Future<List<Map<String, String>>> fetchSecurityNews() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.cyberscoop.com/feed/'),
        headers: {'Cache-Control': 'no-cache'},
      );

      if (response.statusCode == 200) {
        final doc = XmlDocument.parse(response.body);
        final items = doc.findAllElements('item').take(5);

        return items.map((item) {
          final title = item.findElements('title').single.innerText.trim();
          final link = item.findElements('link').single.innerText.trim();
          final desc = item
              .findElements('description')
              .single
              .innerText
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();

          final shortDesc =
          desc.length > 150 ? '${desc.substring(0, 150)}...' : desc;

          return {
            'title': title,
            'link': link,
            'description': shortDesc,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('News error: $e');
    }

    return [
      {'title': 'No news – pull to retry', 'link': '', 'description': ''}
    ];
  }

  Future<void> _showArticleUrl(String url, String title) async {
    if (url.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0E1624),
        title: Text(title, style: const TextStyle(color: Colors.cyan)),
        content:
        SelectableText(url, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.cyan)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri,
                    mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Open', style: TextStyle(color: Colors.cyan)),
          ),
        ],
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1624),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const TopTabs(isDashboard: true),
                const SizedBox(height: 16),

                /// ===== CyberShield Banner =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121B2A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.cyan.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'CyberShield',
                        style: TextStyle(
                          color: Colors.cyan,
                          fontSize: 13,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Security Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        title: 'Device Model',
                        value: deviceInfo['model'] ?? '',
                        icon: Icons.desktop_windows,
                        gradient: const [
                          Color(0xFF1E3C72),
                          Color(0xFF2A5298)
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        title: 'OS Version',
                        value: deviceInfo['version'] ?? '',
                        icon: Icons.shield_outlined,
                        gradient: const [
                          Color(0xFF42275A),
                          Color(0xFF734B6D)
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Public IP Address',
                  value: publicIp,
                  icon: Icons.wifi,
                  gradient: const [
                    Color(0xFF134E5E),
                    Color(0xFF71B280)
                  ],
                ),
                const SizedBox(height: 20),

                /// ===== Security Feed =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121B2A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Security Feed',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...news.map(
                            (item) => _SecurityItem(
                          title: item['title'] ?? '',
                          description: item['description'] ?? '',
                          onTap: () => _showArticleUrl(
                            item['link'] ?? '',
                            item['title'] ?? '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ===================== TOP TABS ===================== */

class TopTabs extends StatelessWidget {
  final bool isDashboard;

  const TopTabs({required this.isDashboard, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            label: 'Dashboard',
            active: isDashboard,
            icon: Icons.grid_view,
            onTap: () {
              if (!isDashboard) Navigator.pop(context);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TabButton(
            label: 'Vault',
            active: !isDashboard,
            icon: Icons.lock_outline,
            onTap: () {
              if (isDashboard) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LockedVaultScreen(),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

/* ===================== UI HELPERS ===================== */

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final IconData icon;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.active,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? Colors.cyan : Colors.white24),
          color: active
              ? const Color(0xFF101F33)
              : const Color(0xFF121B2A),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: active ? Colors.cyan : Colors.white70),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: active ? Colors.cyan : Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: gradient),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecurityItem extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;

  const _SecurityItem({
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyan.withOpacity(0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.cyan),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
