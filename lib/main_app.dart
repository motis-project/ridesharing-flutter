import 'package:flutter/material.dart';
import 'package:flutter_app/account/account_page.dart';
import 'package:flutter_app/drives/pages/drives_page.dart';
import 'package:flutter_app/home_page.dart';
import 'package:flutter_app/rides/pages/rides_page.dart';
import 'package:flutter_app/account/pages/settings_page.dart';

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
          final isFirstRouteInCurrentTab =
              !await _navigatorKeys[_currentTab]!.currentState!.maybePop();
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
            children: TabItem.values
                .map((tabItem) => buildNavigatorForTab(tabItem))
                .toList(),
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.drive_eta),
                label: 'Drives',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chair),
                label: 'Rides',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle),
                label: 'Account',
              ),
            ],
            currentIndex: _currentTab.index,
            selectedItemColor: Colors.blue,
            onTap: (index) {
              _selectTab(TabItem.values[index]);
            },
          ),
        ));
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
