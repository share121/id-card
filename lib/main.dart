import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';
import 'package:system_theme/system_theme.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data.dart';
import 'widget/window_buttons.dart';

final isDesktop = !kIsWeb && GetPlatform.isDesktop;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isDesktop) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(450, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  SystemTheme.fallbackColor = Colors.blue;
  await SystemTheme.accentColor.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(Controller());
    return SystemThemeBuilder(builder: (context, accent) {
      return GetMaterialApp(
        title: '计算身份证',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: accent.accent),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: accent.accent,
            brightness: Brightness.dark,
          ),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh', 'CN'),
          Locale('en', 'US'),
        ],
        locale: const Locale('zh', 'CN'),
        fallbackLocale: const Locale('en', 'US'),
        home: const MyHomePage(),
        debugShowCheckedModeBanner: false,
      );
    });
  }
}

class MyHomePage extends GetView<Controller> {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isDesktop
            ? const DragToMoveArea(child: Text('计算身份证'))
            : const Text('计算身份证'),
        flexibleSpace:
            isDesktop ? const DragToMoveArea(child: SizedBox.expand()) : null,
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(
                  text: 'https://github.com/share121/id-card'));
              Get.rawSnackbar(
                title: '复制成功',
                message: 'https://github.com/share121/id-card',
                animationDuration: 500.ms,
              );
              await launchUrl(Uri.parse('https://github.com/share121/id-card'));
            },
            child: const Text('Github'),
          ),
          const SizedBox(width: 8),
          if (isDesktop) const WindowButtons(),
        ],
        elevation: 8,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Form(
                key: controller.idTextBoxKey,
                child: TextFormField(
                  onChanged: (e) {
                    if (controller.idTextBoxKey.currentState?.validate() ??
                        false) {
                      controller.idCard(e);
                    }
                  },
                  maxLength: 18,
                  decoration: const InputDecoration(
                    labelText: '身份证号',
                    hintText: '用 - 来代表你不知道的部分，不用输入校验码',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return '请输入身份证';
                    } else if (value!.length < 18) {
                      return '身份证长度不足';
                    } else {
                      return null;
                    }
                  },
                ),
              ),
              Column(
                children: [
                  Obx(() {
                    return RadioListTile(
                      value: '男',
                      title: const Text('男'),
                      groupValue:
                          controller.gender() == Gender.male ? '男' : null,
                      onChanged: (v) {
                        controller.gender(Gender.male);
                      },
                    );
                  }),
                  Obx(() {
                    return RadioListTile(
                      value: '女',
                      title: const Text('女'),
                      groupValue:
                          controller.gender() == Gender.female ? '女' : null,
                      onChanged: (v) {
                        controller.gender(Gender.female);
                      },
                    );
                  }),
                  Obx(() {
                    return RadioListTile(
                      value: '未知',
                      title: const Text('未知'),
                      groupValue:
                          controller.gender() == Gender.unknown ? '未知' : null,
                      onChanged: (v) {
                        controller.gender(Gender.unknown);
                      },
                    );
                  }),
                ],
              ),
              Obx(() => Text('有 ${controller.list.length} 个身份证')),
              Expanded(
                child: Obx(() {
                  return ListView.builder(
                    itemCount: controller.list.length,
                    itemBuilder: (context, index) {
                      return Obx(() {
                        final item = controller.list[index];
                        return ListTile(
                          title: Text(item),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: item));
                            Get.rawSnackbar(
                              title: '复制成功',
                              message: item,
                              animationDuration: 500.ms,
                            );
                          },
                        );
                      });
                    },
                  );
                }),
              ),
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: controller.list.join('\n')));
                  Get.rawSnackbar(
                    title: '复制成功',
                    message: '共 ${controller.list.length} 个身份证',
                    animationDuration: 500.ms,
                  );
                },
                child: const Text('复制全部'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
