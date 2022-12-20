import 'package:flutter/material.dart';
import 'package:flutter_app/account/pages/settings_page.dart';
import 'package:flutter_app/util/profiles/profile_widget.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account"),
      ),
      body: ListView(
        children: [
          InkWell(
            onTap: () => {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ProfileWidget(
                    SupabaseManager.getCurrentProfile()!,
                    size: 25,
                  ),
                  TextButton.icon(
                    onPressed: signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text("Log out"),
                  ),
                ],
              ),
            ),
          ),
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
