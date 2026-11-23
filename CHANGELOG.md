## 0.1.1

- BREAKING: migrate Material and Cupertino widgets to `material_ui` and `cupertino_ui`; consuming apps must migrate together.
- Replace `useAppBarAsSliver` with `appBarLayout: .fixed` / `.sliver`, independently of the body layout.
- Replace `useSlivers` with fixed, scrollable, and sliver body layouts. Scrollable bodies fill the viewport and scroll when content exceeds it.
- Add explicit Cupertino, Material, and adaptive refresh styles, retaining the legacy indicator setting and existing scroll-start gating.
- Add safe-area handling, keyboard dismissal, back-navigation control, and an optional scroll controller with ownership-aware disposal.
- Preserve the existing loading and error presentation and resolve scaffold builders together before composing the page.
- Add regression coverage for layouts, keyboard constraints, refresh controls, scroll-start gating, and default loading/error widgets.

## 0.0.8

- Expose extendBodyBehindAppBar property within LoadableScaffold

## 0.0.7

- Minor fix to the & operator logic

## 0.0.6

- Add operator & to combine multiple LoadableStatus'es
- Remove bottom safe area padding when used without slivers

## 0.0.5

- Rework bottom safe area in LoadableScaffold to use padding instead of SafeArea

## 0.0.4

- Add bottom safe area to LoadableScaffold

## 0.0.3

- Add support for web

## 0.0.2

- Add support for persistent footer buttons in LoadableScaffold

## 0.0.1

- Initial release