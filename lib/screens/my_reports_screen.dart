import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'report_condition_step1_screen.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  void _createReport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ReportConditionStep1Screen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),

              const Icon(
                Icons.report_outlined,
                size: 70,
                color: AppColors.grey600,
              ),

              const SizedBox(height: AppSpacing.md),

              const Text(
                'Condition Reports',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              const Text(
                'Help other passengers by reporting the condition '
                'of buses, stations and rest areas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: AppColors.grey600,
                ),
              ),

              const Spacer(),

              ElevatedButton.icon(
                onPressed: () => _createReport(context),
                icon: const Icon(Icons.add),
                label: const Text('REPORT A CONDITION'),
              ),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}