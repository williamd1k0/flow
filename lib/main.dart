import 'dart:async';
import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

void main() {
  runApp(const FlowApp());
}

class FlowApp extends StatelessWidget {
  const FlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(
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
  int _rest_max = 0;
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
    return "${hour <= 1 ? "${fmt.format(hour)}:" : ""}${fmt.format(minutes)}:${hour <= 1 ? "${fmt.format(seconds)}" : ""}";
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
          _rest_max = _flow_time * _rest_ratio ~/ 1;
          _rest_time = _rest_max;
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
            CircularPercentIndicator(
              radius: 100.0,
              lineWidth: 10.0,
              percent:
                  _timer_mode == TimerMode.FLOW ? 0.0 : _rest_time / _rest_max,
              backgroundWidth: 5,
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
                    _timer_mode == TimerMode.FLOW ? "Flow time" : "Rest time",
                  ),
                ],
              ),
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
                          ? Icons.restore
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
