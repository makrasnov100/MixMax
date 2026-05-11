import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/services/firebase/database_service.dart';
import 'package:mix_max/services/ui/app_colors.dart';
import 'package:mix_max/services/ui/size_config.dart';
import 'package:mix_max/widgets/input/icon_button/icon_button.dart';
import 'package:mix_max/widgets/text/normal_text.dart';
import 'package:mix_max/widgets/wrappers/bottom_drawer/bottom_drawer.dart';

class AddOutputDrawer extends StatefulWidget {
  final Function(SchemaOutcome) onSave;

  const AddOutputDrawer({super.key, required this.onSave});

  @override
  State<AddOutputDrawer> createState() => _AddOutputDrawerState();
}

class _AddOutputDrawerState extends State<AddOutputDrawer> {
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  OutcomeGoal? _goal;

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final id = DatabaseService.experimentsRef.doc().id;
    final outcome = SchemaOutcome(
      id: id,
      name: name,
      unit: _unitController.text.trim().isEmpty ? null : _unitController.text.trim(),
      min: double.tryParse(_minController.text),
      max: double.tryParse(_maxController.text),
      goal: _goal,
    );

    widget.onSave(outcome);
    Navigator.pop(context);
  }

  Widget _goalChip(OutcomeGoal goal, String label, IconData icon) {
    final selected = _goal == goal;
    return GestureDetector(
      onTap: () => setState(() => _goal = selected ? null : goal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.safeBlockHorizontal * 3,
          vertical: SizeConfig.safeBlockVertical * 1,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.dark : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(SizeConfig.safeBlockHorizontal * 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: SizeConfig.getFontSize(3.5),
              color: selected ? Colors.white : AppColors.dark,
            ),
            SizedBox(width: SizeConfig.safeBlockHorizontal * 1.5),
            NormalText(
              text: label,
              color: selected ? Colors.white : AppColors.dark,
              fontSize: SizeConfig.getFontSize(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: maxLength == null
          ? null
          : [LengthLimitingTextInputFormatter(maxLength)],
      style: TextStyle(
        fontSize: SizeConfig.getFontSize(3.2),
        color: AppColors.dark,
        fontFamily: 'Roboto',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.grey, fontSize: SizeConfig.getFontSize(3.2)),
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
    );
  }

  Widget _label(String text) => Padding(
        padding: EdgeInsets.only(bottom: SizeConfig.safeBlockVertical * 1),
        child: NormalText(text: text, color: AppColors.grey, fontSize: SizeConfig.getFontSize(3)),
      );

  @override
  Widget build(BuildContext context) {
    return BottomDrawer(
      height: SizeConfig.safeBlockVertical * 65,
      title: 'Add Output',
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(_nameController, 'Output name', maxLength: 50),
                SizedBox(height: SizeConfig.safeBlockVertical * 2.5),
                _field(_unitController, 'Unit (optional)  e.g. kg, ms, °C'),
                SizedBox(height: SizeConfig.safeBlockVertical * 2.5),
                _label('Goal'),
                Row(
                  children: [
                    _goalChip(OutcomeGoal.minimize, 'Minimize', Icons.arrow_downward),
                    SizedBox(width: SizeConfig.safeBlockHorizontal * 2),
                    _goalChip(OutcomeGoal.maximize, 'Maximize', Icons.arrow_upward),
                  ],
                ),
                SizedBox(height: SizeConfig.safeBlockVertical * 2.5),
                _label('Range (optional)'),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _minController,
                        'Min',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      ),
                    ),
                    SizedBox(width: SizeConfig.safeBlockHorizontal * 3),
                    Expanded(
                      child: _field(
                        _maxController,
                        'Max',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.safeBlockVertical * 2.5),
                AppIconButton(
                  text: 'Save',
                  iconEnd: Icons.check,
                  color: AppColors.actionOrange,
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
