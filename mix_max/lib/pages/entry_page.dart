import 'package:flutter/material.dart';
import 'package:mix_max/widgets/wrappers/orientation_scaffold.dart';

class EntryPage extends StatelessWidget {
  const EntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OrientationScaffold(body: Column(children: const [Text("Go Build It!")]));
  }
}
