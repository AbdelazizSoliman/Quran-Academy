# Design QA — Madarak-inspired role portals

## Evidence

- Source visual truth paths:
  - `tmp/madarak-frames/teacher.jpg` (1968 × 1128)
  - `tmp/madarak-frames/student.jpg` (1968 × 1128)
  - `tmp/madarak-frames/parent.jpg` (1968 × 1128)
- Browser-rendered implementation screenshots:
  - `tmp/qa-teacher.png` (1440 × 950)
  - `tmp/qa-student.png` (1440 × 950)
  - `tmp/qa-guardian.png` (1440 × 1082)
- Combined comparison evidence:
  - `C:/Users/hp/.codex/visualizations/2026/08/11/019fefda-a2df-7260-96ab-b0ee50f50460/compare-teacher.jpg`
  - `C:/Users/hp/.codex/visualizations/2026/08/11/019fefda-a2df-7260-96ab-b0ee50f50460/compare-student.jpg`
  - `C:/Users/hp/.codex/visualizations/2026/08/11/019fefda-a2df-7260-96ab-b0ee50f50460/compare-guardian.jpg`
- Local implementation URL: `http://127.0.0.1:3132`
- CSS viewport: 1440 × 900; `deviceScaleFactor: 1`; desktop Arabic RTL; authenticated dashboard state.
- Density normalization: source contact sheets and implementation captures were independently scaled to 900 px wide, vertically combined, then a 700 px-wide review copy was opened. No density-only differences were filed.

The source files are presentation-style video contact sheets containing several application states, not a single pixel-identical dashboard state. The comparison therefore judges the shared desktop design language, role structure, information hierarchy, RTL navigation, palette, density, and controls without claiming false pixel precision.

## Findings

- No actionable P0, P1, or P2 differences remain.
- The implementation preserves the source's principal desktop language: fixed deep-green RTL sidebar, green/gold brand palette, white working canvas, compact cards, role-specific navigation, prominent primary actions, and schedule/progress/report entry points.
- [P3] The first guardian browser context emitted one generic `404` console message. A response listener recorded no HTTP response with status 400 or higher, the dashboard and `/guardian/students` loaded successfully, and teacher/student contexts were clean. This is consistent with a browser-default icon probe and does not affect the product flow.

## Required Fidelity Surfaces

- Fonts and typography: Arabic uses the configured `Noto Sans Arabic`/system fallback stack with clear page, hero, card, and supporting-text hierarchy. English profile names remain dynamic content and wrap safely.
- Spacing and layout rhythm: 1440 px captures show stable sidebar width, logical RTL margins, four-column desktop stats, aligned hero/action regions, consistent card padding, radii, borders, and section gaps. No overlap, clipping, or persistent-control overflow was visible.
- Colors and visual tokens: deep green `#073f34`/`#0b4f42`, gold `#c8a34f`, pale green states, neutral canvas, and restrained shadows match the source direction.
- Image quality and asset fidelity: the referenced portal states are UI-only and contain no required photographic or illustrative assets. Icons use the application's existing icon library; no emoji, CSS drawings, placeholder image boxes, or handcrafted SVG substitutes were introduced.
- Copy and content: all fixed portal copy is coherent in Arabic and adapted to a single Quran Academy. Madarak subscription/multi-academy language is absent. Dynamic demo names are intentionally retained.

## Focused Region Evidence

The sidebar/navigation, hero/action strip, stat cards, and quick-action/schedule regions were inspected in the full 1440 px implementation captures and the 1968 px source contact sheets, then again in the combined comparison images. Separate micro-crops were not needed because these regions remained readable at the opened review sizes and there are no source logos, product images, or dense table typography requiring pixel-level asset inspection.

## Interaction and Console Checks

- Guardian: signed in, rendered dashboard, selected-child summary visible, navigated the first quick action to `/guardian/students`.
- Teacher: signed in, rendered dashboard, navigated the first quick action to `/teacher/schedule`.
- Student: signed in, rendered dashboard, navigated the first quick action to `/student/schedule`.
- All three destinations completed successfully. Teacher and student console checks were clean. Guardian had the non-blocking generic 404 note documented above.

## Comparison History

1. Initial comparison found a P1 presentation mismatch: the QA server was serving a stale precompiled stylesheet, so the green/gold surfaces, desktop grid, and visible sidebar did not match the current implementation or source direction.
2. Fix: rebuilt/precompiled the current Tailwind bundle, restarted the stable no-reload preview, forced Arabic demo locale, and recaptured all three roles at the same 1440 × 900 viewport.
3. Post-fix evidence: `tmp/qa-guardian.png`, `tmp/qa-teacher.png`, and `tmp/qa-student.png`, plus the three combined comparison images above. The corrected captures show the intended deep-green RTL sidebar, gold actions, dark-green hero, four-column stats, and white working canvas with no remaining P0/P1/P2 mismatch.

## Implementation Checklist

- [x] Arabic RTL desktop shell and role-specific sidebar
- [x] Teacher, student, and guardian dashboards
- [x] Guardian child scoping and portal routes
- [x] Primary quick-action navigation
- [x] Browser screenshots at target viewport
- [x] Combined source/implementation comparison
- [x] Console and route checks

## Madarak owner V1 — students and teachers

### Evidence

- Student source: `tmp/madarak-owner-audit/focus/students-12-view.jpg`.
- Student implementation: `tmp/madarak-owner-audit/implementation-students.png`.
- Teacher source: `tmp/madarak-owner-audit/focus/teachers-12-view.jpg`.
- Teacher implementation: `tmp/madarak-owner-audit/implementation-teachers.png`.
- Review viewport: 1440 × 1000, Arabic RTL, authenticated academy administrator.

### Findings

- No actionable P0, P1, or P2 differences remain for these two V1 screens.
- Students preserve the Madarak toolbar and workflow: add, Excel-compatible import, filtered export, search, status, teacher, country, currency, Quran level, gender, age, and guardian filters. Cards preserve identity/code, status, assigned teacher, guardian, country, contact, Quran level, and completion state.
- Teachers preserve the reference column order: teacher identity, calculated utilization, assigned student count, status, gender, country/language/specialization context, conditional compensation, and actions.
- Teacher utilization is derived from active weekly teaching availability versus scheduled/in-progress/completed lesson minutes; it is not a manually entered value.
- Student finance/trial CRM surfaces remain intentionally excluded from V1 according to the approved release contract. Compensation remains conditional on the payroll release feature.

### Interaction and console checks

- Students: status filter applied, filtered CSV downloaded, and import page/file control opened successfully.
- Teachers: gender filter applied, filtered CSV downloaded, and import page/file control opened successfully.
- Both Playwright flows passed. The only console error was the existing non-blocking `/favicon.ico` 404.

### QA cleanup

- The temporary QA server was stopped.
- Demo records were removed from `quran_academy_test`; the test database was returned to an empty schema state.
- Temporary Playwright specifications and runner output were removed; implementation screenshots were retained as evidence.
final result: passed

## Madarak owner V1 - final workflow verification

### Evidence

- Weekly schedule: 	mp/madarak-owner-audit/implementation-scheduling.png.
- Four-measure evaluations: 	mp/madarak-owner-audit/implementation-evaluations.png.
- Team and role access: 	mp/madarak-owner-audit/implementation-team.png.
- Academy branding/settings: 	mp/madarak-owner-audit/implementation-settings.png.
- Teacher, student, and guardian portals: 	mp/madarak-owner-audit/implementation-teacher-portal.png, implementation-student-portal.png, and implementation-guardian-portal.png.
- Review viewport: 1600 x 1000, Microsoft Edge, authenticated Arabic RTL states.

### Result

- No actionable P0, P1, or P2 findings remain on the final V1 surfaces.
- The evaluation list preserves the nine-column Madarak contract and the one-step memorization, tajweed, attendance, and behavior workflow.
- Guardian reports expose only linked students and published evaluations. Teacher and student navigation remains role-isolated.
- Branding name and primary/secondary colors apply to the authenticated shell; slug, logo URL, and custom-domain fields are present in settings.
- All reviewed pages passed RTL, expected-column/field, horizontal-overflow, route-isolation, and browser-console checks.
- A missing Arabic default date format found during browser QA was fixed and covered by a request regression test.

final result: passed