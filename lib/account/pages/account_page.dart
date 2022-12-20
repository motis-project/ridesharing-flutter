import 'package:flutter/material.dart';
import 'package:flutter_app/util/locale_manager.dart';
import 'package:flutter_app/util/supabase.dart';
import 'package:flutter_app/util/theme_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'about_page.dart';
import 'help_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  ThemeMode? _currentTheme = themeManager.themeMode;
  Locale? _currentLanguage;

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
                  title: Text(
                    [
                      AppLocalizations.of(context)!.pageAccountThemesSystem,
                      AppLocalizations.of(context)!.pageAccountThemesLight,
                      AppLocalizations.of(context)!.pageAccountThemesDark
                    ][index],
                  ),
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
              2,
              (index) => RadioListTile(
                title: Text(localeManager.supportedLocales.map((e) => e.languageName).toList()[index]),
                value: localeManager.supportedLocales[index],
                groupValue: localeManager.currentLocale,
                onChanged: (Object? value) {
                  setState(() {
                    localeManager.setCurrentLocale((value as Locale));
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _currentLanguage ??= Localizations.localeOf(context);

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
        themeText = AppLocalizations.of(context)!.pageAccountThemesSystem;
        break;
      case ThemeMode.light:
        themeText = AppLocalizations.of(context)!.pageAccountThemesLight;
        break;
      case ThemeMode.dark:
        themeText = AppLocalizations.of(context)!.pageAccountThemesDark;
        break;
      default:
        themeText = "";
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
            subtitle: Text(localeManager.currentLocale.languageName),
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
