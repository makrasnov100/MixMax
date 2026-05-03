import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:mix_max/services/firebase/storage_service.dart';

enum OperationType { upload, download }

class NetworkTask {
  String id;
  String localPath;
  String cloudPath;
  double progress;
  bool isDone;
  bool isSuccessful;
  OperationType type;

  Completer<void> completer = Completer<void>();
  Function(String)? onError;

  void onDone({required bool isSuccessful}) {
    isDone = true;
    this.isSuccessful = isSuccessful;
    if (!isSuccessful) {
      onError?.call("Failed to perform operation");
    }
    completer.complete();
  }

  String getProgressPercentage() {
    double percentageProgress = progress * 100;
    return "${percentageProgress.toStringAsFixed(2)}%";
  }

  NetworkTask({
    required this.id,
    required this.localPath,
    required this.cloudPath,
    this.progress = 0,
    this.isDone = false,
    this.isSuccessful = false,
    this.onError,
    this.type = OperationType.upload,
  });
}

class NetworkQueueService with ChangeNotifier {
  Queue<NetworkTask> tasksQueue = Queue();
  NetworkTask? activeTask;

  Future<void> processTasks() async {
    while (tasksQueue.isNotEmpty) {
      activeTask = tasksQueue.removeFirst();
      notifyListeners();

      bool isSuccessful = false;
      try {
        bool isUpload = activeTask!.type == OperationType.upload;
        if (isUpload) {
          isSuccessful = await uploadToStorage(
            localPath: activeTask!.localPath,
            cloudPath: activeTask!.cloudPath,
            onProgress: (progress) {
              activeTask!.progress = progress;
              notifyListeners();
            },
          );
        } else {
          isSuccessful = await downloadFromStorage(
            localPath: activeTask!.localPath,
            cloudPath: activeTask!.cloudPath,
            onProgress: (progress) {
              activeTask!.progress = progress;
              notifyListeners();
            },
          );
        }
      } catch (e) {
        activeTask!.onError?.call(e.toString());
      }

      if (activeTask != null) {
        activeTask?.onDone(isSuccessful: isSuccessful);
        activeTask = null;
      }
    }
    notifyListeners();
  }

  void addTask(NetworkTask task) {
    tasksQueue.add(task);
    notifyListeners();

    if (activeTask == null) {
      processTasks();
    }
  }
}
