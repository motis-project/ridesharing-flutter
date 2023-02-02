import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'account/pages/account_page.dart';
import 'drives/pages/drives_page.dart';
import 'home_page.dart';
import 'rides/pages/rides_page.dart';

enum TabItem { home, drives, rides, account }

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  TabItem _currentTab = TabItem.home;
  final Map<TabItem, GlobalKey<NavigatorState>> _navigatorKeys = <TabItem, GlobalKey<NavigatorState>>{
    TabItem.home: GlobalKey<NavigatorState>(),
    TabItem.drives: GlobalKey<NavigatorState>(),
    TabItem.rides: GlobalKey<NavigatorState>(),
    TabItem.account: GlobalKey<NavigatorState>(),
  };
  final Map<TabItem, Widget> _pages = <TabItem, Widget>{
    TabItem.home: const HomePage(),
    TabItem.drives: const DrivesPage(),
    TabItem.rides: const RidesPage(),
    TabItem.account: const AccountPage(),
  };

  void _selectTab(TabItem tabItem) {
    if (tabItem == _currentTab) {
      // pop to first route
      _navigatorKeys[tabItem]!.currentState!.popUntil((Route<void> route) => route.isFirst);
    } else {
      setState(() => _currentTab = tabItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final bool isFirstRouteInCurrentTab = !await _navigatorKeys[_currentTab]!.currentState!.maybePop();
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
          children: TabItem.values.map((TabItem tabItem) => buildNavigatorForTab(tabItem)).toList(),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.home, key: Key('homeIcon')),
              label: S.of(context).pageHomeTitle,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.drive_eta, key: Key('drivesIcon')),
              label: S.of(context).pageDrivesTitle,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chair, key: Key('ridesIcon')),
              label: S.of(context).pageRidesTitle,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_circle, key: Key('accountIcon')),
              label: S.of(context).pageAccountTitle,
            ),
          ],
          currentIndex: _currentTab.index,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          onTap: (int index) {
            _selectTab(TabItem.values[index]);
          },
        ),
      ),
    );
  }

  Widget buildNavigatorForTab(TabItem tabItem) {
    return Navigator(
      key: _navigatorKeys[tabItem],
      observers: <NavigatorObserver>[HeroController()],
      onGenerateRoute: (RouteSettings routeSettings) => MaterialPageRoute<void>(
        builder: (BuildContext context) => _pages[tabItem]!,
      ),
    );
  }
}
