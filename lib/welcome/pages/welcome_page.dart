import 'package:flutter/material.dart';
import 'package:flutter_app/util/big_button.dart';
import 'package:flutter_app/welcome/pages/login_page.dart';
import 'package:flutter_app/welcome/pages/register_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  static const double indicatorSize = 10;
  static const double indicatorMargin = 3;
  static const List<String> images = [
    'assets/welcome1.png',
    'assets/welcome2.png',
    'assets/welcome3.png'
  ];

  int activePage = 0;

  List<Widget> indicators(imagesLength, currentIndex) {
    return List<Widget>.generate(imagesLength, (index) {
      return Container(
        margin: const EdgeInsets.all(indicatorMargin),
        width: indicatorSize,
        height: indicatorSize,
        decoration: BoxDecoration(
          color: currentIndex == index ? Colors.black : Colors.black26,
          shape: BoxShape.circle,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    Widget carousel = Column(
      children: [
        SizedBox(
          height: height / 2 - indicatorSize - indicatorMargin * 2,
          child: PageView.builder(
            itemCount: images.length,
            pageSnapping: true,
            padEnds: false,
            onPageChanged: (page) {
              setState(() {
                activePage = page;
              });
            },
            itemBuilder: (context, pagePosition) {
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
        children: [
          Hero(
            tag: "LoginButton",
            transitionOnUserGestures: true,
            child: BigButton(
              text: "Login",
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Hero(
            tag: "RegisterButton",
            transitionOnUserGestures: true,
            child: BigButton(
              text: "Register",
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const RegisterPage()),
              ),
            ),
          )
        ],
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: height > 300
                    ? Column(
                        children: [
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
