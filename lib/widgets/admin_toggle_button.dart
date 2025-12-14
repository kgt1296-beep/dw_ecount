import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';

class AdminToggleButton extends StatelessWidget {
  const AdminToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return IconButton(
      tooltip: appState.isAdmin ? '관리자 모드 해제' : '관리자 모드',
      icon: Icon(
        appState.isAdmin ? Icons.lock_open : Icons.lock_outline,
      ),
      onPressed: () async {
        if (appState.isAdmin) {
          appState.disableAdmin();
          return;
        }

        final controller = TextEditingController();

        final ok = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('관리자 모드'),
              content: TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      controller.text == 'dw2025',
                    );
                  },
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );

        if (ok == true) {
          appState.enableAdmin();
        }
      },
    );
  }
}
