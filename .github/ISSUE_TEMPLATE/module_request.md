---
name: Module request
about: Propose a new system framework/capability for the kit to cover
title: "Add <ModuleName>"
labels: enhancement
---

## Framework / capability

<!-- What system framework or app-behavior surface this would wrap, e.g.
     "NEHotspotConfiguration" or "ClassKit authorization". -->

## Does it fit this kit's pattern?

This kit only covers **non-prompting status reads** a `System<Name>`
implementation can safely expose — see the README's ["note on frameworks
this kit doesn't
cover"](https://github.com/EmilioBejasa/iOS_testing_suite#a-note-on-frameworks-this-kit-doesnt-cover)
for the line it draws (CarPlay, MultipeerConnectivity, and Core NFC were all
evaluated and excluded for lacking one). Before requesting, check:

- [ ] Does Apple expose a real authorization/status API for this (not just a
      one-shot prompt with no readable status)?
- [ ] Can a real implementation avoid triggering a system prompt or crash
      just by reading status?
- [ ] If neither is true, is there still a pure/deterministic utility shape
      that fits (like `JSONFixtureLoading` or `DeepLinkTesting`)?

## Why it's useful

<!-- What real app scenario would use this. -->
