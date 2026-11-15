# SLAMFORGE

**3D third-person forge climber.** Slam to forge glowing platforms under you, chain aerial slams for height combos, dodge spinning hazard blades, and beat the rising magma to the summit beacon.

Godot **4.7.2** · typed GDScript · procedural meshes  
Repo: https://github.com/bwritten95-stack/slamforge

## Hook
Every slam is **attack + level geometry**. Miss the rhythm and the melt eats you.

## Controls
| Action | Input |
|--------|--------|
| Move | WASD |
| Look | Mouse |
| Jump | Space |
| Slam | LMB / F / Ctrl |
| Pause | Esc |

## Loop
Menu → climb tower (forge pads + ring ledges) → dodge hazard spinners → summit beacon win **or** magma/blade death → results

## Run
```bash
godot --path .
godot --path . -- --ship-test
```

## Exports
| Target | How |
|--------|-----|
| Linux x86_64 | `godot --headless --path . --export-release "Linux/X11" export/Slamforge.x86_64` |
| Web | `godot --headless --path . --export-release "Web" export/web/index.html` then serve `export/web/` over HTTP |

Release builds: https://github.com/bwritten95-stack/slamforge/releases
