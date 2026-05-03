import 'package:flutter/material.dart';
import 'package:mix_max/classes/app/sign_in_result.dart';
import 'package:mix_max/services/firebase/auth_service.dart';
import 'package:mix_max/services/get_it.dart';
import 'package:mix_max/services/globals.dart';
import 'package:mix_max/services/ui/app_colors.dart';
import 'package:mix_max/widgets/input/icon_button/icon_button.dart';

class SignInWithAppleButton extends StatelessWidget {
  const SignInWithAppleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      onPressed: () async {
        Navigator.pop(context);
        SignInResult result = await getIt<AuthService>().signInWithApple();
        if (!result.success) {
          snackbarKey.currentState?.showSnackBar(
            SnackBar(
              content: Text("❌ ${result.message}"),
              backgroundColor: AppColors.dangerRed,
              duration: Duration(seconds: 5),
            ),
          );
        }
      },
      text: "Sign in with Apple",
      isOutline: false,
      color: Colors.black,
      iconEnd: Icons.navigate_next_rounded,
      svgIconStart: "assets/svg/icons/apple_icon.svg",
    );
  }
}
