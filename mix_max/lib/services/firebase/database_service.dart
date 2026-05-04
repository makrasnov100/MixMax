import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/user.dart';

class DatabaseService {
  static final usersRef = FirebaseFirestore.instance
      .collection('Users')
      .withConverter<SchemaUser>(
        fromFirestore: (snapshot, _) {
          Map<String, dynamic>? data = snapshot.data();

          if (data != null) {
            return SchemaUser.fromJson(data);
          } else {
            return SchemaUser.unknown();
          }
        },
        toFirestore: (user, _) => user.toJson(),
      );

  static final experimentsRef = FirebaseFirestore.instance
      .collection('Experiments')
      .withConverter<SchemaExperiment>(
        fromFirestore: (snapshot, _) {
          Map<String, dynamic>? data = snapshot.data();

          if (data != null) {
            return SchemaExperiment.fromJson(data);
          } else {
            return SchemaExperiment.unknown();
          }
        },
        toFirestore: (experiment, _) => experiment.toJson(),
      );
}
