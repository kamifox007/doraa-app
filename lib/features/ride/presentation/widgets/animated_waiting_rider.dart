import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedWaitingRider extends StatefulWidget {
  const AnimatedWaitingRider({super.key});

  @override
  State<AnimatedWaitingRider> createState() => _AnimatedWaitingRiderState();
}

class _AnimatedWaitingRiderState extends State<AnimatedWaitingRider> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _shakeAnimation;
  bool _isAngry = false;
  Timer? _angryTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _shakeAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticIn),
    );

    // التحول إلى غاضبة بعد 15 ثانية من الانتظار
    _angryTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          _isAngry = true;
          // تسريع الحركة للتعبير عن الغضب ونفاد الصبر
          _controller.duration = const Duration(milliseconds: 600);
          _bounceAnimation = Tween<double>(begin: 0, end: -15).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
          );
          _shakeAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
            CurvedAnimation(parent: _controller, curve: Curves.elasticIn),
          );
          _controller.repeat(reverse: true);
        });
      }
    });
  }

  @override
  void dispose() {
    _angryTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bounceAnimation.value),
            child: Transform.rotate(
              angle: _shakeAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _isAngry ? Colors.orange : const Color(0xFFE91E63), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _isAngry ? Colors.orange.withValues(alpha: 0.4) : const Color(0xFFE91E63).withValues(alpha: 0.3),
                      blurRadius: _isAngry ? 15 : 10,
                      spreadRadius: _isAngry ? 4 : 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    _isAngry ? 'assets/images/impatient_girl.png' : 'assets/images/waiting_girl.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
