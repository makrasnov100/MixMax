import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/services/ui/size_config.dart';
import 'package:mix_max/widgets/input/icon_button/icon_button.dart';
import 'package:mix_max/widgets/wrappers/bottom_drawer/bottom_drawer.dart';

class RenameExperimentDrawer extends StatefulWidget {
  static const int maxNameLength = 50;

  final String? initialName;
  final String title;
  final Function(String) onSave;

  const RenameExperimentDrawer({
    super.key,
    required this.onSave,
    this.initialName,
    this.title = 'Name Experiment',
  });

  @override
  State<RenameExperimentDrawer> createState() => _RenameExperimentDrawerState();
}

class _RenameExperimentDrawerState extends State<RenameExperimentDrawer> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    widget.onSave(name);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BottomDrawer(
      height: SizeConfig.safeBlockVertical * 30,
      title: widget.title,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  maxLength: RenameExperimentDrawer.maxNameLength,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(RenameExperimentDrawer.maxNameLength),
                  ],
                  style: TextStyle(
                    fontSize: SizeConfig.getFontSize(3.2),
                    color: AppColors.dark,
                    fontFamily: 'Roboto',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Experiment name',
                    hintStyle: TextStyle(
                      color: AppColors.grey,
                      fontSize: SizeConfig.getFontSize(3.2),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.safeBlockHorizontal * 3,
                      vertical: SizeConfig.safeBlockVertical * 1.2,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(SizeConfig.safeBlockHorizontal * 2),
                      borderSide: BorderSide(color: AppColors.lightGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(SizeConfig.safeBlockHorizontal * 2),
                      borderSide: BorderSide(color: AppColors.lightGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(SizeConfig.safeBlockHorizontal * 2),
                      borderSide: const BorderSide(color: AppColors.dark),
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.safeBlockVertical * 1.5),
                AppIconButton(
                  text: 'Save',
                  iconEnd: Icons.check,
                  color: AppColors.addGreen,
                  spaceOutside: true,
                  customButtonMargin: EdgeInsets.zero,
                  onPressed: _save,
                ),
                SizedBox(height: SizeConfig.safeBlockVertical * 1),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
