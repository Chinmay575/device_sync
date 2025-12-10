import 'dart:io';

import 'package:bixat_key_mouse/bixat_key_mouse.dart';
import 'package:connect/src/domain/repositories/local_data_repository.dart';
import 'package:connect/src/domain/bloc/client/client_bloc.dart';
import 'package:connect/src/domain/repositories/notification_listener_repository.dart';
import 'package:connect/src/domain/repositories/notification_repository.dart';
import 'package:connect/src/presentation/home/views/remote_command_execution_page.dart';
import 'package:connect/src/presentation/home/views/remote_input_page.dart';
import 'package:connect/src/domain/bloc/server/server_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/app_route.dart';
import '../presentation/error/views/error_page.dart';
import '../presentation/home/views/home_page.dart';
import '../utils/constants/strings/routes.dart';

class AppRouter {
  static init() async {
    WidgetsFlutterBinding.ensureInitialized();

    // if (!Platform.isLinux) {
    //   await Firebase.initializeApp();
    // }

    if (!(Platform.isAndroid || Platform.isIOS)) {
      await BixatKeyMouse.initialize();
    }
    await LocalDataRepository.instance.initialize();
    if (Platform.isAndroid || Platform.isIOS) {
      // String? fcm = (await FirebaseMessaging.instance.getToken());
      // print("fcm token $fcm");

      await NotificationListenerRepository.instance.initialize();
    }
    await NotificationRepository.instance.initialize();
  }

  static List<AppRoute> _routes() => [
    .new(name: Routes.home, view: HomePage()),
    .new(name: Routes.remoteInput, view: RemoteInputPage()),
    .new(
      name: Routes.remoteCommandExecution,
      view: RemoteCommandExecutionPage(),
    ),
  ];

  static List allBlocProviders() => [
    BlocProvider(create: (_) => ServerBloc()..add(Initial()), lazy: false),
    BlocProvider(
      create: (_) => ClientBloc()..add(CheckPrevConnection()),
      lazy: false,
    ),
  ];

  static PageRoute onGenerateRoute(RouteSettings settings) {
    if (settings.name != null) {
      Iterable<AppRoute> result = _routes().where(
        (element) => element.name == settings.name,
      );

      if (result.isNotEmpty) {
        return MaterialPageRoute(builder: (context) => result.first.view);
      }
    }
    return MaterialPageRoute(builder: (context) => ErrorPage());
  }
}
