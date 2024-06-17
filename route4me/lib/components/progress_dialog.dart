import 'package:flutter/material.dart';

class ProgressDialog extends StatelessWidget {
  final String? message;
  ProgressDialog({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize
              .min, // Ensures the container sizes itself just to fit its children
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
            SizedBox(width: 26),
            Expanded(
              child: Text(
                message ??
                    'Loading...', // Fallback text in case the message is null
                style: TextStyle(
                  color: Colors.black,
                  fontSize:
                      16, // Made text slightly larger for better visibility
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
