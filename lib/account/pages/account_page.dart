import 'package:flutter/material.dart';
import 'package:flutter_app/account/pages/settings_page.dart';
import 'package:flutter_app/util/supabase.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  void signOut() {
    supabaseClient.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    Widget profilePic = CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      child: const Text('U'),
    );

    Widget userName = Column(
      children: <Widget>[
        const Text("User"),
        TextButton.icon(
          onPressed: signOut,
          icon: const Icon(Icons.logout),
          label: const Text("Log out"),
        )
      ],
    );

    Widget userRow = InkWell(
      onTap: () => {},
      child: Row(
        children: <Widget>[profilePic, userName],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Account"),
      ),
      body: ListView(
        children: [
          userRow,
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SettingsPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
