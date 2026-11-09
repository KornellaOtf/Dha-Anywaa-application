# Dha Anywaa UI Audit

**Date:** 2026-11-03 (Updated: 2026-11-09 v1.2.22)  
**Scope:** Full Flutter UI source review, asset-reference check, and `flutter analyze`.  
**Method note:** This is a code-led audit. I did not run a device/emulator visual test in this pass, so findings about clipping at very small sizes should be confirmed on target devices.

## Executive summary

The app has a clear educational purpose and a useful learning sequence: alphabet, vocabulary, reading, and quiz. Its core content is broad, the two-column wide-screen navigator is a good starting point, and most primary screens expose both Anywaa and English labels.

**Update (v1.2.22):** Body parts screen has been significantly improved with a clean custom SVG illustration, removing the watermarked stock image and baked-in text labels that were previously flagged as usability issues.

The UI currently has high-impact reliability and usability gaps. Several catalog cards cannot be selected, a number of detail views show the wrong section heading, most vocabulary modules show an audio control that does nothing, and the quiz loses its state during ordinary rebuilds. The visual system is also inconsistent across modules: app bars, header-language order, colors, spacing, and wide-screen behavior vary considerably. Fix the P0/P1 items before a user-facing release.

## Recent Improvements (v1.2.22)

### ✅ Fixed Issues
- **Body Parts Screen**: Replaced watermarked stock photo with custom SVG illustration
- **Text Legibility**: Removed baked-in text labels that were blurry on mobile screens
- **Layout Issues**: Eliminated excessive whitespace and nested container issues
- **Professional Appearance**: Added proper Anywaa title and cleaner visual hierarchy

## Screen and navigation inventory

| Area | Entry point | Current experience | Primary concern |
| --- | --- | --- | --- |
| Welcome/name | `Wrapper` → `NameEntry` | Collects a learner name and stores it locally. | No keyboard-safe/scrollable layout; unclear submit control. |
| Home | `HomePage` | Phone: 2-column category grid. Wide: master list plus embedded learning module. | Missing selected-card semantics, dense layout, and inconsistent screen chrome. |
| Drawer | `HomePage` drawer | Vowels, body diagram, About, Help, external website, log out. | Drawer remains open after navigation; logout icon is misleading. |
| Alphabet | `Page1` | Letter grid and enlarged next/previous mode with audio. | Enlarged header incorrectly says Birds; invalid audio lifecycle logic. |
| Words | `Page2` | Illustrated word grid and enlarged image/audio mode. | Some text/data quality errors; fixed image height risks overflow. |
| Reading | `Page3` | Scrollable sentence list; tap a row to play audio. | No visible play affordance/status, state is not represented correctly. |
| Quiz | `Page4` | Vertically paged 31-question quiz with answer feedback. | Controller/data are re-created on rebuild; progress is hidden; navigation is weak. |
| Result | `Result` | Displays score in a circle. | No restart, review, or return-home action. |
| Vocabulary groups | Number, colors, shapes, body, clothes, birds, animals, fish | Grids with a zoom/detail toggle. | ✅ Body screen improved with SVG. Most other grids still non-interactive. |
| About/Help/body diagram | `About`, `Help`, `Body` | Supporting information and visual body chart. | ✅ Body diagram now uses clean SVG illustration. Text-heavy responsive layout still needs work. |

## Findings

### P0 — release-blocking or content-blocking

1. **About screen references a missing logo asset.**  
   `About` loads `assets/word_images/awal_icon.png` at [lib/about.dart:81](lib/about.dart:81), but that file is absent. Opening About will show Flutter's broken-image/error presentation instead of the intended branding. Add the asset or update the reference to a shipped image.

2. **Most vocabulary grids do not open their detail mode.**  
   Shapes, colors, body parts, clothes, birds, animals, and fish wrap cards in `GestureDetector`, but their `onTap` is commented out or omitted. Examples: [lib/components/shape.dart:155](lib/components/shape.dart:155), [lib/components/fish.dart:168](lib/components/fish.dart:168), and [lib/components/cloth.dart:182](lib/components/cloth.dart:182). The only way into `zoom` mode is its header icon, which always starts at item 0. A learner cannot select a card to study it.

3. **Audio controls promise functionality but do nothing in most modules.**  
   The detail views for numbers, shapes, colors, body parts, clothes, birds, animals, and fish display a large play icon with an empty callback (for example [lib/components/number.dart:143](lib/components/number.dart:143), [lib/components/fish.dart:116](lib/components/fish.dart:116)). Remove these controls until audio is supplied, or implement and test pronunciation audio for each item.

4. **The quiz recreates its `PageController` on every build.**  
   [lib/pages/page4.dart:245](lib/pages/page4.dart:245) creates `PageController()` in `build`. Answering uses `setState` ([line 330](lib/pages/page4.dart:330)), so the controller is replaced during an active quiz. This can reset the current page/gesture position and is a major assessment-flow defect. Store/dispose a single controller in state.

### P1 — major usability, interaction, and responsive issues

5. **Three enlarged lesson headers identify the user as being in “Birds.”**  
   Shapes has `winy / Birds` at [lib/components/shape.dart:48](lib/components/shape.dart:48); colors has the same at [lib/components/colors.dart:76](lib/components/colors.dart:76); clothes also has it at [lib/components/cloth.dart:75](lib/components/cloth.dart:75). Alphabet repeats the error at [lib/pages/page1.dart:95](lib/pages/page1.dart:95). This is a disorienting, visible content error.

6. **Audio code misuses `setState` and never waits for the intended duration.**  
   Alphabet, words, and vowels call `setState(() async { ... })`, e.g. [lib/pages/page1.dart:159](lib/pages/page1.dart:159). `setState` must be synchronous. The code also constructs `Duration(...)` without awaiting a delay ([line 165](lib/pages/page1.dart:165)), casts potentially nullable duration values, and broadly suppresses errors. Result: unreliable playback and no trustworthy play/pause state. Move audio work to an async method, await it outside `setState`, and derive UI state from the player event stream.

7. **Fixed 400 px detail content can overflow short phones and large-text settings.**  
   The detail pattern uses a fixed `height: 400` image plus title, labels, controls, and app bar in a non-scrollable `Column` (for example [lib/pages/page2.dart:222](lib/pages/page2.dart:222), [lib/components/animal.dart:125](lib/components/animal.dart:125), and [lib/components/number.dart:99](lib/components/number.dart:99)). On short devices or with accessibility text scaling, this can produce a bottom overflow. Use `Expanded`/`Flexible`, `AspectRatio`, and a scrollable fallback.

8. **The welcome form is not keyboard-safe or scrollable.**  
   `NameEntry` uses a fixed `Column` with a 160 px spacer ([lib/nameEntry.dart:21](lib/nameEntry.dart:21), [line 33](lib/nameEntry.dart:33)). When the keyboard opens or text size is enlarged, the submit control can be covered. Use `SafeArea` plus `SingleChildScrollView`, and replace the icon-only Card with a labeled full-width button.

9. **Quiz has no visible progress and weak navigation safeguards.**  
   Its score/progress header is commented out ([lib/pages/page4.dart:258](lib/pages/page4.dart:258)). Users cannot see question count or completion progress. Back is offered on question one ([line 377](lib/pages/page4.dart:377)) without a disabled state, and forward is possible before choosing an answer. Provide “Question X of 31,” a progress indicator, disabled boundary controls, and an explicit “answer required” state (or clearly state that skipping is allowed).

10. **Quiz answers do not expose selection or correctness accessibly.**  
    State is communicated solely by red/green backgrounds ([lib/pages/page4.dart:311](lib/pages/page4.dart:311)), while the leading icon remains a generic outlined circle ([line 353](lib/pages/page4.dart:353)). Add selected/correct/incorrect icons, semantic labels, and text feedback. Color alone fails non-color perception and is especially unfriendly for children learning independently.

11. **Home wide-screen embeds full `Scaffold` screens inside another screen.**  
    `pageList[_currentIndex]` is inserted into the right pane at [lib/home_page.dart:367](lib/home_page.dart:367), while each listed page creates its own `Scaffold`. This produces inconsistent/duplicated app bars and can create competing visual surfaces. Extract reusable module body widgets or use a shell with one top-level Scaffold.

12. **Responsive behavior is inconsistent across related modules.**  
    Home switches at width >600 ([lib/home_page.dart:289](lib/home_page.dart:289)); some grids use `shortestSide > 600`, some remain fixed at two columns, and clothes includes a no-op responsive expression (`? 2 : 2`) at [lib/components/cloth.dart:178](lib/components/cloth.dart:178). Define shared breakpoints and grid delegates. Use `LayoutBuilder`/`MediaQuery` inside `build` rather than a cached global view measurement.

13. **Deprecated global window access undermines multi-window and resize support.**  
    Components cache `MediaQueryData.fromView(WidgetsBinding.instance.window)` (e.g. [lib/home_page.dart:118](lib/home_page.dart:118), [lib/pages/page2.dart:194](lib/pages/page2.dart:194)). `flutter analyze` reports this as deprecated in ten files. Obtain sizing from `MediaQuery.of(context)` or `View.of(context)` during build so the UI responds correctly to window changes.

14. **Drawer actions navigate without dismissing the drawer.**  
    Drawer entries directly push pages, e.g. [lib/home_page.dart:190](lib/home_page.dart:190). The drawer can remain on the navigator stack/back path, which feels broken. Call `Navigator.pop(context)` before navigation or use a single route replacement strategy.

15. **External actions silently fail and are incorrectly wrapped in state updates.**  
    Home “More” invokes `_openUrl()` inside `setState` and swallows exceptions ([lib/home_page.dart:247](lib/home_page.dart:247)); About does the same for web and email actions ([lib/about.dart:122](lib/about.dart:122)). This offers no feedback if a browser/email app is unavailable. Await the action without `setState`, check success, and show a SnackBar on failure.

16. **Result screen is a dead end.**  
    After finishing, `Result` only presents a score ([lib/result_page.dart:36](lib/result_page.dart:36)). There is no retry, review, or home route. Add clear primary and secondary actions; also ensure a result can be reached only after the intended completion condition.

### P2 — accessibility, content quality, and design-system issues

17. **Touch targets and affordances are inconsistent.**  
    Home/category cards use generic `GestureDetector` around visual cards ([lib/home_page.dart:405](lib/home_page.dart:405)); other cards appear tappable but do nothing. Prefer `InkWell`/`FilledButton`/`ListTile` with visible feedback, semantics, and at least a 48×48 dp target.

18. **Typography, language ordering, and labels vary across categories.**  
    Home presents Anywaa as primary and English as secondary; Animals reverses that in its grid ([lib/components/animal.dart:190](lib/components/animal.dart:190)); Number and Fish do likewise. Establish a learning-content rule (for example: Anywaa primary, English translation secondary) and use it everywhere.

19. **Several content strings are incomplete or likely incorrect.**  
    Fish intentionally renders an empty English label for every item ([lib/components/fish.dart:17](lib/components/fish.dart:17)); Clothes maps Anywaa word “Shoes” to English “War” ([lib/components/cloth.dart:34](lib/components/cloth.dart:34)); Shapes uses “Three Angle” rather than “Triangle” ([lib/components/shape.dart:18](lib/components/shape.dart:18)); Word list includes “Crocdile,” “Hayna,” “Quitar,” and a blank translation ([lib/pages/page2.dart:137](lib/pages/page2.dart:137), [line 142](lib/pages/page2.dart:142), [line 172](lib/pages/page2.dart:172), [line 147](lib/pages/page2.dart:147)). Have a language/content reviewer validate every translation, spelling, and diacritic.

20. **Color and visual hierarchy are not centrally defined.**  
    Many screens hard-code near-identical navy, grey, blue, and spacing values (e.g. [lib/about.dart:60](lib/about.dart:60), [lib/pages/page3.dart:242](lib/pages/page3.dart:242)), while the app theme only defines `primaryColor` ([lib/main.dart:25](lib/main.dart:25)). Create a Material 3 `ColorScheme`, `TextTheme`, component themes, and semantic constants. This will improve contrast consistency and make dark mode/future visual changes feasible.

21. **Some screens have no meaningful page title in their AppBar.**  
    The home app bar is intentionally blank ([lib/home_page.dart:154](lib/home_page.dart:154)), most lesson pages have transparent empty app bars, and Result uses blank text ([lib/result_page.dart:28](lib/result_page.dart:28)). A screen title helps orientation, screen readers, and navigation history. If the visual design requires a minimal bar, retain a semantic title and provide a clear back/menu control.

22. **About footer is positioned with a magic left inset.**  
    `padding: EdgeInsets.fromLTRB(125, 5, 0, 5)` ([lib/about.dart:159](lib/about.dart:159)) will look off-center or clip on narrow screens and is not RTL-ready. Center the footer text with proper safe-area padding.

23. **Long help text is hard to scan and not task-oriented.**  
    `Help` renders one large `SelectableText` block ([lib/help.dart:21](lib/help.dart:21)). Use short sections, numbered steps, icons/screenshots where appropriate, and headings such as “Listen to a letter,” “Take a quiz,” and “Use the menu.”

24. **The code quality signals make future UI regressions likely.**  
    `flutter analyze` reports 14 issues: missing `flutter_lints` include, deprecated window APIs across ten files, deprecated `withOpacity`, and an invalid `@override` on [lib/nameEntry.dart:12](lib/nameEntry.dart:12). Fix lint configuration first, then resolve warnings so UI defects are caught sooner.

25. **Navigation and route naming are inconsistent.**  
    Routes omit leading slashes except root ([lib/main.dart:29](lib/main.dart:29)), some navigation uses named routes and others use `MaterialPageRoute`, and `Shpae` is misspelled as a public class ([lib/components/shape.dart:3](lib/components/shape.dart:3)). Standardize routes and names; the result will be easier to test and less error-prone.

## Recommended implementation order

1. Repair the missing asset; make every vocabulary card open its selected item; either implement or remove inactive play controls.
2. Stabilize the quiz (state-owned controller, progress, answer feedback, navigation bounds, restart/home actions).
3. Replace the audio callbacks with a shared, accessible audio-control component.
4. Make name entry and all detail pages responsive to keyboard, small height, and text scale.
5. Normalize headers, language order, content strings, and catalog layouts; correct the visible “Birds” copy errors.
6. Establish an app shell/design system and remove nested Scaffolds/deprecated window APIs.
7. Add device tests at phone, small-phone landscape, tablet, and desktop widths; include 200% text scale and screen-reader checks.

## Verification performed

- Ran `flutter analyze`: no compilation-stopping errors; 14 warnings/info items were reported and are reflected above.
- Checked UI-referenced asset paths: `assets/word_images/awal_icon.png` is missing.
- Reviewed all files under `lib/` that build visible screens, navigation, lesson modules, quiz, help/about, and persisted-name entry.

