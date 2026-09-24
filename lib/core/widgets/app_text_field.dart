import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/typography.dart';

/// The design's text input (login / OTP / password kit).
///
/// Idle: white fill, 1px `#D9D9D9` border, radius 10.
/// Focused: `#FBF6F1` fill + 2px maroon inset border (transparent outer).
///
/// Focus is purely visual local state, so this is a [StatefulWidget].
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.controller,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.hintText,
    this.textAlign = TextAlign.start,
    this.maxLength,
    this.letterSpacing,
    this.fontSize = 16,
    this.useLatinFont = false,
    this.fontWeight = FontWeight.w400,
    this.height = AppDimens.controlH,
    this.inputFormatters,
    this.prefixText,
  });

  final String? label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? hintText;
  final TextAlign textAlign;
  final int? maxLength;
  final double? letterSpacing;
  final double fontSize;

  /// A fixed, non-editable prefix rendered inside the field (e.g. `"+91"` on
  /// a phone-only field) — so the poojari types just the local number and
  /// never has to guess whether the country code belongs in the box.
  final String? prefixText;

  /// Use Roboto (for phone numbers / OTP digits) instead of Malayalam.
  final bool useLatinFont;
  final FontWeight fontWeight;
  final double height;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  TextStyle get _textStyle => widget.useLatinFont
      ? AppText.latin(
          size: widget.fontSize,
          weight: widget.fontWeight,
          color: AppColors.ink,
          letterSpacing: widget.letterSpacing,
        )
      : AppText.malayalam(
          size: widget.fontSize,
          weight: widget.fontWeight,
          color: AppColors.ink,
          letterSpacing: widget.letterSpacing,
        );

  @override
  Widget build(BuildContext context) {
    final field = Container(
      height: widget.height.h,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: _focused ? AppColors.creamInput : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.login.r),
        border: Border.all(
          color: _focused ? AppColors.maroon : AppColors.border,
          width: _focused ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textAlign: widget.textAlign,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        cursorColor: AppColors.maroon,
        style: _textStyle,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          counterText: '',
          hintText: widget.hintText,
          hintStyle: _textStyle.copyWith(color: AppColors.grayPlaceholder),
          prefixText: widget.prefixText == null
              ? null
              : '${widget.prefixText} ',
          prefixStyle: _textStyle,
        ),
      ),
    );

    if (widget.label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label!,
          style: AppText.malayalam(size: 14, color: AppColors.ink),
        ),
        SizedBox(height: 8.h),
        field,
      ],
    );
  }
}
