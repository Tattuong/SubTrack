import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_ui.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FtrScaffold(
      appBar: AppBar(title: Text(AppStrings.t(context, 'privacyPolicy'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(AppStrings.t(context, 'privacyPolicyTitle'), style: AppTypography.title(size: 20, context: context)),
          const SizedBox(height: 12),
          Text(AppStrings.t(context, 'privacyPolicyBody'), style: AppTypography.body(size: 14, context: context)),
        ],
      ),
    );
  }
}
