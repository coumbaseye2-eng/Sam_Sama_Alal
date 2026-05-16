import 'package:flutter/material.dart';

class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.value,
    required this.onChanged,
    this.onSubmit,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'Effacer',
      '0',
      'OK'
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        final isAction = key == 'Effacer' || key == 'OK';
        return OutlinedButton(
          onPressed: () {
            if (key == 'Effacer') {
              if (value.isNotEmpty) {
                onChanged(value.substring(0, value.length - 1));
              }
              return;
            }
            if (key == 'OK') {
              if (value.length == 4) onSubmit?.call();
              return;
            }
            if (value.length < 4) onChanged('$value$key');
          },
          child: Text(
            key,
            style: TextStyle(
              fontSize: isAction ? 14 : 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      },
    );
  }
}
