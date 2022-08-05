import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_provider.dart';
import '../../setting/setting_screen.dart';

class UserProfileAppBar extends StatelessWidget {
  const UserProfileAppBar(this.userId, {super.key});

  /// Current displayed user.
  final String userId;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      actions: [
        _AutoGeneratedAction(userId),
      ],
    );
  }
}

/// Auto generated action.
class _AutoGeneratedAction extends ConsumerWidget {
  const _AutoGeneratedAction(this.userId);

  /// Current displayed user.
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If profile user is same as authenticated user, show settings button.
    if (authenticatedProvider.same(ref.watch, userId)) {
      return const _SettingsButton();
    }

    // If profile user is not same as authenticated user, show more button.
    return _MoreButton(userId);
  }
}

/// Settings button.
class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.crop_square),
      onPressed: () => _jumpToSettingScreen(context),
    );
  }

  /// Jump to setting screen.
  void _jumpToSettingScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext context) => const SettingScreen(),
    ));
  }
}

/// More button.
class _MoreButton extends StatelessWidget {
  const _MoreButton(this.userId);

  /// Current displayed user.
  final String userId;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.more_horiz),
      onPressed: () {
        // TODO : implement more
      },
    );
  }
}