import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:package_info_plus/package_info_plus.dart';

const String githubLink = 'https://github.com/MOTIS-Mitfahr-App/flutter-app';
const String websiteLink = 'https://motis-project.de/';
// TODO Terms of service
const String termsOfServiceLink = 'https://motis-project.de/';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then(
      (value) => setState(
        () => _packageInfo = value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    TextStyle packageInfoStyle = Theme.of(context)
        .textTheme
        .subtitle2!
        .copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5));
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageAboutTitle),
      ),
      body: Center(
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(children: [
                  Expanded(child: Container()),
                  Text(
                    S.of(context).appName,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (_packageInfo != null) ...[
                    Text(
                      S.of(context).pageAboutVersion(_packageInfo!.version),
                      style: packageInfoStyle,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      S.of(context).pageAboutBuildNumber(_packageInfo!.buildNumber),
                      style: packageInfoStyle,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      S.of(context).pageAboutBuildSignature(_packageInfo!.buildSignature),
                      style: packageInfoStyle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  SvgPicture.asset(
                    'assets/logo.svg',
                    width: MediaQuery.of(context).size.width / 2,
                    height: MediaQuery.of(context).size.width / 2,
                    semanticsLabel: S.of(context).pageAboutLogoSemantics,
                  ),
                  Text(
                    S.of(context).pageAboutText,
                    textAlign: TextAlign.center,
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        TextButton(
                          onPressed: () async => await launchUrlString(
                            githubLink,
                            mode: LaunchMode.externalApplication,
                          ),
                          child: Text(S.of(context).pageAboutGithub),
                        ),
                        TextButton(
                          onPressed: () async => await launchUrlString(websiteLink),
                          child: Text(S.of(context).pageAboutWebsite),
                        ),
                        TextButton(
                          onPressed: () async => await launchUrlString(termsOfServiceLink),
                          child: Text(S.of(context).pageAboutTermsOfService),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
