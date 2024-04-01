import 'dart:async';
import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const FlowApp());
}

class FlowApp extends StatelessWidget {
  const FlowApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        //colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const FlowTimerPage(),
    );
  }
}

class FlowTimerPage extends StatefulWidget {
  const FlowTimerPage({super.key});

  @override
  State<FlowTimerPage> createState() => _FlowTimerPageState();
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

class _FlowTimerPageState extends State<FlowTimerPage> {
  final Duration _timer_interval = Duration(milliseconds: 50);
  Timer? _timer;

  int _flow_time = 0;
  int _rest_time = 0;
  double _rest_ratio = 0.25;
  TimerMode _timer_mode = TimerMode.FLOW;
  TimerState _timer_state = TimerState.STOP;

  @override
  void initState() {
    _timer = Timer.periodic(_timer_interval, (timer) {
      if (_timer_state == TimerState.ACTIVE) {
        update_time_spent(_timer_interval.inMilliseconds);
      }
    });
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
        // TODO: Notify
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
    NumberFormat fmt = NumberFormat("00");
    return "${hour >= 1 ? "${fmt.format(hour)}:" : ""}${fmt.format(minutes)}:${fmt.format(seconds)}";
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
          _rest_time = _flow_time * _rest_ratio ~/ 1;
          _timer_mode = TimerMode.REST;
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
      //appBar: AppBar(
      // title: Text(widget.title),
      //   ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _timer_mode == TimerMode.FLOW ? "Flow time" : "Rest time",
            ),
            Text(
              format_time(
                  _timer_mode == TimerMode.FLOW ? _flow_time : _rest_time),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _timer_state == TimerState.ACTIVE
                    ? IconButton(
                        onPressed:
                            _timer_mode == TimerMode.REST && _rest_time <= 0
                                ? null
                                : _on_start_pressed,
                        icon: Icon(Icons.pause))
                    : IconButton.filled(
                        onPressed:
                            _timer_mode == TimerMode.REST && _rest_time <= 0
                                ? null
                                : _on_start_pressed,
                        icon: Icon(Icons.play_arrow),
                      ),
                SizedBox(width: 10),
                OutlinedButton.icon(
                    onPressed: _timer_mode == TimerMode.FLOW && _flow_time <= 1
                        ? null
                        : _on_next_pressed,
                    icon: Icon(
                      _timer_mode == TimerMode.FLOW
                          ? Icons.skip_next
                          : Icons.skip_next,
                    ),
                    label:
                        Text(_timer_mode == TimerMode.FLOW ? "Rest" : "Skip"))
              ],
            )
          ],
        ),
      ),
    );
  }
}
