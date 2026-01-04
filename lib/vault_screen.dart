import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'auth_provider.dart';
import 'dashboard.dart';

/* ===================== LOCKED VAULT ===================== */

class LockedVaultScreen extends StatefulWidget {
  const LockedVaultScreen({super.key});

  @override
  State<LockedVaultScreen> createState() => _LockedVaultScreenState();
}

class _LockedVaultScreenState extends State<LockedVaultScreen> {
  bool _showPin = false;
  final _pinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Provider.of<AuthProvider>(context, listen: false)
        .authenticate(reason: 'Unlock your vault');
  }

  Future<void> _unlockWithPin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.unlockWithPin(_pinCtrl.text);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.unlocked) return const VaultContentScreen();

    return Scaffold(
      backgroundColor: const Color(0xFF0E1624),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: TopTabs(isDashboard: false),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: 340,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121B2A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.lock, color: Colors.cyan, size: 40),
                    const SizedBox(height: 16),
                    const Text(
                      'Unlock Vault',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    if (!_showPin) ...[
                      const Icon(Icons.fingerprint,
                          color: Colors.cyan, size: 48),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => setState(() => _showPin = true),
                        child: const Text(
                          'Use PIN instead',
                          style: TextStyle(color: Colors.cyan),
                        ),
                      )
                    ] else ...[
                      TextField(
                        controller: _pinCtrl,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          filled: true,
                          hintText: 'Enter PIN',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _unlockWithPin,
                        child: const Text('Unlock'),
                      ),
                    ]
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===================== VAULT CONTENT ===================== */

class VaultContentScreen extends StatelessWidget {
  const VaultContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('vault');

    return Scaffold(
      backgroundColor: const Color(0xFF0E1624),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddItemDialog(),
        ),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, Box box, _) {
            final entries = box.toMap().entries.toList();
            final passwords =
            entries.where((e) => e.value['type'] == 'password');
            final notes = entries.where((e) => e.value['type'] == 'note');

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const TopTabs(isDashboard: false),
                const SizedBox(height: 16),

                /// ===== Banner =====
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121B2A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.cyan.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Column(
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
                            'Encrypted Vault',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Lock Vault',
                        icon:
                        const Icon(Icons.lock_outline, color: Colors.cyan),
                        onPressed: () {
                          Provider.of<AuthProvider>(context, listen: false)
                              .lock();
                        },
                      ),
                    ],
                  ),
                ),

                if (passwords.isNotEmpty) ...[
                  const Text('Passwords',
                      style: TextStyle(color: Colors.cyan)),
                  ...passwords
                      .map((e) => PasswordTile(e.key, e.value)),
                ],

                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Secure Notes',
                      style: TextStyle(color: Colors.cyan)),
                  ...notes.map((e) => NoteTile(e.key, e.value)),
                ],

                if (passwords.isEmpty && notes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: Text(
                        'No items in vault',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  )
              ],
            );
          },
        ),
      ),
    );
  }
}

/* ===================== PASSWORD TILE ===================== */

class PasswordTile extends StatefulWidget {
  final dynamic hiveKey;
  final Map item;

  const PasswordTile(this.hiveKey, this.item, {super.key});

  @override
  State<PasswordTile> createState() => _PasswordTileState();
}

class _PasswordTileState extends State<PasswordTile> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('vault');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyan.withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(widget.item['title'],
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.cyan, size: 18),
            onPressed: () => showDialog(
              context: context,
              builder: (_) =>
                  AddItemDialog(existing: widget.item, hiveKey: widget.hiveKey),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
            onPressed: () => box.delete(widget.hiveKey),
          ),
        ]),
        const SizedBox(height: 4),
        Text('Username: ${widget.item['user']}',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text('URL: ${widget.item['url']}',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: Text(
              _hidden
                  ? '•' * widget.item['value'].length
                  : widget.item['value'],
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: Icon(
              _hidden ? Icons.visibility_off : Icons.visibility,
              color: Colors.cyan,
            ),
            onPressed: () => setState(() => _hidden = !_hidden),
          ),
        ])
      ]),
    );
  }
}

/* ===================== NOTE TILE ===================== */

class NoteTile extends StatelessWidget {
  final dynamic hiveKey;
  final Map item;

  const NoteTile(this.hiveKey, this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('vault');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(item['title'],
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.cyan, size: 18),
            onPressed: () => showDialog(
              context: context,
              builder: (_) =>
                  AddItemDialog(existing: item, hiveKey: hiveKey),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
            onPressed: () => box.delete(hiveKey),
          ),
        ]),
        const SizedBox(height: 6),
        Text(item['value'],
            style: const TextStyle(color: Colors.white70))
      ]),
    );
  }
}

/* ===================== ADD / EDIT DIALOG ===================== */

class AddItemDialog extends StatefulWidget {
  final Map? existing;
  final dynamic hiveKey;

  const AddItemDialog({this.existing, this.hiveKey, super.key});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  late bool isPassword;

  final title = TextEditingController();
  final user = TextEditingController();
  final url = TextEditingController();
  final value = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    isPassword = e == null || e['type'] == 'password';

    if (e != null) {
      title.text = e['title'];
      user.text = e['user'] ?? '';
      url.text = e['url'] ?? '';
      value.text = e['value'];
    }
  }

  void _save() {
    final box = Hive.box('vault');

    final data = {
      'type': isPassword ? 'password' : 'note',
      'title': title.text,
      'user': user.text,
      'url': url.text,
      'value': value.text,
    };

    if (widget.hiveKey != null) {
      box.put(widget.hiveKey, data);
    } else {
      box.add(data);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Item'),
      content: SingleChildScrollView(
        child: Column(children: [
          ToggleButtons(
            isSelected: [isPassword, !isPassword],
            onPressed: (i) => setState(() => isPassword = i == 0),
            children: const [
              Padding(padding: EdgeInsets.all(8), child: Text('Password')),
              Padding(padding: EdgeInsets.all(8), child: Text('Note')),
            ],
          ),
          TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title')),
          if (isPassword) ...[
            TextField(
                controller: user,
                decoration:
                const InputDecoration(labelText: 'Username')),
            TextField(
                controller: url,
                decoration: const InputDecoration(labelText: 'URL')),
          ],
          TextField(
              controller: value,
              decoration: InputDecoration(
                  labelText: isPassword ? 'Password' : 'Note')),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
