import 'package:flutter/material.dart';
import 'package:flutter_app/util/supabase.dart';
import 'package:flutter_app/util/theme_manager.dart';

import 'about_page.dart';
import 'help_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  ThemeMode? _currentTheme = themeManager.themeMode;
  String? _currentLanguage = "en";

  void signOut() {
    supabaseClient.auth.signOut();
  }

  void showDesignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (index) => RadioListTile(
                  title: Text(["System setting", "Light", "Dark"][index]),
                  value: [ThemeMode.system, ThemeMode.light, ThemeMode.dark][index],
                  groupValue: _currentTheme,
                  onChanged: (ThemeMode? value) {
                    setState(() {
                      _currentTheme = value;
                      changeTheme(value);
                    });
                    this.setState(() {});
                  }),
            ),
          ),
        ),
      ),
    );
  }

  void changeTheme(ThemeMode? themeMode) {
    if (themeMode == null) return;
    themeManager.setTheme(themeMode);
  }

  void showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (index) => RadioListTile(
                  title: Text(["Deutsch", "English", "Français"][index]),
                  value: ["de", "en", "fr"][index],
                  groupValue: _currentLanguage,
                  onChanged: (String? value) {
                    setState(() {
                      _currentLanguage = value;
                    });
                    this.setState(() {});
                  }),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget profilePic = CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      child: const Text('U'),
    );

    Widget userName = Column(
      children: <Widget>[
        Text(SupabaseManager.getCurrentProfile()!.username),
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

    String themeText;
    switch (_currentTheme) {
      case ThemeMode.system:
        themeText = "System setting";
        break;
      case ThemeMode.light:
        themeText = "Light";
        break;
      case ThemeMode.dark:
        themeText = "Dark";
        break;
      default:
        themeText = "";
    }

    String languageText;
    switch (_currentLanguage) {
      case "de":
        languageText = "Deutsch";
        break;
      case "en":
        languageText = "English";
        break;
      case "fr":
        languageText = "Français";
        break;
      default:
        languageText = "";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Account"),
      ),
      body: ListView(
        children: [
          userRow,
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(languageText),
            onTap: () => showLanguageDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_medium),
            title: const Text('Design'),
            subtitle: Text(themeText),
            onTap: () => showDesignDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const HelpPage(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AboutPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
