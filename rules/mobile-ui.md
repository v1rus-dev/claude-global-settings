# Mobile UI & Accessibility (Compose)

Applies to mobile / Compose UI work (Android, Compose Multiplatform, and analogous SwiftUI where noted). This is the high-frequency miss-list an implementer must satisfy up front and a reviewer checks — it pre-empts the predictable UX/a11y findings that otherwise surface only in a late review or on-device. Not exhaustive; for a non-trivial screen still run a `ux-expert` review (and prefer reviewing the *plan/design* too, not only the finished code).

## Screen states & navigation
- Every screen handles **loading / empty / error (+retry) / content**; a fetched detail screen also handles **not-found**. No state left as a blank screen.
- **Back navigation must be reachable in ALL states** — including loading and error. Hoist the top bar / back affordance **outside** the state `when`/`AnimatedContent`, never only in the content branch. A network error must never trap the user with no way out.
- Empty states carry human copy ("No results found"), not emptiness.

## Interactive elements & accessibility
- Tappable icons use **`IconButton`** (or an explicit ≥48dp touch target) — not bare `Icon` + `Modifier.clickable` (sub-48dp target, no ripple).
- Every **interactive** icon/control has a `contentDescription` from a string resource. A purely decorative icon adjacent to a text label that already names it may use `contentDescription = null` — decide deliberately, don't default to null on controls.
- Tint icons from theme tokens, never `Color.White` / raw colors.

## Theming & text
- Colors, typography, shapes from the **app theme only** (`AppTheme.*` / Material tokens) — never a hardcoded `Color(0x…)` in feature code, including status/weekend/semantic colors (add a theme token instead).
- Never render a raw enum/status token (`WaitingForApprove`) to the user — map closed-set values to **localized labels** via resources.
- All user-visible text via string resources, **including fallbacks/placeholders** (resolve in the Composable when the source is a non-Composable mapper/VM); free-form server text is shown as-is.
- When filters/sorting are applied but not visible on the current surface, show an **active-state indicator** (badge/count) so the user understands why data is reduced.

## Lists & performance
- Lazy lists use a **stable `key`** and **`contentType`**; hoist heavy or per-item work out of the item lambda; `remember` expensive pure derivations (avatar color, date/string formatting).
- UI-state / list-item models that are read-only data carriers are `@Immutable` (Compose skippability).
- Avoid **card-in-card** / double elevation; keep one clickable layer per row.

## Consistency
- The same datum renders consistently across surfaces (e.g. a type icon shown on a list row also appears in the calendar/detail view).
- Match established components/patterns from the project's design system rather than inventing one-offs.
