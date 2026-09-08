import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:flutter/src/widgets/_window.dart";

import 'window_decorations.dart';

/// Quits the application once the only window has gone away.
///
/// Destroying a window doesn't end the process by itself, so without this the
/// app keeps running in the background after its last window is closed.
class MainWindowDelegate with WindowControllerDelegate {
  @override
  void onWindowDestroyed() {
    super.onWindowDestroyed();
    ServicesBinding.instance.exitApplication(AppExitType.required);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runWidget(const MyWindow());
}

class MyWindow extends StatefulWidget {
  const MyWindow({super.key});

  @override
  State<MyWindow> createState() => _WindowState();
}

class _WindowState extends State<MyWindow> {
  WindowController controller = WindowController(
    size: Size(400, 400),
    title: 'Flutter Window',
    delegate: MainWindowDelegate(),
  );

  @override
  Widget build(BuildContext context) {
    return ViewCollection(
      views: [
        Window(
          controller: controller,
          child: const WindowDecorations(child: MyApp()),
        ),
      ],
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
