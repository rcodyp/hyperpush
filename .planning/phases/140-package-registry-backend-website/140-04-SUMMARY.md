---
phase: 140-package-registry-backend-website
plan: "04"
subsystem: ui
tags: [vitepress, vue, tailwindcss, packages, registry, frontend]

# Dependency graph
requires:
  - phase: 140-package-registry-backend-website
    provides: Registry API at registry.meshlang.dev with GET /api/v1/packages and GET /api/v1/packages/{name} endpoints
provides:
  - VitePress /packages browse page with featured cards, full list, and debounced search
  - VitePress /packages/package?name= per-package detail page with metadata, install command, version history, README
  - PackageBrowse.vue, PackageCard.vue, PackageList.vue, PackagePage.vue components
  - Nav bar entry linking to /packages/
affects: [registry-frontend, website, packages-section]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - ClientOnly wrapping for all components that use fetch() or window.location
    - Runtime query param reading via URLSearchParams(window.location.search) — NOT VitePress build-time routing
    - 300ms debounce on search input to avoid hammering the registry API
    - Inline markdown renderer (escape HTML, then regex transforms for headers/code/bold/italic)

key-files:
  created:
    - website/docs/.vitepress/theme/components/packages/PackageBrowse.vue
    - website/docs/.vitepress/theme/components/packages/PackageCard.vue
    - website/docs/.vitepress/theme/components/packages/PackageList.vue
    - website/docs/.vitepress/theme/components/packages/PackagePage.vue
    - website/docs/packages/index.md
    - website/docs/packages/package.md
  modified:
    - website/docs/.vitepress/config.mts

key-decisions:
  - "Query param ?name= for per-package pages rather than file-based dynamic routing — VitePress SSG cannot pre-render dynamic package pages at build time"
  - "ClientOnly wrapping mandatory — components read window.location and call fetch(), both unavailable during SSR/SSG build"
  - "Inline markdown renderer (regex-based) for README — VitePress markdown-it is build-time only; no external markdown library added to keep bundle lean"
  - "Featured section shows top-6 packages (slice of API response sorted by downloads DESC on server side); search mode collapses to flat list"

patterns-established:
  - "Runtime-only data fetching pattern: ClientOnly + onMounted fetch + URLSearchParams for query params"
  - "Browse/detail page pair: index.md mounts browse component, package.md mounts detail component, both use ClientOnly"

requirements-completed: [REG-02, REG-03, REG-04]

# Metrics
duration: 3min
completed: 2026-03-01
---

# Phase 140 Plan 04: Package Registry Website Pages Summary

**Four Vue 3 components with Tailwind CSS zinc/violet palette delivering /packages browse + search page and /packages/package?name= detail page wired to the registry API via runtime fetch**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-01T05:05:05Z
- **Completed:** 2026-03-01T05:07:25Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- /packages browse page: featured grid (top 6 by downloads), full package list, search input with 300ms debounce calling GET /api/v1/packages?search=
- /packages/package?name= detail page: metadata card with install command + copy-to-clipboard, latest version badge, download count, author link to GitHub, expandable version history, README rendered as HTML
- All components wrapped in ClientOnly to prevent SSR/build-time fetch failures
- Packages nav entry added to VitePress config.mts nav array

## Task Commits

Each task was committed atomically:

1. **Task 1: PackageBrowse, PackageCard, PackageList components + /packages index** - `f3c6520d` (feat)
2. **Task 2: PackagePage component + per-package page + nav config** - `7e72165d` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `website/docs/.vitepress/theme/components/packages/PackageBrowse.vue` - Browse/search landing with featured cards, list, debounced search, loading/error/empty states
- `website/docs/.vitepress/theme/components/packages/PackageCard.vue` - Featured package card with click-to-navigate, version badge, download count, owner link
- `website/docs/.vitepress/theme/components/packages/PackageList.vue` - Compact row list for all-packages section and search results
- `website/docs/.vitepress/theme/components/packages/PackagePage.vue` - Full per-package detail: metadata card, install+copy, version history expand, README markdown
- `website/docs/packages/index.md` - VitePress page mounting PackageBrowse via ClientOnly
- `website/docs/packages/package.md` - VitePress page mounting PackagePage via ClientOnly
- `website/docs/.vitepress/config.mts` - Added nav array with Docs and Packages links

## Decisions Made

- Query param pattern (`?name=owner/package-name`) chosen over file-based dynamic routes — VitePress SSG cannot enumerate registry packages at build time; runtime URL reading via `URLSearchParams` is the correct pattern
- Inline markdown renderer (regex transforms on escaped HTML) used for README rendering — VitePress's markdown-it is build-time only; adding a full markdown library would increase client bundle size unnecessarily for v1
- Featured section: top-6 slice of the API response (server already returns sorted by downloads DESC); search mode collapses featured section entirely and shows flat list with result count
- `<ClientOnly>` wrapping required for all four components because they access `window.location.search` and call `fetch()` — both unavailable during VitePress SSG rendering

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - VitePress build succeeded on first attempt for both tasks.

## User Setup Required

None - no external service configuration required. Pages are static HTML that fetch from the live registry at runtime.

## Next Phase Readiness

- REG-02 (browse), REG-03 (search), REG-04 (per-package page) all satisfied
- Website packages section is live-data-driven; works as soon as the registry backend (plans 01-03) has packages published
- Phase 140 fully complete after this plan

---
*Phase: 140-package-registry-backend-website*
*Completed: 2026-03-01*

## Self-Check: PASSED

- All 4 Vue component files: FOUND
- Both VitePress pages (index.md, package.md): FOUND
- SUMMARY.md: FOUND
- Task commits f3c6520d and 7e72165d: FOUND in git log
