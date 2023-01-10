import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/pages/account_page.dart';
import 'package:motis_mitfahr_app/drives/pages/drives_page.dart';
import 'package:motis_mitfahr_app/home_page.dart';
import 'package:motis_mitfahr_app/rides/pages/rides_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum TabItem { home, drives, rides, account }

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  TabItem _currentTab = TabItem.home;
  final _navigatorKeys = {
    TabItem.home: GlobalKey<NavigatorState>(),
    TabItem.drives: GlobalKey<NavigatorState>(),
    TabItem.rides: GlobalKey<NavigatorState>(),
    TabItem.account: GlobalKey<NavigatorState>(),
  };
  final _pages = {
    TabItem.home: const HomePage(),
    TabItem.drives: const DrivesPage(),
    TabItem.rides: const RidesPage(),
    TabItem.account: const AccountPage(),
  };

  void _selectTab(TabItem tabItem) {
    if (tabItem == _currentTab) {
      // pop to first route
      _navigatorKeys[tabItem]!.currentState!.popUntil((route) => route.isFirst);
    } else {
      setState(() => _currentTab = tabItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final isFirstRouteInCurrentTab = !await _navigatorKeys[_currentTab]!.currentState!.maybePop();
        if (isFirstRouteInCurrentTab) {
          if (_currentTab == TabItem.home) {
            return true;
          }

          _selectTab(TabItem.home);
        }
        return false;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentTab.index,
          children: TabItem.values.map((tabItem) => buildNavigatorForTab(tabItem)).toList(),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: S.of(context).pageHomeTitle,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.drive_eta),
              label: S.of(context).pageDrivesTitle,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chair),
              label: S.of(context).pageRidesTitle,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_circle),
              label: S.of(context).pageAccountTitle,
            ),
          ],
          currentIndex: _currentTab.index,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          onTap: (index) {
            _selectTab(TabItem.values[index]);
          },
        ),
      ),
    );
  }

  Widget buildNavigatorForTab(TabItem tabItem) {
    return Navigator(
      key: _navigatorKeys[tabItem]!,
      onGenerateRoute: (routeSettings) => MaterialPageRoute(
        builder: (context) => _pages[tabItem]!,
      ),
    );
  }
}
