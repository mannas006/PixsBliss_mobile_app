import 'package:flutter/material.dart';

class ButtonAnimation extends StatefulWidget {
  final Color primaryColor;
  final Color darkPrimaryColor;
  final VoidCallback onDownload;
  final bool isComplete;
  final double borderRadius;
  final String buttonText;
  final bool isEnabled;

  const ButtonAnimation(
    this.primaryColor,
    this.darkPrimaryColor,
    {required this.onDownload, required this.isComplete, this.borderRadius = 12.0, this.buttonText = "Download", this.isEnabled = true, Key? key}
  ) : super(key: key);

  @override
  _ButtonAnimationState createState() => _ButtonAnimationState();
}

class _ButtonAnimationState extends State<ButtonAnimation> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _scaleAnimationController;
  late AnimationController _fadeAnimationController;

  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  double buttonWidth = 200.0;
  double scale = 1.0;
  bool animationComplete = false;
  double barColorOpacity = .6;
  bool animationStart = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3)
    );

    _scaleAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300)
    );

    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400)
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_fadeAnimationController);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(_scaleAnimationController)..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _scaleAnimationController.reverse();
        _fadeAnimationController.forward();
        _animationController.forward();
      }
    });

    _animation = Tween<double>(
      begin: 0.0,
      end: buttonWidth
    ).animate(_animationController)..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          animationComplete = true;
          barColorOpacity = .0;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ButtonAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('ButtonAnimation didUpdateWidget: isComplete=${widget.isComplete}, animationComplete=$animationComplete');
    if (widget.isComplete && !animationComplete) {
      setState(() {
        animationComplete = true;
        barColorOpacity = 0.0;
      });
      debugPrint('ButtonAnimation: animationComplete set to true');
    }
    if (!widget.isComplete && animationComplete) {
      setState(() {
        animationComplete = false;
        barColorOpacity = .6;
      });
      debugPrint('ButtonAnimation: animationComplete reset to false');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedBuilder(
          animation: _scaleAnimationController,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: InkWell(
              onTap: widget.isEnabled && !animationComplete ? () {
                debugPrint('Button tapped!');
                widget.onDownload();
                _scaleAnimationController.forward();
              } : null,
              child: Container(
                width: 200,
                height: 50,
                decoration: BoxDecoration(
                  color: widget.primaryColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius)
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Align(
                        child: 
                        !widget.isComplete ?
                        Text(widget.buttonText, style: TextStyle(color: Colors.white, fontSize: 16),)
                        :
                        Icon(Icons.check, color: Colors.white,)
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _fadeAnimationController,
                      builder: (context, child) => AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: _fadeAnimationController.isCompleted ? 0 : 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: widget.darkPrimaryColor,
                          borderRadius: BorderRadius.circular(widget.borderRadius)
                        ),
                        child: AnimatedOpacity(
                          duration: Duration(milliseconds: 500),
                          opacity: _fadeAnimation.value,
                          child: Icon(Icons.arrow_downward, color: Colors.white,)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ),
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) => Positioned(
            left: 0,
            top: 0,
            width: _animation.value,
            height: 50,
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 200),
              opacity: barColorOpacity,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
} 