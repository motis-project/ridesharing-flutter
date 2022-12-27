import 'package:flutter/material.dart';
import 'package:flutter_app/account/pages/account_page.dart';
import 'package:flutter_app/drives/pages/drives_page.dart';
import 'package:flutter_app/home_page.dart';
import 'package:flutter_app/rides/pages/rides_page.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';

enum TabItem { home, drives, rides, account }

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  PersistentTabController _controller = PersistentTabController(initialIndex: 0);

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      confineInSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      popAllScreensOnTapOfSelectedTab: true,
      popActionScreens: PopActionScreensType.all,
      itemAnimationProperties: const ItemAnimationProperties(
        duration: Duration(milliseconds: 200),
        curve: Curves.ease,
      ),
      screenTransitionAnimation: const ScreenTransitionAnimation(
        animateTabTransition: true,
        curve: Curves.ease,
        duration: Duration(milliseconds: 200),
      ),
      navBarStyle: NavBarStyle.style3,
    );
  }

  List<Widget> _buildScreens() {
    return const [HomePage(), HomePage(), HomePage(), HomePage()];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home),
        title: ("Home"),
        activeColorPrimary: Theme.of(context).colorScheme.primary,
        inactiveColorPrimary: Theme.of(context).unselectedWidgetColor,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.drive_eta),
        title: ("Drives"),
        activeColorPrimary: Theme.of(context).colorScheme.primary,
        inactiveColorPrimary: Theme.of(context).unselectedWidgetColor,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.chair),
        title: ("Rides"),
        activeColorPrimary: Theme.of(context).colorScheme.primary,
        inactiveColorPrimary: Theme.of(context).unselectedWidgetColor,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.account_circle),
        title: ("Account"),
        activeColorPrimary: Theme.of(context).colorScheme.primary,
        inactiveColorPrimary: Theme.of(context).unselectedWidgetColor,
      ),
    ];
  }
}
