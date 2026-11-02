# Omegaverse — Godot 2D Prototype

A fast, pastel-coloured, romance-themed top-down 2D prototype. **Godot 4.x / GDScript.**

## Design priorities
1. Playable immediately: one character, one small territory.
2. Collect simple resources, plant/harvest one crop, build a nest.
3. Nest completion percentage drives character happiness; pack happiness is a later, harder-to-achieve system.
4. Nest completion at a configurable threshold unlocks clearly visible scent trails. Higher influence eventually means better scent visibility and longer tracking distance.
5. The character starts **uncategorised**: the virus has left them with no Alpha, Beta, or Omega characteristics.
6. Soft pastel colours, rounded UI, minimal placeholder art; no asset purchasing or complex animation for MVP.

## Scope guardrails
- **No multiplayer, pack AI, romance system, complex virus evolution or full territory expansion in the first playable build.**
- One crop, a few resource types, four territory posts, basic nest progress, scent demonstration trail.
- Keep all thresholds and resource costs in one editable configuration script.
- Use original or openly licensed graphics; default to Godot-generated shapes.

## Confirmed lore
- Alpha 15%, Beta 75%, Omega 10% of population.
- Only Betas can potentially evolve into Alpha or Omega. Initial uncategorised-to-Beta transition is undefined; **do not invent its mechanics**.

## Getting started
Open the folder containing `project.godot` using Godot 4.x and run the main scene. The current starter is intentionally minimal; use `docs/CLAUDE_BUILD_PROMPT.md` to implement Stage 1.

## Source of truth
This GitHub repository is the source of truth for code. The linked Omegaverse Game Design Register Google Sheet is the design reference (especially `INITIAL GAME`, `Basics`, and `Background`). If design details are uncertain, document defaults rather than silently presenting them as established rules.
