import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final Color color;
  final double size;

  const LoadingIndicator({
    Key? key,
    this.message,
    this.color = Colors.deepPurple,
    this.size = 50.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitCircle(
            color: color,
            size: size,
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                message!,
                style: TextStyle(
                  color: color,
                  fontSize: 16.0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Convenience static methods
  static Widget fullScreen({String? message, Color color = Colors.deepPurple}) {
    return Container(
      color: Colors.white,
      child: LoadingIndicator(
        message: message,
        color: color,
      ),
    );
  }

  static Widget overlay({String? message, Color color = Colors.deepPurple}) {
    return Container(
      color: Colors.black26,
      child: LoadingIndicator(
        message: message,
        color: color,
      ),
    );
  }

  static Widget button({Color color = Colors.white, double size = 24.0}) {
    return SpinKitCircle(
      color: color,
      size: size,
    );
  }
}
