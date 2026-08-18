# Workspace Lens Design

Status: approved in conversation on 2026-08-18; awaiting review of this written
specification before implementation planning.

## 1. Problem and outcome

Omarchy's built-in workspace widget identifies workspaces by number and occupancy,
but does not reveal which applications occupy them. The user must visit a
workspace or remember its contents.

Workspace Lens will turn the same bar location into a compact application map.
The user should be able to identify the likely destination at a glance and hover
a workspace to inspect its application groups and window titles. The feature is
an Operate-mode desktop surface: scanability and stable interaction targets take
priority over decorative expression.

## 2. Scope

The first release will:

- replace the built-in `omarchy.workspaces` widget with a user-owned plugin;
- retain numbered workspaces 1–5 and occupied workspaces up to 10;
- show grouped application icons within each occupied workspace;
- limit the bar summary to three application icons and a `+N` overflow label;
- show grouped applications and their window titles in a hover popover;
- preserve click-to-focus behavior on each workspace;
- follow Omarchy theme, spacing, typography, and bar-position conventions;
- work from live Quickshell/Hyprland state without polling `hyprctl`.

The first release will not:

- add window-management actions to rows in the popover;
- rename workspaces or persist a separate workspace database;
- introduce an external daemon or polling process;
- modify files under `/usr/share/omarchy/`;
- replace the visual identity of the Omarchy bar;
- promise support for compositors other than Hyprland.

## 3. Packaging and ownership

The public repository is `JacobsenNando/workspace-lens`. The plugin identifier
is `jacobsennando.workspace-lens`. Its manifest sets
`omarchy.clonedFrom` to `omarchy.workspaces`, which makes Omarchy replace the
built-in widget while preserving its bar position.

Development files live in the repository. Installation copies only the runtime
plugin files into
`~/.config/omarchy/plugins/jacobsennando.workspace-lens/`. The installation flow
must never edit packaged Omarchy files. Enabling the plugin should replace the
built-in workspace widget without requiring the user to rearrange the bar.

## 4. Architecture

The feature is one plugin with three internal units:

1. **Workspace model** normalizes raw workspace/toplevel data, groups windows by
   application identity, resolves display metadata, sorts deterministic output,
   and calculates overflow.
2. **Bar summary** renders stable numbered workspace targets, up to three grouped
   application icons, focus state, hover state, and the overflow count. It owns
   click-to-focus behavior.
3. **Workspace popover** anchors to the hovered workspace target and renders the
   full grouped application list with window titles. It owns delayed open/close
   behavior but does not mutate window state.

The QML view must consume a small derived model rather than repeat grouping and
fallback rules inside delegates. Pure transformation logic should live in a
focused JavaScript module so it can be tested without rendering the shell.

## 5. Data flow and model contract

The plugin observes `Hyprland.workspaces` and each workspace's `toplevels` model.
Changes to workspaces, toplevel membership, active workspace, application ID, or
title cause the derived model to refresh through normal QML bindings/signals.
There is no timer-driven state collection.

For every visible workspace, the derived record contains:

- numeric workspace ID;
- focused and occupied flags;
- ordered application groups;
- total application and window counts;
- the first three application groups for the summary;
- remaining application-group count for `+N`;
- display label, icon source, and ordered window titles for every group.

The grouping key is a normalized application identifier. Prefer the toplevel
`appId`; trim whitespace, compare case-insensitively where appropriate, and use a
stable unknown key when it is absent. Browser-installed web applications remain
separate when Hyprland reports distinct application IDs.

Application display metadata is resolved against Quickshell desktop entries and
the Omarchy application library. The existing Omarchy icon resolver remains the
authority for icon paths and fallback behavior. Group ordering is stable:
preserve first appearance within the workspace unless the live API provides a
more reliable stacking order.

## 6. Interaction design

### Bar

- Every workspace retains a fixed, clickable target containing its number.
- Clicking anywhere in the target focuses that workspace, matching the built-in
  widget.
- Empty workspaces show only a subdued number.
- Occupied workspaces show their number followed by grouped application icons.
- A group with multiple windows carries a compact count badge.
- More than three application groups renders the first three plus `+N`; the
  target never expands indefinitely.
- The active workspace uses both a surface treatment and an accent underline so
  state is not conveyed through color alone.
- Hover uses a border/accent treatment without moving neighboring targets.

### Popover

- Hovering an occupied workspace for 180 ms opens a popover anchored to that
  workspace.
- Moving between workspace targets changes the content without first collapsing
  the popover into a flicker.
- Leaving both target and popover starts a 220 ms close delay, allowing the
  pointer to cross the anchor gap.
- The header shows workspace number plus application and window totals.
- Each application group shows icon, display name, optional window-count badge,
  and its window titles.
- Rows are informational in the first release. The workspace target remains the
  only navigation action.
- Empty workspaces do not open an empty panel.

## 7. Visual direction

The approved direction is **Workspace Lens**. It extends the incumbent Omarchy
bar rather than creating a new visual world.

- Use Omarchy `Style`, `Color`, font, spacing, corner, foreground, background,
  accent, and border primitives wherever available.
- On the current Hackerman theme, the direction reads as a dark navy surface,
  muted blue-gray inactive states, cool foreground text, and green accent. These
  values illustrate the result; they must not be hard-coded.
- Application icons are real desktop-entry icons at a compact, HiDPI-safe size.
- The popover is a single anchored surface with restrained separation between
  application groups. Avoid nested decorative cards.
- Window titles are single-line and ellipsized. Their complete value remains
  available through a native tooltip when truncated.
- Motion is limited to popover opacity/position and state transitions. It must
  respect reduced-motion settings when the shell exposes them.

The visual hierarchy is: workspace identity, application identity, group count,
then window title. The bar answers “where is the app?”; the popover answers
“which windows are there?”

## 8. Failure and edge states

- Missing application ID: derive a stable label when possible and use the
  generic executable icon.
- Missing title: show the application name instead of a blank line.
- Failed icon resolution: render the generic application icon without changing
  layout dimensions.
- Long names or titles: elide on one line; never widen the bar or popover beyond
  its bounded width.
- Workspace removed while hovered: cancel timers and close the popover.
- Toplevel removed during rendering: recompute the group; do not retain a stale
  row or count.
- No Hyprland data during shell startup: render the persistent workspace numbers
  and fill live data when it becomes available.
- Multiple monitors: preserve the built-in widget's global workspace list on
  every bar. Each popover anchors to the bar where the hover occurred and never
  appears on a different monitor.
- Vertical or bottom bar: follow the bar's existing orientation and anchor
  direction. If the full icon summary cannot fit a vertical bar, preserve the
  number and expose details through the same popover rather than clipping.

## 9. Accessibility and usability

- Focus and hover states use shape/surface differences in addition to color.
- Icon images expose application names to assistive tooling where QML support
  permits; decorative duplicates remain hidden from accessibility APIs.
- Workspace targets retain the built-in minimum hit area.
- The informational panel must not steal keyboard focus on hover.
- Text follows shell scaling and theme contrast rather than fixed pixel colors.
- Rapid pointer movement must not leave a stranded popover or produce repeated
  open/close flashing.

## 10. Verification

### Model tests

Test the isolated grouping/normalization module with fixtures for:

- empty workspace;
- one application and one window;
- repeated application with multiple windows;
- more than three application groups and correct `+N` value;
- missing IDs, titles, and icons;
- deterministic ordering after add/remove changes;
- web applications whose IDs must remain distinct.

### Functional verification

- Load the plugin through Omarchy Shell and confirm there are no QML/runtime
  errors.
- Verify click-to-focus across workspaces 1–5 and an occupied workspace above 5.
- Open, move, retitle, and close real applications; confirm immediate model and
  count updates without polling.
- Confirm open and close delays, movement between targets, and safe teardown of
  a hovered workspace.
- Verify top, bottom, and vertical bar behavior where supported by the existing
  bar implementation.
- Verify separate anchors and content on every connected monitor.

### Visual completion gate

The visual feature is complete only with all three forms of evidence required by
the project instructions:

1. functional behavior confirmed in the running Omarchy Shell;
2. screenshots compared with the approved Workspace Lens mockup and a
   representative sibling widget in the current bar;
3. real Hyprland data rendered, including Ghostty/WhatsApp or the applications
   present at verification time.

Capture one bounded screenshot round covering normal, hover, active, overflow,
and empty states. Fix material discrepancies in one batch and confirm with at
most one additional screenshot round.

## 11. Expected repository structure

```text
workspace-lens/
├── README.md
├── PRODUCT.md
├── manifest.json
├── BarWidget.qml
├── WorkspaceModel.js
├── WorkspacePopover.qml
├── tests/
│   └── workspace-model.test.js
└── docs/
    └── superpowers/specs/
        └── 2026-08-18-workspace-lens-design.md
```

The implementation plan may adjust filenames to follow concrete Omarchy plugin
loading constraints, but it must preserve the three module boundaries and the
behavior specified here.
