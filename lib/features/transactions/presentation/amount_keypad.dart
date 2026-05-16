import 'package:flutter/material.dart';

class AmountKeypad extends StatelessWidget {
  const AmountKeypad({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '000', '0', '⌫'];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.8,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        return OutlinedButton(
          onPressed: () {
            if (key == '⌫') {
              if (value.isNotEmpty) {
                onChanged(value.substring(0, value.length - 1));
              }
              return;
            }
            final next = value == '0' ? key : '$value$key';
            onChanged(next.replaceFirst(RegExp(r'^0+'), ''));
          },
          child: Text(key,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        );
      },
    );
  }
}
