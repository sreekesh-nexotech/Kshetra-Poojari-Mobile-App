import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/widgets/ks_temple_background.dart';
import '../components/attendance_card.dart';
import '../components/home_greeting_card.dart';
import '../components/overall_progress_card.dart';
import '../components/today_tally_table.dart';
import '../components/upcoming_days_row.dart';

/// Home tab — today's overview: greeting, attendance, progress, tally, upcoming.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const KsTempleBackground(flipped: true),
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 36.h, 16.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HomeGreetingCard(),
                SizedBox(height: 12.h),
                const AttendanceCard(),
                SizedBox(height: 12.h),
                const OverallProgressCard(),
                SizedBox(height: 12.h),
                const TodayTallyTable(),
                SizedBox(height: 12.h),
                const UpcomingDaysRow(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
