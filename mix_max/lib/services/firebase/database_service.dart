import 'package:cloud_firestore/cloud_firestore.dart';
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
}
