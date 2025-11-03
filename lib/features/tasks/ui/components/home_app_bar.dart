import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/weekly_task_bloc.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('CoupleS'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () =>
              context.read<WeeklyTaskBloc>().add(const RefreshWeeklyTasks()),
          tooltip: 'Refresh',
        ),
        // IconButton(
        //   icon: const Icon(Icons.logout),
        //   onPressed: () async {
        //     await Supabase.instance.client.auth.signOut();
        //     if (context.mounted) context.go('/');
        //   },
        // ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
