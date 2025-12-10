import 'package:connect/src/domain/bloc/client/client_bloc.dart';
import 'package:connect/src/utils/constants/strings/enums.dart';
import 'package:connect/src/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RemoteCommandExecutionPage extends StatelessWidget {
  const RemoteCommandExecutionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        width: context.width,
        child: Column(
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: .center,
                alignment: .center,
                spacing: 16,
                runSpacing: 16,
                children: RemoteCommand.values
                    .map((e) => _GridTile(command: e))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({required this.command});

  final RemoteCommand command;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<ClientBloc>().add(RemoteCommandExecute(command: command));
      },
      child: SizedBox(
        height: 160,
        width: 160,
        child: Card(
          elevation: 4,
          margin: .zero,
          child: Column(
            crossAxisAlignment: .center,
            mainAxisAlignment: .center,
            children: [
              Icon(command.icon, size: 32),
              SizedBox(height: 16),
              Text(command.name),
            ],
          ),
        ),
      ),
    );
  }
}
