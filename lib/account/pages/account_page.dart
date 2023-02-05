import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../util/locale_manager.dart';
import '../../util/profiles/profile_widget.dart';
import '../../util/supabase_manager.dart';
import '../../util/theme_manager.dart';
import 'about_page.dart';
import 'help_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  void initState() {
    //I don't know why this isn't propagated through, for localeManager we just need to call setState in main...
    themeManager.addListener(refresh);
    super.initState();
  }

  @override
  void dispose() {
    themeManager.removeListener(refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageAccountTitle),
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: ProfileWidget(
              supabaseManager.currentProfile!,
              size: 25,
              actionWidget: const Icon(Icons.chevron_right),
              onPop: (_) => setState(() {}),
              withHero: true,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(S.of(context).pageAccountLanguage),
            subtitle: Text(localeManager.currentLocale.languageName),
            onTap: () => showLanguageDialog(context),
            key: const Key('accountLanguage'),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_medium),
            title: Text(S.of(context).pageAccountDesign),
            subtitle: Text(themeManager.currentThemeMode.getName(context)),
            onTap: () => showDesignDialog(context),
            key: const Key('accountTheme'),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: Text(S.of(context).pageAccountHelp),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const HelpPage(),
              ),
            ),
            key: const Key('accountHelp'),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(S.of(context).pageAccountAbout),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const AboutPage(),
              ),
            ),
            key: const Key('accountAbout'),
          ),
        ],
      ),
    );
  }

  void refresh() => setState(() {});

  void showDesignDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, void Function(VoidCallback) innerSetState) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List<RadioListTile<ThemeMode>>.generate(
              ThemeMode.values.length,
              (int index) => RadioListTile<ThemeMode>(
                title: Text(
                  ThemeMode.values[index].getName(context),
                ),
                value: ThemeMode.values[index],
                groupValue: themeManager.currentThemeMode,
                onChanged: (ThemeMode? value) {
                  innerSetState(() {
                    themeManager.setTheme(value);
                  });
                },
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              key: const Key('okButtonDesign'),
              child: Text(S.of(context).okay),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void showLanguageDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, void Function(VoidCallback) innerSetState) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List<RadioListTile<Locale>>.generate(
              localeManager.supportedLocales.length,
              (int index) => RadioListTile<Locale>(
                title: Text(localeManager.supportedLocales.map((Locale e) => e.languageName).toList()[index]),
                value: localeManager.supportedLocales[index],
                groupValue: localeManager.currentLocale,
                onChanged: (Locale? value) {
                  innerSetState(() {
                    localeManager.setCurrentLocale(value);
                  });
                },
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              key: const Key('okButtonLanguage'),
              child: Text(S.of(context).okay),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
