import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/empty_state.dart';

class NotFoundScreen extends StatelessWidget {
  final String? location;
  final Object? error;

  const NotFoundScreen({super.key, this.location, this.error});

  @override
  Widget build(BuildContext context) {
    final message = location == null || location!.isEmpty
        ? 'The page you are looking for does not exist.'
        : 'No route matches "$location".';

    return Scaffold(
      body: Responsive.centeredContent(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Page not found', style: AppText.h2(context)),
            const SizedBox(height: 12),
            EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Nothing here',
              message: message,
              action: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Back to dashboard'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Go back'),
                  ),
                  if (location != null && location!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: location!),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Route copied')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy route'),
                    ),
                  ],
                ],
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                'Error: $error',
                style: AppText.small(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
