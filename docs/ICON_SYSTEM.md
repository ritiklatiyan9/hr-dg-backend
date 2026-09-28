# App icon system

The employee app and HR panel use a consistent Lucide line style, with tinted
module badges and a shared custom sparkle mark for AI. AI chat avatars, report
badges, summaries and action buttons use this mark; robot icons have been removed.

## Employee app

Use `AppIcons`, `AppIcon` and `AppIconBadge` from `lib/ui/icons.dart` for new UI.
`AppIcon` preserves inherited sizing, colors, disabled opacity and semantic labels;
AI is drawn as a small local vector. `AppIconBadge` adds theme-aware module color
and a subtle border. Labels remain the primary way to identify actions. Existing
touch targets, status text, focus behavior and navigation are preserved.

The local `assets/fonts/Lucide.ttf` is the default font from
[lucide_icons_flutter 3.1.20](https://pub.dev/packages/lucide_icons_flutter/versions/3.1.20).
Its 100 selected codepoint constants are in `AppIcons`, marked `@staticIconProvider`
for Flutter release font subsetting. Only this font is bundled; six unused weight
variants would add approximately 2.8 MiB before APK compression. No icon requires
a network connection or a paid service.

- Source font SHA-256: `64272399ee0c00aeeb6dd391928667c9f5eba5b2ffc9603492693550d78d4d81`.
- Update the font and codepoint constants together; never infer codepoints from
  icon names or mix font versions.
- `assets/fonts/LICENSE-Lucide.txt` contains the font package's MIT notice and
  Lucide/Feather notices. It is bundled and registered with Flutter's license registry.
- [cupertino_icons 1.0.9](https://pub.dev/packages/cupertino_icons) supplies the
  font used by Flutter's platform controls; the release check found this fallback
  missing before this increment.
- Widget golden tests explicitly load the real Lucide font. Baselines cover light,
  dark, 320 px width, landscape, Hindi at 200% text scale and DWR chat/editor views.

## HR panel

Continue to use the existing `lucide-react` package for normal UI icons. Navigation
uses distinct module symbols (for example compass, receipt, headset and notebook)
with a 26 px tinted badge. Both full and collapsed navigation retain visible icons;
the mobile menu uses the same treatment.

Use `AiIcon` from `components/ui/ai-icon.tsx` for AI features. Its geometry matches
the Flutter painter. It inherits the surrounding text color and accepts SVG props;
it is decorative unless an accessible name is supplied. `ai-avatar` provides the
shared evergreen background and light foreground. Do not use robot imagery.

Verification logs and screenshots: [evidence/icons](evidence/icons/README.md).
