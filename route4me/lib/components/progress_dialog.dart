import 'package:flutter/material.dart';

class ProgressDialog extends StatelessWidget {
  String? message;
  ProgressDialog({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Dialog(
        backgroundColor: Colors.white,
        child: Flexible(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Flexible(
              child: Row(
                children: [
                  const SizedBox(
                    width: 6,
                  ),
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                  ),
                  const SizedBox(width: 26),
                  Flexible(
                    child: Text(
                      message!,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
