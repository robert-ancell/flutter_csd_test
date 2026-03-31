import 'package:flutter/material.dart';
import "package:flutter/src/widgets/_window.dart";

void main() {
  runWidget(const Window());
}

class Window extends StatefulWidget {
  const Window({super.key});

  @override
  State<Window> createState() => _WindowState();
}

class _WindowState extends State<Window> {
  RegularWindowController controller = RegularWindowController(
    preferredSize: Size(400, 400),
    decorated: false,
    backgroundColor: Colors.transparent,
  );

  @override
  Widget build(BuildContext context) {
    return ViewCollection(
      views: [
        RegularWindow(
          controller: controller,
          child: const WindowDecorations(child: const MyApp()),
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

class WindowDecorations extends StatelessWidget {
  final Widget child;

  const WindowDecorations({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return WindowShadows(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            TitleBar(
              title: "Flutter Window",
              onClose: () {
                return;
              },
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class TitleBar extends StatelessWidget {
  final String title;
  final void Function()? onClose;

  const TitleBar({super.key, required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Container(
        color: Colors.blueGrey,
        padding: const EdgeInsets.all(4),
        child: Row(
          children: <Widget>[
            Expanded(child: WindowTitle(title: title)),
            WindowCloseButton(onClose: onClose),
          ],
        ),
      ),
    );
  }
}

class WindowTitle extends StatelessWidget {
  final String title;

  const WindowTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, textAlign: TextAlign.center);
  }
}

class WindowCloseButton extends StatelessWidget {
  final void Function()? onClose;

  const WindowCloseButton({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: TextButton(
        onPressed: onClose,
        style: TextButton.styleFrom(foregroundColor: Colors.white),
        child: const Icon(Icons.close, size: 16),
      ),
    );
  }
}

class WindowShadows extends StatelessWidget {
  final Widget child;
  final double borderWidth;

  const WindowShadows({super.key, required this.child, this.borderWidth = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderWidth),
        border: Border.all(width: borderWidth, color: Colors.transparent),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: borderWidth, color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: borderWidth,
              spreadRadius: -borderWidth * 0.5,
            ),
          ],
        ),
        child: child,
      ),
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
