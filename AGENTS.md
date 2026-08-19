# Repository Guide

## Project

- This is a Godot 4.7 RTS written in GDScript. The main scene is `res://maps/M2Map.tscn`.
- `PLAN.md` is the gameplay and technical design baseline; `LORE.md` owns world and character canon. Check the running code and recent history before trusting milestone status text in `README.md`.
- Keep the game readable as a 2D top-down pixel-and-ink RTS. Do not introduce HD-2D, 3D scenes, or depth-of-field effects.

## Layout

- `maps/`: playable maps and scene composition.
- `units/`, `buildings/`, `ai/`: runtime actors and behavior.
- `systems/`: shared rules, input, navigation, selection, camera, and victory state.
- `data/defs.gd`: central unit, building, and faction definitions plus the unit factory.
- `art/`: procedural drawing and shaders; `ui/`: HUD and controls.
- `tests/`: standalone Godot test scenes that exit nonzero on failure.

## Commands

```powershell
# Run the game or open the editor
godot --path .
godot --editor --path .

# Import resources and catch parse/load errors
godot --headless --editor --path . --quit

# Run one focused test
godot --headless --path . res://tests/TestCombat.tscn

# Run the complete test-scene suite, failing fast
Get-ChildItem tests/Test*.tscn | ForEach-Object {
    & godot --headless --path . "res://tests/$($_.Name)"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
```

Use Godot 4.7.x; the locally verified version is 4.7.1.

## Conventions

- Follow the existing thin-scene pattern: compose nodes in GDScript and add `.tscn` structure only when it improves editor-authored content.
- Use tabs for GDScript indentation, `snake_case` for files/functions/variables, and `PascalCase` for `class_name` types.
- Prefer typed GDScript at public boundaries and where inference is ambiguous. Keep comments short and focused on non-obvious rules.
- Keep player-facing text, design docs, and domain comments in Chinese; identifiers remain English except for the established element values (`金木水火土凡`).
- Reuse `Defs`, `Elements`, `NavRegistry`, and existing node groups before adding new helpers or abstractions.
- Preserve Godot `.uid` files for tracked scripts and scenes. Never commit `.godot/` cache or exported builds.

## Change Discipline

- Inspect `git status` before editing. Preserve unrelated user changes and stage only files belonging to the task.
- For gameplay changes, add or update the smallest relevant standalone test scene. Run that test plus any directly affected navigation, economy, combat, AI, or victory tests.
- For shared systems or scene-loading changes, run the headless import check and the complete test suite.
- Do not silently change faction identity, elemental counters, economy, or unit/building contracts; reconcile those changes with `PLAN.md` and `LORE.md`.
