import 'package:flutter/material.dart';

class PrimaryScaffold extends StatelessWidget {
  const PrimaryScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.showBack = true,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!),
              automaticallyImplyLeading: showBack,
              actions: actions,
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: body,
        ),
      ),
    );
  }
}
