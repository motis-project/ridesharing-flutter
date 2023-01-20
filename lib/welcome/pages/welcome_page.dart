import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../rides/pages/search_ride_page.dart';
import '../../util/buttons/button.dart';
import 'login_page.dart';
import 'register_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  static const double indicatorSize = 10;
  static const double indicatorMargin = 3;
  static const List<String> images = <String>['assets/welcome1.png', 'assets/welcome2.png', 'assets/welcome3.png'];

  int activePage = 0;

  List<Widget> indicators(int imagesLength, int currentIndex) {
    return List<Container>.generate(imagesLength, (int index) {
      return Container(
        margin: const EdgeInsets.all(indicatorMargin),
        width: indicatorSize,
        height: indicatorSize,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(currentIndex == index ? 1 : 0.3),
          shape: BoxShape.circle,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    Widget carousel = Column(
      children: <Widget>[
        SizedBox(
          height: height / 2 - indicatorSize - indicatorMargin * 2,
          child: PageView.builder(
            itemCount: images.length,
            pageSnapping: true,
            padEnds: false,
            onPageChanged: (int page) {
              setState(() {
                activePage = page;
              });
            },
            itemBuilder: (BuildContext context, int pagePosition) {
              return Container(
                margin: const EdgeInsets.all(10),
                child: Image.asset(images[pagePosition]),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: indicators(images.length, activePage),
        )
      ],
    );
    Widget buttons = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Hero(
            tag: "LoginButton",
            transitionOnUserGestures: true,
            child: Button(
              S.of(context).pageWelcomeLogin,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (BuildContext context) => const LoginPage()),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Hero(
            tag: "RegisterButton",
            transitionOnUserGestures: true,
            child: Button(
              S.of(context).pageWelcomeRegister,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (BuildContext context) => const RegisterPage()),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Hero(
            tag: "SearchButton",
            transitionOnUserGestures: true,
            child: Button(
              S.of(context).pageWelcomeAnonymousSearch,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const SearchRidePage(anonymous: true),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: <Widget>[
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: height > 378
                    ? Column(
                        children: <Widget>[
                          SizedBox(height: height / 2, child: carousel),
                          Expanded(child: buttons),
                        ],
                      )
                    : buttons,
              ),
            )
          ],
        ),
      ),
    );
  }
}
