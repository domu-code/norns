# Norns Pocket v0.4 alpha

Android norns-inspired Lua runtime with an expanding, clearly attributed script library.

## What's new

- **Nine bundled scripts**, including five new community-inspired/ported instruments.
- **ZIP package import** via the Android document picker: files from the common top-level GitHub ZIP directory are extracted into their own app-local folder, with Lua libraries preserved. Imports are limited to 1,200 entries and 64 MB unpacked, and path traversal is rejected.
- **Recursive script browser** that finds scripts inside imported packages while hiding their `lib/` support files.
- **Script lifecycle cleanup**: when changing scripts, the previous script's `cleanup()` runs before the audio/grid are reset.
- **Additional compatibility** for older norns scripts: `metro.alloc`, `params/control`, `params/option`, and older `params:add_option` and `params:add_number` call forms.
- **LuaJ unit smoke tests** that load, initialise and redraw all nine bundled scripts with simulated host APIs.

## Bundled script library

| Script | Status / provenance | Main controls |
| --- | --- | --- |
| Pocket Grid | Original norns-compatible Android script | E1 tempo, E2 row, E3 length, K2 transport |
| Tape Garden | Original Android Softcut looper | E1 loop, E2 rate, E3 feedback, K2 record, K3 play |
| MIDI Monitor | Original Android MIDI diagnostics | Connect USB MIDI then MIDI SCAN |
| Sample Deck | Original Android sample playback | E2 rate, E3 duration, K2 play |
| **Walkabout (Android port)** | **Adapted from Darwin Grosse's original MIT-licensed Walkabout norns script**. See `LICENSE_Walkabout.txt`. | K2/K3 step, E2 sequence, E3 value, K1+E1 view/settings |
| Awake Pocket | Independently written adaptation of the Awake sequencer idea, **not** tehn's original code | E1 tempo, E2 root, E3 density, K2 run, K3 evolve |
| Meadowphysics Pocket | Independently written cascading-counter instrument, **not** the original norns/Ansible Meadowphysics | Grid rows set counter lengths, E1 tempo, E2 row, E3 cascade, K2 run, K3 reset |
| Bloom Pocket | New lightweight generative garden **inspired by schollz's MIT-licensed Bloom**; not its original DSP or script | Touch grid seeds, E1 root, E2 spacing, E3 evolution, K2 clear, K3 scatter |
| MLR Pocket | Original slice performer **inspired by monome mlr**; not original mlr or MLRE source | Grid rows 1–4 choose sample slices, 5–8 stop voices; E1 slices, E2 speed, E3 level |

These Pocket Editions are **reinterpretations, not unmodified copies** of the classic scripts. No original Awake, Meadowphysics, or mlr source code is bundled.

## Original project references

- Walkabout: https://github.com/darwingrosse/norns (MIT; licence bundled with the port)
- Awake: https://github.com/tehn/awake (link only; original not redistributed)
- Meadowphysics: https://github.com/dansimco/meadowphysics (link only; original not redistributed)
- Bloom: https://github.com/schollz/bloom (MIT; inspiration only)
- mlr: https://monome.org/docs/mlr/ (inspiration only)

## Installing other norns scripts

For straightforward Lua scripts, use **+ LUA**. For a repository downloaded as a GitHub source ZIP, use **+ ZIP PACKAGE**. The archive is unpacked into private app storage; the filename selector will list the detected main scripts. Nested `lib` scripts are available to `include()` but excluded from the main menu.

An imported script is **not guaranteed to execute**. Lua 5.3-only syntax, SuperCollider `Engine_*.sc` files, binary Lua modules, filesystem layout assumptions, arc/crow/i2c hardware, and APIs outside the current compatibility shim still require implementation or porting.

The Android audio engine remains a six-voice Softcut-inspired sampler, not norns' original DSP stack. External USB monome 64 and USB MIDI support remain device-dependent.

## Building from this repository

This version retains the original v0.3 source ZIP as the immutable baseline. GitHub Actions extracts that archive, applies the documented compiler fix, upgrades `LuaRuntime.java` and `MainActivity.java` using `patches/upgrade_v04.py`, and overlays newer source files under `overrides/app/`. The result is compiled and unit tested using Gradle 8.7 / Android SDK 35 / Java 17.

The next source-organisation milestone is committing the expanded Android project as ordinary source files and retiring the archive/patch build flow.

The repository PR is verified through GitHub Actions. Compilation and LuaJ smoke tests **do not replace testing the app and USB hardware on an Android device**.

This is an independent community compatibility project; it is not endorsed by monome or the authors of other referenced scripts.
