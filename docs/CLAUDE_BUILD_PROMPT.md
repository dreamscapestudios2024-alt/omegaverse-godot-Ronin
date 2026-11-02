# Claude build prompt — Stage 1

You are the lead Godot 4 GDScript developer. Work **inside this existing repository** and commit your complete changes to GitHub. First inspect README.md, docs/DESIGN_DECISIONS.md, project.godot and existing scenes/scripts. Treat this repository as the source of truth for code. Keep the first iteration small, coherent and runnable.

**Goal:** Make an extremely simple but complete top-down 2D Omegaverse prototype, feasible as a single focused coding session. Gameplay matters more than art. Use only native Godot 4 nodes, GDScript, and primitive/placeholder graphics; no paid assets or external dependencies. Present the world with soft romantic pastel pink/lavender/cream/mint colours, clear readable text, and rounded panels wherever practical.

**Implement:**
1. One playable, initially uncategorised human character affected by a fictional virus, with no Alpha/Beta/Omega traits. Smooth WASD and arrow-key movement within a small grassy rectangular territory.
2. Clearly visible farm plot, nest location, 4 boundary posts and a few reusable resource nodes. Gather wood/grass/leaves using a nearby interaction key (E) and show inventory counters. Plant one crop, wait a short growth interval, then harvest it. Keep this very simple.
3. Build the nest by depositing gathered resources. Show a **nest completion percentage (0–100%)** in the HUD, plus a clear visual upgrade at major milestones. Nest completion increases **individual happiness (0–100%)**. Add a simple, visible happiness display. Do not yet implement multiplayer pack happiness, but document the future link and more difficult threshold.
4. Scent mechanic: disabled at the start. At a **configurable default** nest completion threshold (choose 50% and label it as provisional), unlock a visible scent mode (toggle with Q). Use an obvious pastel-glowing pre-placed sample scent trail (because we have only one character). Place four boundary posts which can be marked with E when nearby; show number marked. Keep scent visuals straightforward, not particles-heavy.
5. Influence: show a simple Influence value derived from happiness as a **prototype stand-in**, clearly named as provisional. Do not implement NPC persuasion. Longer-term, sphere of influence should improve visibility of other characters' scents and detectable trail distance. For this prototype, optionally increase the visible trail range based on the provisional influence meter, without adding NPC AI.
6. Provide an on-screen objectives checklist: gather materials → build nest → unlock scent → mark all four posts → harvest crop. Once complete, show a gentle success banner and allow restart.
7. Store costs, scent unlock percent, crop growth seconds and happiness/influence balancing constants together in `scripts/config.gd` or equivalent. Choose sensible prototype numbers and document them as provisional.

**Engineering constraints:**
- Godot 4.x compatible, no external addons; create any missing project scenes and scripts.
- Simple architecture: player movement, world interactions, and HUD can be separated into small scripts. Avoid overengineering.
- No biological transformation mechanic yet. Only Betas may eventually evolve into Alpha/Omega; don't accidentally implement Omega→Alpha transitions.
- No multiplayer, pack AI, romance NPCs, server, complex crafting tree, save system or advanced art in this first iteration.
- Protect against negative inventory, repeat harvesting before regrowth, duplicate post marking, and interaction at unrealistic distance.
- If Godot CLI is available, run import/headless checks; otherwise give reproducible editor test steps and mark untested items honestly.
- Commit all added/updated files and report the commit hash, files changed, how to run, controls, tested behaviour and known limitations. Do not claim tests ran unless they did.

**Definition of done:** Open `project.godot` in Godot 4, press Play, move, gather, farm, build/upgrade nest, see completion/happiness, unlock/show sample scent and mark 4 territory posts, with a visible finish condition. Focus on a complete playable vertical slice rather than features beyond scope.
