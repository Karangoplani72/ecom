import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.leading,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(leading: leading, title: Text(title!), actions: actions),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
