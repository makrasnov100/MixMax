import 'package:mix_max/services/general_info_service.dart';
import 'package:mix_max/services/get_it.dart';
import 'package:mix_max/services/ui/app_colors.dart';
import 'package:mix_max/services/ui/link_service.dart';
import 'package:mix_max/services/ui/size_config.dart';
import 'package:mix_max/widgets/input/link_button.dart';
import 'package:mix_max/widgets/text/normal_text.dart';
import 'package:flutter/material.dart';

class PrivacyAndTermsLinks extends StatelessWidget {
  const PrivacyAndTermsLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NormalText(textAlign: TextAlign.center, text: "By continuing you agree to our: ", color: Colors.grey),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                LinkButton(
                  buttonText: "Privacy Policy",
                  onPress: () {
                    launchLink(getIt<GeneralInfoService>().privacyPolicy);
                  },
                ),
              ],
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: SizeConfig.safeBlockHorizontal),
              child: NormalText(textAlign: TextAlign.center, text: "and ", color: AppColors.grey),
            ),
            LinkButton(
              buttonText: "Terms of Service",
              onPress: () {
                launchLink(getIt<GeneralInfoService>().termsOfService);
              },
            ),
          ],
        ),
      ],
    );
  }
}
