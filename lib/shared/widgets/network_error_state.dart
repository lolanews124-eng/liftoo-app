import 'package:flutter/material.dart';

import 'error_screen.dart';



class NetworkErrorState extends StatelessWidget {

  final VoidCallback onRetry;

  final String? message;

  final bool offline;



  const NetworkErrorState({

    super.key,

    required this.onRetry,

    this.message,

    this.offline = true,

  });



  @override

  Widget build(BuildContext context) {

    return ErrorScreen(

      type: offline ? ErrorScreenType.offline : ErrorScreenType.server,

      message: message,

      onRetry: onRetry,

    );

  }

}

