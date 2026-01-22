import 'package:app_bhb/common_widget/round_textfield.dart';
import 'package:flutter/material.dart';

class NewRoundSelectField extends StatefulWidget {
  final String hintText;
  final List<String> options;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool isPadding;
  final Widget? rightIcon;
  final IconData? icon;
  final bool readOnly;
  final void Function(String?)? onChanged;
  final bool enableSearch;

  const NewRoundSelectField({
    super.key,
    required this.hintText,
    required this.options,
    this.controller,
    this.validator,
    this.isPadding = true,
    this.rightIcon,
    this.icon,
    this.readOnly = false,
    this.onChanged,
    this.enableSearch = false,
  });

  @override
  State<NewRoundSelectField> createState() => _NewRoundSelectFieldState();
}

class _NewRoundSelectFieldState extends State<NewRoundSelectField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  String? _selectedValue;
  List<String> _filteredOptions = [];
  final TextEditingController _searchController = TextEditingController();

  bool _isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  @override
  void initState() {
    super.initState();
    _filteredOptions = [...widget.options];

    if (widget.controller != null && widget.controller!.text.isNotEmpty) {
      _selectedValue = widget.controller!.text;
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleDropdown() {
    if (widget.readOnly) return;

    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    } else {
      _removeOverlay();
    }
  }
  @override
  void didUpdateWidget(covariant NewRoundSelectField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.options != widget.options) {
      setState(() {
        _filteredOptions = [...widget.options];
      });
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    final screenHeight = MediaQuery.of(context).size.height;
    final dropdownHeight = 250.0;

    final spaceBelow =
        screenHeight - offset.dy - size.height;
    final spaceAbove = offset.dy;

    final showAbove = spaceBelow < dropdownHeight && spaceAbove > spaceBelow;

    return OverlayEntry(
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _removeOverlay,
          child: Stack(
            children: [
              Positioned(
                width: size.width,
                left: offset.dx,
                top: showAbove
                    ? offset.dy - dropdownHeight - 5
                    : offset.dy + size.height + 5,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: dropdownHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _buildDropdownContent(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildDropdownContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.enableSearch)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child:
              NewRoundTextField(
                hintText: 'بحث...',
                controller: _searchController,
                isPadding: false,
                minLines: 1,
                maxLines: 1,
                right: const Icon(Icons.search_off, color: Colors.grey),
                onChanged: (value) {
                  _filteredOptions = widget.options
                      .where((e) =>
                      e.toLowerCase().contains(value.toLowerCase()))
                      .toList();

                  _overlayEntry?.markNeedsBuild();
                },
              ),

            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _filteredOptions.length,
            itemBuilder: (context, index) {
              final option = _filteredOptions[index];
              final isArabic = _isArabic(option);

              return ListTile(
                title: Directionality(
                  textDirection:
                  isArabic ? TextDirection.rtl : TextDirection.ltr,
                  child: Align(
                    alignment: isArabic
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Text(
                      option,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedValue = option;
                    widget.controller?.text = option;
                    widget.onChanged?.call(option);
                  });
                  _removeOverlay();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
    widget.readOnly ? Colors.grey.shade200 : Colors.white;
    final borderColor =
    widget.readOnly ? Colors.grey.shade400 : Colors.black12;

    return FormField<String>(
      validator: widget.validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: GestureDetector(
                onTap: _toggleDropdown,
                child: Container(
                  height: 60,
                  margin: EdgeInsets.symmetric(
                      horizontal: widget.isPadding ? 20 : 0),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: state.hasError ? Colors.red : borderColor),
                    boxShadow: widget.readOnly
                        ? null
                        : const [
                      BoxShadow(
                          color: Colors.black12, blurRadius: 2)
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedValue ?? widget.hintText,
                          textAlign:
                          _isArabic(_selectedValue ?? widget.hintText)
                              ? TextAlign.right
                              : TextAlign.left,
                          style: TextStyle(
                            color: _selectedValue == null
                                ? Colors.black54
                                : Colors.black,
                            fontSize: 17,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                      Icon(
                        widget.rightIcon != null
                            ? (widget.rightIcon as Icon).icon
                            : Icons.arrow_drop_down,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(right: 25, top: 4),
                child: Text(
                  state.errorText!,
                  textDirection: TextDirection.rtl,
                  style:
                  const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}
