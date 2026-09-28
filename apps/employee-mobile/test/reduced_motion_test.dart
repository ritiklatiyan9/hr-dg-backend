import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:defence_garden_employee/mobile_ui.dart';

class VisibleTransition extends PageTransitionsBuilder {
  const VisibleTransition();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => const Text('Animated transition');
}

void main() {
  testWidgets(
    'reduced motion bypasses route effects without hiding page content',
    (tester) async {
      Future<void> render(bool reduced) => tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: Builder(
              builder: (context) =>
                  const ReducedMotionTransitions(
                    VisibleTransition(),
                  ).buildTransitions(
                    MaterialPageRoute<void>(builder: (_) => const SizedBox()),
                    context,
                    const AlwaysStoppedAnimation(0.5),
                    const AlwaysStoppedAnimation(0.0),
                    const Text('Page content'),
                  ),
            ),
          ),
        ),
      );
      await render(true);
      expect(find.text('Page content'), findsOneWidget);
      expect(find.text('Animated transition'), findsNothing);
      await render(false);
      expect(find.text('Animated transition'), findsOneWidget);
    },
  );
}
