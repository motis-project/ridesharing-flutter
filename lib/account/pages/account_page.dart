import 'package:flutter/material.dart';
import 'package:flutter_app/util/locale_manager.dart';
import 'package:flutter_app/util/profiles/profile_widget.dart';
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
              ThemeMode.values.length,
              (index) => RadioListTile(
                  title: Text(
                    ThemeMode.values[index].getName(context),
                  ),
                  value: ThemeMode.values[index],
                  groupValue: themeManager.currentThemeMode,
                  onChanged: (ThemeMode? value) {
                    setState(() {
                      themeManager.setTheme(value);
                    });
                  }),
            ),
          ),
        ),
      ),
    );
  }

  void showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              localeManager.supportedLocales.length,
              (index) => RadioListTile(
                title: Text(localeManager.supportedLocales.map((e) => e.languageName).toList()[index]),
                value: localeManager.supportedLocales[index],
                groupValue: localeManager.currentLocale,
                onChanged: (Locale? value) {
                  setState(() {
                    localeManager.setCurrentLocale(value);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageAccountTitle),
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
                    label: Text(S.of(context).pageAccountSignOut),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(S.of(context).pageAccountLanguage),
            subtitle: Text(localeManager.currentLocale.languageName),
            onTap: () => showLanguageDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_medium),
            title: Text(S.of(context).pageAccountDesign),
            subtitle: Text(themeManager.currentThemeMode.getName(context)),
            onTap: () => showDesignDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: Text(S.of(context).pageAccountHelp),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const HelpPage(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(S.of(context).pageAccountAbout),
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
