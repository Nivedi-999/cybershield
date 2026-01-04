// lib/onboarding_screen.dart
// First-time setup: biometrics consent, device info consent, PIN setup
// Styled to match CyberShield theme

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _allowBiometrics = true;
  bool _allowDeviceInfo = true;

  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isSaving = false;

  Future<void> _completeSetup() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (pin.length < 4) {
      _showError('PIN must be at least 4 digits');
      return;
    }
    if (pin != confirmPin) {
      _showError('PINs do not match');
      return;
    }

    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_complete', true);
    await prefs.setBool('allow_biometrics', _allowBiometrics);
    await prefs.setBool('allow_device_info', _allowDeviceInfo);
    await prefs.setString('vault_pin', pin); // local only (can be encrypted later)

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1624),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF121B2A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyan.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield, color: Colors.cyan, size: 42),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome to CyberShield',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Let’s secure your vault',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),

                  // Biometrics toggle
                  _SettingTile(
                    title: 'Enable Biometrics',
                    subtitle:
                    'Use fingerprint authentication to unlock your vault',
                    value: _allowBiometrics,
                    onChanged: (v) => setState(() => _allowBiometrics = v),
                    icon: Icons.fingerprint,
                  ),

                  const SizedBox(height: 12),

                  // Device info toggle
                  _SettingTile(
                    title: 'Allow Device Information',
                    subtitle:
                    'Used to show device model and OS version on dashboard',
                    value: _allowDeviceInfo,
                    onChanged: (v) => setState(() => _allowDeviceInfo = v),
                    icon: Icons.phone_android,
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Set Vault PIN',
                    style: TextStyle(
                        color: Colors.cyan,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter PIN',
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Confirm PIN',
                      filled: true,
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _completeSetup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                          : const Text(
                        'Finish Setup',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ===================== UI HELPERS ===================== */

class _SettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;

  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1624),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyan),
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
                Text(subtitle,
                    style:
                    const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.cyan,
          ),
        ],
      ),
    );
  }
}
