# Workspace Lens

<!-- impeccable:product-schema 1 -->

## Platform

Linux desktop, implemented as an Omarchy Shell widget in Quickshell/QML and
backed by Hyprland workspace state.

## Users

The primary user runs an Omarchy desktop, switches frequently between numbered
workspaces, and needs to recognize where an application is without visiting
each workspace.

## Product Purpose

Make the application distribution across workspaces understandable at a glance.
Success means the user can choose the intended workspace confidently from the
bar and reveal window-level detail without leaving the current workspace.

## Positioning

Unlike a workspace indicator that reports only occupied numbers, Workspace Lens
maps grouped application identities to their workspaces and reveals the
underlying windows contextually.

## Operating Context

- Omarchy 4 with a transparent top bar.
- The workspace widget sits in the left section beside the Omarchy menu.
- Hyprland supplies live workspaces, application identifiers, window titles,
  focus state, and window counts.
- The current workspace model keeps workspaces 1–5 visible and adds occupied
  workspaces up to 10.

## Capabilities and Constraints

- Preserve direct workspace switching from the bar.
- Group multiple windows from the same application and show a count.
- Keep a compact summary visible in the bar.
- Reveal the hovered workspace in a contextual detail panel with applications
  and window titles.
- Remain readable when application names or window titles are long.
- Keep user-owned customization under `~/.config/omarchy/`; packaged files under
  `/usr/share/omarchy/` remain read-only.

## Evidence on Hand

Live Hyprland data confirmed Ghostty in workspace 1 and the WhatsApp web
application in workspace 2 during discovery. No synthetic claims or external
product assets are required.

## Product Principles

- Spatial recognition before decoration.
- Stable targets: hovering must not shift workspace controls.
- Progressive disclosure: identity in the bar, detail in the hover panel.
- Density without clutter through grouping and explicit overflow.
- Native behavior and theme tokens over a visually isolated custom surface.

