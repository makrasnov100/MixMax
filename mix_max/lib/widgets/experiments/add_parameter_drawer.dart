import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/services/firebase/database_service.dart';
import 'package:mix_max/services/ui/app_colors.dart';
import 'package:mix_max/services/ui/size_config.dart';
import 'package:mix_max/widgets/input/icon_button/icon_button.dart';
import 'package:mix_max/widgets/text/normal_text.dart';
import 'package:mix_max/widgets/wrappers/bottom_drawer/bottom_drawer.dart';

class AddParameterDrawer extends StatefulWidget {
  final Function(SchemaParameter) onSave;

  const AddParameterDrawer({super.key, required this.onSave});

  @override
  State<AddParameterDrawer> createState() => _AddParameterDrawerState();
}

class _AddParameterDrawerState extends State<AddParameterDrawer> {
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  final _optionController = TextEditingController();
  final _itemController = TextEditingController();

  ParameterType? _selectedType;
  final List<String> _options = [];
  final List<String> _items = [];

  static const List<String> _durationUnits = ['seconds', 'minutes', 'hours'];
  String _durationUnit = 'minutes';

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _optionController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedType == null) return;

    final id = DatabaseService.experimentsRef.doc().id;
    final isDuration = _selectedType == ParameterType.duration;
    final unit = isDuration
        ? _durationUnit
        : (_unitController.text.trim().isEmpty ? null : _unitController.text.trim());
    final parameter = SchemaParameter(
      id: id,
      name: name,
      type: _selectedType,
      unit: unit,
      min: double.tryParse(_minController.text),
      max: double.tryParse(_maxController.text),
      options: _options.isEmpty ? null : List.from(_options),
      items: _items.isEmpty ? null : List.from(_items),
    );

    widget.onSave(parameter);
    Navigator.pop(context);
  }

  Widget _typeChip(ParameterType type, String label, IconData icon) {
    final selected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
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

  Widget _field(TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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

  Widget _chipListInput(List<String> list, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (list.isNotEmpty) ...[
          Wrap(
            spacing: SizeConfig.safeBlockHorizontal * 2,
            runSpacing: SizeConfig.safeBlockVertical * 0.8,
            children: list
                .map(
                  (item) => Chip(
                    label: NormalText(
                      text: item,
                      color: AppColors.dark,
                      fontSize: SizeConfig.getFontSize(2.8),
                    ),
                    backgroundColor: AppColors.lightGrey,
                    deleteIcon: Icon(Icons.close, size: SizeConfig.getFontSize(3)),
                    onDeleted: () => setState(() => list.remove(item)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.symmetric(horizontal: SizeConfig.safeBlockHorizontal * 1),
                    side: BorderSide.none,
                  ),
                )
                .toList(),
          ),
          SizedBox(height: SizeConfig.safeBlockVertical * 1),
        ],
        Row(
          children: [
            Expanded(child: _field(controller, hint)),
            SizedBox(width: SizeConfig.safeBlockHorizontal * 2),
            GestureDetector(
              onTap: () {
                final val = controller.text.trim();
                if (val.isEmpty) return;
                setState(() {
                  list.add(val);
                  controller.clear();
                });
              },
              child: Container(
                padding: EdgeInsets.all(SizeConfig.safeBlockHorizontal * 2.8),
                decoration: BoxDecoration(
                  color: AppColors.dark,
                  borderRadius: BorderRadius.circular(SizeConfig.safeBlockHorizontal * 2),
                ),
                child: Icon(Icons.add, color: Colors.white, size: SizeConfig.getFontSize(4)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: EdgeInsets.only(bottom: SizeConfig.safeBlockVertical * 1),
        child: NormalText(text: text, color: AppColors.grey, fontSize: SizeConfig.getFontSize(3)),
      );

  Widget _durationUnitDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.safeBlockHorizontal * 3,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SizeConfig.safeBlockHorizontal * 2),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _durationUnit,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: AppColors.dark),
          style: TextStyle(
            fontSize: SizeConfig.getFontSize(3.2),
            color: AppColors.dark,
            fontFamily: 'Roboto',
          ),
          items: _durationUnits
              .map(
                (u) => DropdownMenuItem<String>(
                  value: u,
                  child: NormalText(
                    text: u,
                    color: AppColors.dark,
                    fontSize: SizeConfig.getFontSize(3.2),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val == null) return;
            setState(() => _durationUnit = val);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomDrawer(
      height: SizeConfig.safeBlockVertical * 75,
      title: 'Add Parameter',
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(_nameController, 'Parameter name'),
                SizedBox(height: SizeConfig.safeBlockVertical * 2.5),
                _label('Type'),
                Wrap(
                  spacing: SizeConfig.safeBlockHorizontal * 2,
                  runSpacing: SizeConfig.safeBlockVertical * 1,
                  children: [
                    _typeChip(ParameterType.number, 'Number', Icons.tag),
                    _typeChip(ParameterType.duration, 'Duration', Icons.timer_outlined),
                    _typeChip(ParameterType.toggle, 'Toggle', Icons.toggle_on_outlined),
                    _typeChip(ParameterType.choice, 'Choice', Icons.list_outlined),
                    _typeChip(ParameterType.order, 'Order', Icons.swap_vert),
                  ],
                ),
                if (_selectedType == ParameterType.number) ...[
                  SizedBox(height: SizeConfig.safeBlockVertical * 2.5),
                  _field(_unitController, 'Unit (optional)  e.g. g, °C, ml'),
                  SizedBox(height: SizeConfig.safeBlockVertical * 1),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          _minController,
                          'Min (optional)',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        ),
                      ),
                      SizedBox(width: SizeConfig.safeBlockHorizontal * 3),
                      Expanded(
                        child: _field(
                          _maxController,
                          'Max (optional)',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_selectedType == ParameterType.duration) ...[
                  SizedBox(height: SizeConfig.safeBlockVertical * 2.5),
                  _label('Unit'),
                  _durationUnitDropdown(),
                  SizedBox(height: SizeConfig.safeBlockVertical * 2),
                  _label('Range (optional)'),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          _minController,
                          'Min',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      SizedBox(width: SizeConfig.safeBlockHorizontal * 3),
                      Expanded(
                        child: _field(
                          _maxController,
                          'Max',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_selectedType == ParameterType.choice) ...[
                  SizedBox(height: SizeConfig.safeBlockVertical * 2.5),
                  _label('Options'),
                  _chipListInput(_options, _optionController, 'Add option'),
                ],
                if (_selectedType == ParameterType.order) ...[
                  SizedBox(height: SizeConfig.safeBlockVertical * 2.5),
                  _label('Steps'),
                  _chipListInput(_items, _itemController, 'Add step'),
                ],
                SizedBox(height: SizeConfig.safeBlockVertical * 2.5),
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
