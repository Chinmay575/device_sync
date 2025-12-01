
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'src/config/router.dart';
import 'src/utils/constants/strings/routes.dart';

void main() async {
  await AppRouter.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [...AppRouter.allBlocProviders()],
      child: ScreenUtilInit(
        designSize: const Size(1080, 1920),
        child: MaterialApp(
          title: 'Flutter',
          debugShowCheckedModeBanner: false,
          onGenerateRoute: AppRouter.onGenerateRoute,
          initialRoute: Routes.home,
        ),
      ),
    );
  }
}


