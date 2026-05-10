# JARVIS — ComputerCraft AI Assistant

A chat-driven AI assistant for ComputerCraft: Tweaked, with a 7-monitor HUD, AE2 network integration, redstone-controlled lights, and speaker melodies.

## What it does

Type `jarvis <command>` in Minecraft chat (within range of the chatBox) and JARVIS will respond. He greets you, tells jokes, quotes Shakespeare, monitors your AE2 network, controls your base lights, plays melodies, and runs diagnostics — all displayed live across seven monitors.

## Required mods

- **CC: Tweaked** — the base mod
- **Advanced Peripherals** — for the chatBox, ME Bridge, and Redstone Integrators
- **Applied Energistics 2** — the storage network JARVIS reports on
- **CC:C Bridge** — for future Create mod integration

## Required peripherals (wired to the computer via Wired Modems)

| Peripheral | How many | What it's for |
|---|---|---|
| Chat Box | 1 | Reading chat commands and speaking back |
| ME Bridge | 1 | Reading AE2 storage and energy data |
| Speaker | 1 | Melodies and sound effects |
| Redstone Integrator | 1+ | Each one controls one set of lights |
| Monitor | 7 | HUD, commands list, storage, energy, last response, clock, lights |

## Monitor layout

JARVIS auto-detects monitors by their aspect ratio, but you can override the assignments at the top of `main.lua` by setting the `CFG_*` variables to specific peripheral names like `"monitor_3"`.

| Role | Suggested size | Purpose |
|---|---|---|
| `helpMon` | 4×5 | Command list |
| `faceMon` | 4×4 | JARVIS HUD with spinning rings |
| `stoMon` | 2×6 (portrait) | AE2 storage bar |
| `energyMon` | 3×3 | AE2 energy bar |
| `lastMon` | 1×3 (portrait) | Last response display |
| `clockMon` | 2×1 (very wide) | Minecraft clock |
| `lightsMon` | 1×1 | Lights status |

## Installing on your CC computer

1. Place a computer next to your peripherals (or wire them with networking cables)
2. Run this **once** to install the auto-updater:
   ```
   wget run https://raw.githubusercontent.com/JustAStickmin/Jarvis-CC/main/update.lua
   ```
3. After that, just run `update` to pull the latest code from GitHub
4. Run `main` to launch JARVIS

## Available commands

Type any of these in chat after `jarvis`:

**General:** `time`, `day`, `status`, `threat`
**Fun:** `joke`, `quote`, `shakespeare`, `define`, `compliment`, `roast`, `warn`, `diagnose`, `flip`, `roll`
**Lights:** `lights on`, `lights off`
**AE2:** `energy`, `storage`, `items`, `find <item>`, `network`
**Audio:** `beep`, `alarm`, `fanfare`, `music`, `victory`, `play <sound>`, `stop`
**System:** `help`, `shutdown`

## Project structure

(Once we split the original 700-line file into modules, this section will list each file and what it owns.)

## Contributing

This is a two-person project. We use feature branches and pull requests:

1. Pull `main` (in GitHub Desktop: **Fetch origin → Pull origin**) before starting work
2. Make a new branch: `yourname/feature-name`
3. Commit your changes to that branch
4. Push and open a Pull Request on github.com
5. The other person reviews and merges

Don't commit directly to `main`.

## Credits

Built by Willie and friend. JARVIS personality and command structure adapted for the ComputerCraft ecosystem.
