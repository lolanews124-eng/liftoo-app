import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'back_navigation.dart';

CustomTransitionPage<T> appSlidePage<T>({
  required LocalKey key,
  required Widget child,
  bool wrapBackHandler = true,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: wrapBackHandler ? RootBackScope(child: child) : child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(curve),
        child: FadeTransition(opacity: curve, child: child),
      );
    },
  );
}

CustomTransitionPage<T> appFadePage<T>({
  required LocalKey key,
  required Widget child,
  bool wrapBackHandler = true,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: wrapBackHandler ? RootBackScope(child: child) : child,
    transitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}
