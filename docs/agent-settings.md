# Agent preferences

Agent instructions, agents, prompts, and shared skills are owned by
[agent-kit](https://github.com/drucedev/agent-kit) and installed from its
checkout:

```sh
cd ~/.agent-kit
./scripts/install.sh all --profile personal
```

This repo only carries provider-neutral Claude Code, Pi, and T3 Code preference
templates in `common/.local/share/agent-settings/`. Stow installs the templates and the
`apply-agent-settings` command; live settings remain ordinary machine-local files.
The command uses only Node.js built-ins (already required by Pi), with no extra
packages or Python dependency. Stop the affected apps before writing:

```sh
apply-agent-settings all --dry-run
apply-agent-settings all
# Or select only one app:
apply-agent-settings claude
apply-agent-settings pi
apply-agent-settings t3
```

The command also works directly from this checkout before stowing:

```sh
./common/.local/bin/apply-agent-settings all --dry-run
```

## Merge behavior

Applying overwrites template-owned preferences, recursively merges objects,
and preserves fields absent from the templates. Claude's additional local
permission denials are retained. Pi's local packages and resource choices are
retained; shared choices take precedence on matching resources, and matching
package sources receive the shared filters. Reapplying unchanged settings does
not rewrite them. Every changed existing file gets an exclusive, mode-600
`settings.json.<random>.bak` or `client-settings.json.<random>.bak` beside it.
Backups can contain credentials: keep them local. Invalid JSON or symlinked
settings/parent directories abort validation before any settings are written.

Excluded from the templates: provider/model selections and overrides,
provider-specific packages/options, authentication, MCP servers, histories,
trust state, identities, onboarding, window geometry, and project-specific state.
Existing local values are preserved, not removed. Pi's generic thinking-level
preference is included. T3's cleanup policy is included (eight days and cleanup
on merge/delete); review it before applying on another machine.

No agent state directories or T3 keybinding defaults are copied.

## Pi theme

Pi's Catppuccin Mocha theme is linked separately at
`~/.pi/agent/themes/catppuccin-mocha.json`. If a regular file already occupies
that path, back it up outside the Stow package before stowing; do not use
`stow --adopt` on live agent settings. Pi's theme and extension choices target
Pi 1.4.x; Claude preferences include version-dependent built-in controls.
Pi packages are installed by Pi separately; the Git package requires SSH access.

## Validation

Runs the installer in temporary homes (no real settings are changed):

```sh
node --test test/agent-settings.test.cjs
```
