import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart' as intl;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const FlowApp());
}

class FlowApp extends StatelessWidget {
  const FlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData.light(useMaterial3: true),
      dark: ThemeData.dark(useMaterial3: true),
      initial: AdaptiveThemeMode.dark,
      builder: (theme, dark_theme) => MaterialApp(
        title: "Flow",
        theme: theme,
        darkTheme: dark_theme,
        home: const FlowTimerPage(),
      ),
    );
  }
}

class FlowTimerPage extends StatefulWidget {
  const FlowTimerPage({super.key});

  @override
  State<FlowTimerPage> createState() => _FlowTimerPageState();
}

class AppConfigs {
  double get rest_ratio => _data["flow.rest_ratio"]?.toDouble() ?? 20;
  void set rest_ratio(double val) {
    _data["flow.rest_ratio"] = val;
    _prefs.then((prefs) => prefs.setDouble("flow.rest_ratio", val));
  }

  bool get auto_start_rest => _data["flow.auto_start_rest"] ?? false;
  void set auto_start_rest(bool val) {
    _set_bool("flow.auto_start_rest", val);
  }

  bool get swap_flow_buttons => _data["flow.swap_flow_buttons"] ?? false;
  void set swap_flow_buttons(bool val) {
    _set_bool("flow.swap_flow_buttons", val);
  }

  bool get swap_rest_buttons => _data["flow.swap_rest_buttons"] ?? false;
  void set swap_rest_buttons(bool val) {
    _set_bool("flow.swap_rest_buttons", val);
  }

  void _set_bool(String key, bool val) {
    _data[key] = val;
    _prefs.then((prefs) => prefs.setBool(key, val));
  }

  void _set_double(String key, double val) {
    _data[key] = val;
    _prefs.then((prefs) => prefs.setDouble(key, val));
  }

  bool get theme_dark => _data["flow.theme_dark"] ?? true;
  void set theme_dark(bool val) {
    _data["flow.theme_dark"] = val;
    _prefs.then((prefs) => prefs.setBool("flow.theme_dark", val));
  }

  final Map<String, dynamic> _data = {};
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<void> init() async {
    final SharedPreferences prefs = await _prefs;
    _data["flow.rest_ratio"] =
        prefs.getDouble("flow.rest_ratio")?.toDouble() ?? 20;
    _data["flow.auto_start_rest"] =
        prefs.getBool("flow.auto_start_rest") ?? false;
    _data["flow.swap_flow_buttons"] =
        prefs.getBool("flow.swap_flow_buttons") ?? false;
    _data["flow.swap_rest_buttons"] =
        prefs.getBool("flow.swap_rest_buttons") ?? false;
  }
}

enum TimerMode {
  FLOW,
  REST,
}

enum TimerState {
  STOP,
  PAUSE,
  ACTIVE,
}

enum Page {
  TIMER,
  CONFIGS,
}

class _FlowTimerPageState extends State<FlowTimerPage> {
  final Duration _timer_interval = const Duration(seconds: 1);
  Timer? _timer;
  final AppConfigs configs = AppConfigs();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  int _flow_time = 0;
  int _rest_time = 0;
  int _rest_max = 0;
  TimerMode _timer_mode = TimerMode.FLOW;
  TimerState _timer_state = TimerState.STOP;
  Page page = Page.TIMER;

  @override
  void initState() {
    _timer = Timer.periodic(_timer_interval, (timer) {
      if (_timer_state == TimerState.ACTIVE) {
        update_time_spent(_timer_interval.inMilliseconds);
      }
    });
    const LinuxInitializationSettings notify_linux =
        LinuxInitializationSettings(defaultActionName: "Start Flow");
    const InitializationSettings notify_settings =
        InitializationSettings(linux: notify_linux);
    flutterLocalNotificationsPlugin.initialize(notify_settings,
        onDidReceiveNotificationResponse: (response) {
      if (_timer_mode == TimerMode.FLOW && _timer_state == TimerState.STOP) {
        _on_start_pressed();
      }
    });
    configs.init().then((value) => setState(() {}));
    super.initState();
  }

  void update_time_spent(int amount) {
    setState(() {
      _flow_time += amount;
      _rest_time = max(_rest_time - amount, 0);
      if (_timer_mode == TimerMode.REST &&
          _timer_state == TimerState.ACTIVE &&
          _rest_time <= 0) {
        _flow_time = 0;
        _timer_state = TimerState.STOP;
        _timer_mode = TimerMode.FLOW;
        flutterLocalNotificationsPlugin.show(
            0, "Rest is over!", "Let's get back to flow.", null);
      }
    });
  }

  String format_time(int time) {
    int seconds = time ~/ 1000;
    seconds = seconds % (24 * 3600);
    int hour = seconds ~/ 3600;
    seconds %= 3600;
    int minutes = seconds ~/ 60;
    seconds %= 60;
    intl.NumberFormat fmt = intl.NumberFormat("00");
    return "${fmt.format(hour)}:${fmt.format(minutes)}:${fmt.format(seconds)}";
  }

  void _on_start_pressed() {
    setState(() {
      switch (_timer_state) {
        case TimerState.ACTIVE:
          _timer_state = TimerState.PAUSE;
          break;
        case TimerState.PAUSE:
          _timer_state = TimerState.ACTIVE;
          break;
        case TimerState.STOP:
          switch (_timer_mode) {
            case TimerMode.FLOW:
              _flow_time = 0;
              _timer_state = TimerState.ACTIVE;
              break;
            case TimerMode.REST:
              _timer_state = TimerState.ACTIVE;
              break;
          }
      }
    });
  }

  void _on_next_pressed() {
    setState(() {
      switch (_timer_mode) {
        case TimerMode.FLOW:
          _timer_state = TimerState.STOP;
          _rest_max = _flow_time * (configs.rest_ratio / 100) ~/ 1;
          _rest_time = _rest_max;
          _timer_mode = TimerMode.REST;
          if (configs.auto_start_rest) {
            _timer_state = TimerState.ACTIVE;
          }
          break;
        case TimerMode.REST:
          _timer_state = TimerState.STOP;
          _flow_time = 0;
          _timer_mode = TimerMode.FLOW;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 5.0, left: 0.0),
        child: Row(children: [
          IconButton(
            onPressed: () => setState(() {
              page = page == Page.TIMER ? Page.CONFIGS : Page.TIMER;
            }),
            //backgroundColor: Colors.transparent,
            icon: Icon(
                page == Page.TIMER ? Icons.settings : Icons.arrow_back_ios_new),
          ),
          IconButton(
            onPressed: () {
              if (configs.theme_dark) {
                configs.theme_dark = false;
                AdaptiveTheme.of(context).setLight();
              } else {
                configs.theme_dark = true;
                AdaptiveTheme.of(context).setDark();
              }
            },
            icon: const Icon(Icons.dark_mode),
          )
        ]),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartTop,
      body: page == Page.TIMER
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularPercentIndicator(
                    radius: 94,
                    lineWidth: 12,
                    percent: _timer_mode == TimerMode.FLOW
                        ? 0.0
                        : _rest_time / _rest_max,
                    backgroundWidth: 8,
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: _timer_mode == TimerMode.FLOW
                        ? Colors.transparent
                        : Colors.green,
                    backgroundColor: Colors.black.withAlpha((255 * 0.2) ~/ 1),
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          format_time(_timer_mode == TimerMode.FLOW
                              ? _flow_time
                              : _rest_time),
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        Text(
                          _timer_mode == TimerMode.FLOW
                              ? "Flow time"
                              : "Rest time",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Directionality(
                    textDirection: _timer_mode == TimerMode.FLOW
                        ? (configs.swap_flow_buttons
                            ? TextDirection.ltr
                            : TextDirection.rtl)
                        : (configs.swap_rest_buttons
                            ? TextDirection.ltr
                            : TextDirection.rtl),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _timer_state == TimerState.ACTIVE
                            ? IconButton(
                                onPressed: _timer_mode == TimerMode.REST &&
                                        _rest_time <= 0
                                    ? null
                                    : _on_start_pressed,
                                icon: const Icon(Icons.pause),
                              )
                            : IconButton.filled(
                                onPressed: _timer_mode == TimerMode.REST &&
                                        _rest_time <= 0
                                    ? null
                                    : _on_start_pressed,
                                icon: const Icon(Icons.play_arrow),
                              ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed:
                              _timer_mode == TimerMode.FLOW && _flow_time <= 1
                                  ? null
                                  : _on_next_pressed,
                          icon: Icon(
                            _timer_mode == TimerMode.FLOW
                                ? Icons.restore
                                : Icons.skip_next,
                          ),
                          label: Text(
                              _timer_mode == TimerMode.FLOW ? "Rest" : "Skip"),
                        )
                      ],
                    ),
                  )
                ],
              ),
            )
          : Column(
              children: [
                const SizedBox(height: 45),
                Expanded(
                  child: ListView(
                    children: [
                      SwitchListTile(
                        value: configs.auto_start_rest,
                        title: const Text("Autostart Rest timer"),
                        subtitle: const Text(
                            "Automatically start the timer when Rest is pressed."),
                        onChanged: (enabled) => setState(
                          () {
                            configs.auto_start_rest = enabled;
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text("Rest timer factor"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                                "The percentage of Flow time that will be used as Rest time."),
                            Slider(
                              value: configs.rest_ratio,
                              secondaryTrackValue: 20,
                              min: 1,
                              max: 100,
                              divisions: 99,
                              label: "${configs.rest_ratio.round()}%",
                              onChanged: (value) => setState(() {
                                configs.rest_ratio = value.round() * 1;
                              }),
                            ),
                          ],
                        ),
                        trailing: Text("${configs.rest_ratio.round()}%"),
                      ),
                      const Divider(),
                      SwitchListTile(
                        value: configs.swap_flow_buttons,
                        title: const Text("Swap Flow buttons"),
                        onChanged: (enabled) => setState(
                          () {
                            configs.swap_flow_buttons = enabled;
                          },
                        ),
                      ),
                      SwitchListTile(
                        value: configs.swap_rest_buttons,
                        title: const Text("Swap Rest buttons"),
                        onChanged: (enabled) => setState(
                          () {
                            configs.swap_rest_buttons = enabled;
                          },
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
