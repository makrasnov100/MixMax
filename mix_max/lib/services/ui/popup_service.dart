import 'package:flutter/material.dart';
import 'package:mix_max/services/globals.dart';
import 'package:mix_max/services/firebase/format_exception_message.dart';
import 'package:mix_max/services/ui/app_colors.dart';

class PopupService {
  static Future<void> performToastOperation({
    String? loadingMessage,
    String? successMessage,
    String? errorMessage,
    bool appendError = false,
    required Function operation,
    Function? onSuccess,
  }) async {
    final loadingSnackbar = SnackBar(
      content: Row(
        children: [
          Text(loadingMessage ?? '⌛ Proccessing...', style: TextStyle(color: Colors.black)),
          Padding(padding: const EdgeInsets.all(8.0), child: CircularProgressIndicator()),
        ],
      ),
      backgroundColor: Colors.white,
      duration: Duration(seconds: 10),
    );
    final generatingSnackbar = snackbarKey.currentState?.showSnackBar(loadingSnackbar);

    String? exceptionMessage;
    bool isError = false;
    try {
      await operation();
      generatingSnackbar?.close();
      final completeSnackbar = SnackBar(
        content: Text(successMessage ?? "✅ Request completed successfully!"),
        backgroundColor: AppColors.addGreen,
        duration: Duration(seconds: 5),
      );
      snackbarKey.currentState?.showSnackBar(completeSnackbar);
      await onSuccess?.call();
    } on Exception catch (e) {
      isError = true;
      exceptionMessage = e.getMessage;
    } catch (e) {
      isError = true;
      print(e);
    }

    if (isError) {
      try {
        generatingSnackbar?.close();
      } catch (e) {
        print(e);
      }

      String finalErrorMessage = errorMessage ?? "❌ Could not complete request!";
      if (appendError && exceptionMessage != null) {
        finalErrorMessage += "\nError: $exceptionMessage";
      }

      //Create a snackbar with the result message
      final completeSnackbar = SnackBar(
        content: Text(finalErrorMessage),
        backgroundColor: AppColors.dangerRed,
        duration: Duration(seconds: 5),
      );
      snackbarKey.currentState?.showSnackBar(completeSnackbar);
    }
  }

  static void showResultToast({
    required String message,
    Color? backgroundColor,
    Duration? duration,
    EdgeInsets? margin,
  }) {
    final completeSnackbar = SnackBar(
      margin: margin,
      content: Text(message),
      backgroundColor: backgroundColor ?? AppColors.dangerRed,
      duration: duration ?? Duration(seconds: 5),
    );
    snackbarKey.currentState?.showSnackBar(completeSnackbar);
  }
}

class PicaColors {}
