## What this changes

<!-- One or two sentences: what module/fix/doc this PR covers. Per CONTRIBUTING.md, keep one module or fix per PR where practical. -->

## Checklist

- [ ] If this adds a module: `Sources/<ModuleName>/` follows the standard
      protocol + `System<Name>` + `Mock<Name>` shape (or is documented as a
      single-file utility exception in CONTRIBUTING.md)
- [ ] `Package.swift` and `project.yml` both reference the new target/product
- [ ] A test exercises it, under `QuoteBoxTests/<ModuleName>Tests.swift` or
      via an existing test file, or a **Scope note** explains why it's
      kit-level only
- [ ] A `### \`ModuleName\`` section was added to the README in the correct
      themed group, with body order matching the table-of-contents order
- [ ] Any deliberate limitation is called out with a **Scope note**, matching
      this repo's documented-not-hidden-gaps convention
- [ ] `gh pr checks` is green (or the failure is an already-known flake)

## Test plan

<!-- How you verified this, or how a reviewer can. -->
