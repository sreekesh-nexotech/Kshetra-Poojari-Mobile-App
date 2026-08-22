import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';

/// The rare Noto Serif Malayalam bold-12 section label
/// ("വരും ദിവസങ്ങൾ", "ഈ മാസം — സെപ്റ്റംബർ", tally titles).
class KsSectionLabel extends StatelessWidget {
  const KsSectionLabel(this.text, {super.key, this.color = AppColors.black});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppText.serif(color: color));
  }
}
