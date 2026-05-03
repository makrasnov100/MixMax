import 'dart:async';
import 'dart:io';
import 'package:http/http.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Downloads a zip archive from the given [url] and saves it to the given [path].
Future<bool> downloadFromUrl({
  required String url,
  required String filepath,
  Function(double)? onProgress,
}) async {
  try {
    int total = 1;
    int received = 0;
    File file = File(filepath);
    List<int> bytes = [];

    StreamedResponse response = await Client().send(Request('GET', Uri.parse(url)));
    total = response.contentLength ?? 1;

    Completer<bool> downloadCompleter = Completer<bool>();

    response.stream.listen((value) {
      bytes.addAll(value);
      received += value.length;
      onProgress?.call(received / total);
    }).onDone(() async {
      await file.writeAsBytes(bytes);
      downloadCompleter.complete(true);
    });

    return await downloadCompleter.future;
  } catch (e) {
    print(e);
    return false;
  }
}

Future<bool> downloadFromStorage({
  required String localPath,
  required String cloudPath,
  Function(double)? onProgress,
}) async {
  try {
    final storageRef = FirebaseStorage.instance.ref();
    final fileStorageRef = storageRef.child(cloudPath);
    final newFile = File(localPath);

    // Create the file directory if it does not exist
    if (!newFile.parent.existsSync()) {
      newFile.parent.createSync(recursive: true);
    }

    Completer<bool> downloadCompleter = Completer<bool>();
    final downloadTask = fileStorageRef.writeToFile(newFile);

    final subscription = downloadTask.snapshotEvents.listen((taskSnapshot) {
      switch (taskSnapshot.state) {
        case TaskState.running:
          onProgress?.call(taskSnapshot.bytesTransferred / taskSnapshot.totalBytes);
          break;
        case TaskState.paused:
          break;
        case TaskState.success:
          break;
        case TaskState.canceled:
          break;
        case TaskState.error:
          break;
      }
    });

    await downloadTask.then((result) {
      downloadCompleter.complete(true);
    }).catchError((result) {
      downloadCompleter.complete(false);
    });

    subscription.cancel();
    return await downloadCompleter.future;
  } catch (e) {
    print(e);
    return false;
  }
}

Future<bool> uploadToStorage({
  required String localPath,
  required String cloudPath,
  Function(double)? onProgress,
}) async {
  try {
    //Check the file to exists before uploading
    File file = File(localPath);
    if (!(await file.exists())) {
      return false;
    }

    final storageRef = FirebaseStorage.instance.ref();
    final backupStorageRef = storageRef.child(cloudPath);
    Completer<bool> uploadCompleter = Completer<bool>();
    try {
      final uploadTask = backupStorageRef.putFile(file);

      final subscription = uploadTask.snapshotEvents.listen((taskSnapshot) {
        switch (taskSnapshot.state) {
          case TaskState.running:
            onProgress?.call(taskSnapshot.bytesTransferred / taskSnapshot.totalBytes);
            break;
          case TaskState.paused:
            break;
          case TaskState.success:
            break;
          case TaskState.canceled:
            break;
          case TaskState.error:
        }
      });

      await uploadTask.then((result) {
        uploadCompleter.complete(true);
      }).catchError((result) {
        uploadCompleter.complete(false);
      });
      subscription.cancel();
    } on FirebaseException catch (e) {
      uploadCompleter.complete(false);
      print(e);
    }

    return await uploadCompleter.future;
  } catch (e) {
    print(e);
    return false;
  }
}
