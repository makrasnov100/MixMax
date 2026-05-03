import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mix_max/services/firebase/format_exception_message.dart';

/// Run a cloud function that has standard response status and error properties as a response
/// @param {String} functionName - The name of the cloud function to run
/// @param {Map} input - The input to the cloud function
/// @param {Function} onSuccess - The function to run when the cloud function returns successfully
/// @param {Function} onError - The function to run when the cloud function returns an error
/// @returns {Future<boolean>} - A future that resolves to true if function ran successfully, false if it failed
Future<bool> runCloudFunction({
  required String functionName,
  Map<String, dynamic>? input,
  Function(String?, Map<String, dynamic>?)? onError,
  Function(Map<String, dynamic>?)? onSuccess,
  int timeoutSeconds = 60,
}) async {
  Map<String, dynamic>? response;
  try {
    HttpsCallable functionReference = FirebaseFunctions.instance.httpsCallable(
      functionName,
      options: HttpsCallableOptions(timeout: Duration(seconds: timeoutSeconds)),
    );
    final rawResponse = await functionReference.call(input);
    response = json.decode(json.encode(rawResponse.data)) as Map<String, dynamic>?;

    if (response == null) {
      throw Exception("Cloud function returned null");
    }

    String? error = response["error"] ?? response["message"];
    int? status = response["status"];

    if ((error != null && error.isNotEmpty) && status != 200) {
      throw Exception("$status - $error");
    } else {
      if (onSuccess != null) {
        onSuccess(response);
      }
      return true;
    }
  } on Exception catch (e) {
    print('Unable to complete $functionName: ${e.toString()}');
    if (onError != null) {
      onError(e.getMessage, response);
      return false;
    }
  } catch (e) {
    print('Unable to complete $functionName: ${e.toString()}');
    if (onError != null) {
      onError(e.toString(), response);
      return false;
    }
  }
  return false;
}
