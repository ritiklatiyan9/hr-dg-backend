import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show rootBundle;
import 'tokens.dart';

// Codepoints from lucide_icons_flutter 3.1.20, default Lucide font only.
// Keep this mapping and assets/fonts/Lucide.ttf together when updating.
void registerIconLicense() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Lucide',
      'Feather',
      'lucide_icons_flutter',
    ], await rootBundle.loadString('assets/fonts/LICENSE-Lucide.txt'));
  });
}

/// One local, tree-shakeable icon family for every employee-facing module.
@staticIconProvider
abstract final class AppIcons {
  static const archive = IconData(57409, fontFamily: 'Lucide');
  static const arrowRight = IconData(57417, fontFamily: 'Lucide');
  static const atSign = IconData(57422, fontFamily: 'Lucide');
  static const badgeAlert = IconData(58485, fontFamily: 'Lucide');
  static const badgeCheck = IconData(57921, fontFamily: 'Lucide');
  static const batteryLow = IconData(57430, fontFamily: 'Lucide');
  static const bell = IconData(57433, fontFamily: 'Lucide');
  static const bellRing = IconData(57892, fontFamily: 'Lucide');
  static const bookOpenCheck = IconData(58241, fontFamily: 'Lucide');
  static const briefcaseBusiness = IconData(58837, fontFamily: 'Lucide');
  static const calendar = IconData(57443, fontFamily: 'Lucide');
  static const calendarCog = IconData(58861, fontFamily: 'Lucide');
  static const calendarDays = IconData(58041, fontFamily: 'Lucide');
  static const calendarRange = IconData(58045, fontFamily: 'Lucide');
  static const calendarX2 = IconData(58047, fontFamily: 'Lucide');
  static const camera = IconData(57444, fontFamily: 'Lucide');
  static const chartNoAxesCombined = IconData(58892, fontFamily: 'Lucide');
  static const check = IconData(57452, fontFamily: 'Lucide');
  static const checkCheck = IconData(58254, fontFamily: 'Lucide');
  static const chevronDown = IconData(57453, fontFamily: 'Lucide');
  static const chevronRight = IconData(57455, fontFamily: 'Lucide');
  static const chevronUp = IconData(57456, fontFamily: 'Lucide');
  static const circle = IconData(57462, fontFamily: 'Lucide');
  static const circleAlert = IconData(57463, fontFamily: 'Lucide');
  static const circleCheck = IconData(57894, fontFamily: 'Lucide');
  static const circleDot = IconData(58181, fontFamily: 'Lucide');
  static const circleHelp = IconData(57474, fontFamily: 'Lucide');
  static const circlePlus = IconData(57473, fontFamily: 'Lucide');
  static const circleStop = IconData(57475, fontFamily: 'Lucide');
  static const circleUserRound = IconData(58466, fontFamily: 'Lucide');
  static const clipboardCheck = IconData(57881, fontFamily: 'Lucide');
  static const clock3 = IconData(57936, fontFamily: 'Lucide');
  static const cloudOff = IconData(57485, fontFamily: 'Lucide');
  static const cloudUpload = IconData(57489, fontFamily: 'Lucide');
  static const coffee = IconData(57494, fontFamily: 'Lucide');
  static const compass = IconData(57499, fontFamily: 'Lucide');
  static const contactRound = IconData(58467, fontFamily: 'Lucide');
  static const copy = IconData(57502, fontFamily: 'Lucide');
  static const download = IconData(57522, fontFamily: 'Lucide');
  static const eye = IconData(57530, fontFamily: 'Lucide');
  static const eyeOff = IconData(57531, fontFamily: 'Lucide');
  static const fileDown = IconData(58136, fontFamily: 'Lucide');
  static const fileText = IconData(57548, fontFamily: 'Lucide');
  static const folderOpen = IconData(57927, fontFamily: 'Lucide');
  static const headset = IconData(58813, fontFamily: 'Lucide');
  static const history = IconData(57845, fontFamily: 'Lucide');
  static const hourglass = IconData(58006, fontFamily: 'Lucide');
  static const house = IconData(57589, fontFamily: 'Lucide');
  static const image = IconData(57590, fontFamily: 'Lucide');
  static const inbox = IconData(57591, fontFamily: 'Lucide');
  static const info = IconData(57593, fontFamily: 'Lucide');
  static const keyRound = IconData(58531, fontFamily: 'Lucide');
  static const languages = IconData(57598, fontFamily: 'Lucide');
  static const leaf = IconData(58078, fontFamily: 'Lucide');
  static const listPlus = IconData(57919, fontFamily: 'Lucide');
  static const listTodo = IconData(58563, fontFamily: 'Lucide');
  static const lockKeyhole = IconData(58673, fontFamily: 'Lucide');
  static const logIn = IconData(57613, fontFamily: 'Lucide');
  static const logOut = IconData(57614, fontFamily: 'Lucide');
  static const mailCheck = IconData(58209, fontFamily: 'Lucide');
  static const mapPin = IconData(57617, fontFamily: 'Lucide');
  static const mapPinOff = IconData(58022, fontFamily: 'Lucide');
  static const megaphone = IconData(57909, fontFamily: 'Lucide');
  static const messageSquareMore = IconData(58736, fontFamily: 'Lucide');
  static const messageSquareText = IconData(58741, fontFamily: 'Lucide');
  static const messagesSquare = IconData(58381, fontFamily: 'Lucide');
  static const mic = IconData(57624, fontFamily: 'Lucide');
  static const monitorSmartphone = IconData(58274, fontFamily: 'Lucide');
  static const moonStar = IconData(58384, fontFamily: 'Lucide');
  static const notebookPen = IconData(58774, fontFamily: 'Lucide');
  static const paperclip = IconData(57645, fontFamily: 'Lucide');
  static const pencil = IconData(57849, fontFamily: 'Lucide');
  static const plus = IconData(57661, fontFamily: 'Lucide');
  static const receiptText = IconData(58796, fontFamily: 'Lucide');
  static const refreshCw = IconData(57669, fontFamily: 'Lucide');
  static const rotateCw = IconData(57673, fontFamily: 'Lucide');
  static const route = IconData(58686, fontFamily: 'Lucide');
  static const save = IconData(57677, fontFamily: 'Lucide');
  static const search = IconData(57681, fontFamily: 'Lucide');
  static const sendHorizontal = IconData(58610, fontFamily: 'Lucide');
  static const settings2 = IconData(57925, fontFamily: 'Lucide');
  static const shield = IconData(57688, fontFamily: 'Lucide');
  static const shieldCheck = IconData(57855, fontFamily: 'Lucide');
  static const shieldOff = IconData(57690, fontFamily: 'Lucide');
  static const shieldUser = IconData(58951, fontFamily: 'Lucide');
  static const slidersHorizontal = IconData(58010, fontFamily: 'Lucide');
  static const smartphone = IconData(57699, fontFamily: 'Lucide');
  static const sprout = IconData(57835, fontFamily: 'Lucide');
  static const stamp = IconData(58299, fontFamily: 'Lucide');
  static const sun = IconData(57720, fontFamily: 'Lucide');
  static const trash2 = IconData(57742, fontFamily: 'Lucide');
  static const treePalm = IconData(57985, fontFamily: 'Lucide');
  static const undo2 = IconData(58017, fontFamily: 'Lucide');
  static const userRound = IconData(58472, fontFamily: 'Lucide');
  static const userRoundMinus = IconData(58475, fontFamily: 'Lucide');
  static const userRoundPlus = IconData(58476, fontFamily: 'Lucide');
  static const usersRound = IconData(58478, fontFamily: 'Lucide');
  static const walletCards = IconData(58572, fontFamily: 'Lucide');
  static const x = IconData(57778, fontFamily: 'Lucide');
  static const ai = IconData(58386, fontFamily: 'Lucide');
}

/// Keeps labels, inherited colors and sizing consistent, with a bespoke AI mark.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });
  final IconData? icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) {
    if (icon != AppIcons.ai) {
      return Icon(icon, size: size, color: color, semanticLabel: semanticLabel);
    }
    final theme = IconTheme.of(context);
    final ink = color ?? theme.color ?? AppTokens.of(context).text;
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size ?? theme.size ?? 24,
          child: CustomPaint(
            painter: _AiMarkPainter(
              ink.withValues(alpha: ink.a * (theme.opacity ?? 1)),
            ),
          ),
        ),
      ),
    );
  }
}

class _AiMarkPainter extends CustomPainter {
  const _AiMarkPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final spark = Path()
      ..moveTo(10.5, 3)
      ..cubicTo(11.5, 8.9, 13.1, 10.5, 19, 11.5)
      ..cubicTo(13.1, 12.5, 11.5, 14.1, 10.5, 20)
      ..cubicTo(9.5, 14.1, 7.9, 12.5, 2, 11.5)
      ..cubicTo(7.9, 10.5, 9.5, 8.9, 10.5, 3)
      ..close();
    canvas.drawPath(
      spark,
      Paint()..color = color.withValues(alpha: color.a * .14),
    );
    canvas.drawPath(
      spark,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeJoin = StrokeJoin.round,
    );
    final satellite = Path()
      ..moveTo(20, 1.5)
      ..quadraticBezierTo(20.4, 4.6, 23.5, 5)
      ..quadraticBezierTo(20.4, 5.4, 20, 8.5)
      ..quadraticBezierTo(19.6, 5.4, 16.5, 5)
      ..quadraticBezierTo(19.6, 4.6, 20, 1.5)
      ..close();
    canvas.drawPath(satellite, Paint()..color = color);
    canvas.drawCircle(
      const Offset(20, 19),
      1.3,
      Paint()..color = color.withValues(alpha: color.a * .7),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AiMarkPainter oldDelegate) => color != oldDelegate.color;
}

/// Quiet, consistent module colors; the symbol and label also identify the action.
class AppIconBadge extends StatelessWidget {
  const AppIconBadge(
    this.icon, {
    super.key,
    this.size = 42,
    this.accent = false,
  });
  final IconData icon;
  final double size;
  final bool accent;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ai = icon == AppIcons.ai;
    final hue = switch (icon) {
      AppIcons.clock3 ||
      AppIcons.calendarDays ||
      AppIcons.calendar ||
      AppIcons.mapPin ||
      AppIcons.compass ||
      AppIcons.route ||
      AppIcons.treePalm =>
        dark ? const Color(0xff87d7b6) : const Color(0xff237354),
      AppIcons.receiptText || AppIcons.walletCards || AppIcons.stamp =>
        dark ? const Color(0xffedbd78) : const Color(0xff9a6425),
      AppIcons.messagesSquare ||
      AppIcons.messageSquareText ||
      AppIcons.messageSquareMore ||
      AppIcons.headset ||
      AppIcons.usersRound =>
        dark ? const Color(0xffb6a7ed) : const Color(0xff7055af),
      AppIcons.listTodo ||
      AppIcons.clipboardCheck ||
      AppIcons.fileText ||
      AppIcons.folderOpen ||
      AppIcons.bookOpenCheck =>
        dark ? const Color(0xff97baed) : const Color(0xff3a67a2),
      _ => dark ? const Color(0xffb4c2cc) : const Color(0xff566b77),
    };
    final tint = accent ? t.success : hue;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .3),
        gradient: ai
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff19483f), Color(0xff397b68)],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    tint.withValues(alpha: dark ? .2 : .1),
                    t.surface,
                  ),
                  Color.alphaBlend(tint.withValues(alpha: .035), t.surface),
                ],
              ),
        border: Border.all(
          color: ai ? const Color(0xff6aa48e) : tint.withValues(alpha: .16),
        ),
      ),
      child: Center(
        child: AppIcon(
          icon,
          size: size * .53,
          color: ai ? const Color(0xfff3fff9) : tint,
        ),
      ),
    );
  }
}
