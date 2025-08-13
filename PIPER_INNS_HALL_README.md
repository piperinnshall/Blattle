# Assignment 1

**Course:** CGRA252  
**Student:** Piper Inns Hall
**Name:** Blattle

---

## Project information
- **Project:** CGRA252 / 2025 / Assignment 1  
- **Commits:** 6  
- **Branches:** 1  
- **Tags:** 0

---

# Table of contents
- [Overview](#overview)  
- [What I built (Game description)](#what-i-built-game-description)  
  - [Controls (Player 2)](#controls-player-2)  
  - [Player / AI architecture summary](#player--ai-architecture-summary)  
  - [Design patterns used](#design-patterns-used)  
- [Main game mechanic](#main-game-mechanic)  
- [Hardest part to implement](#hardest-part-to-implement)  
- [Most interesting part](#most-interesting-part)  
- [Reflection on learning](#reflection-on-learning)  
- [Video demo](#video-demo)  
- [Course / Assignment details](#course--assignment-details)  
- [Notes for assessors](#notes-for-assessors)

---

# Overview
This repository contains my contribution to **Blattle**, a local two-player fighting prototype built in **Godot 4.4** (team project for CGRA252). My primary work was implementing **Player 2** (human-controlled) and a reusable **AI fighter system**, plus the attack system and architecture that lets both human and AI fighters share behaviour cleanly.

---

# What I built (Game description)

**Blattle** is a short prototype where two fighters face off in a small arena. The project contains:
- A `Character` base class that encapsulates movement, physics and health logic.
- A `Player` subclass used for Player 2 (I implemented this).
- An `AICharacter` subclass that replaces player input with an AI brain so the game can run in AI mode.
- A modular attack system (`BaseAttack` → `LightAttack` / `HeavyAttack`) that can be extended by writing short scripts and assigning them in the editor.

## Controls (Player 2)
- Movement: `I` `J` `K` `L`  
- Light attack: ``;`` (semicolon)  
- Heavy attack: `'` (single-quote)  
- Dash: `Enter`

> Player 1 (human) was implemented by my teammate Leo and uses a separate control mapping.

## Player / AI architecture summary
- `Character` (base): movement, collision/physics, health, animation hooks and attack handling.
- `Player` (human): adds input handling on top of `Character`.
- `AICharacter` (AI): replaces input with a **State-based** brain that decides actions (idle, chase, attack, retreat, etc.) and calls the shared `Character` APIs to move/attack.
- Attack system: `BaseAttack` is extended by `LightAttack` and `HeavyAttack`. Attacks are assigned to characters in the editor as separate scripts/resources.

## Design patterns used
- **Strategy Pattern** — movement and attack behaviours are detachable strategy components. I can swap a character’s movement or attack implementation in the editor without modifying the base `Character` code.
- **State Pattern** — the AI brain runs as a state machine (idle → chase → attack → retreat). Each state encapsulates its decision rules and transitions.
- **Inheritance / Componentized Attacks** — `BaseAttack` with concrete subclasses (light/heavy). Adding new attacks is done by creating a new subclass/script and assigning it to the character.

This structure lets human and AI fighters reuse the same movement, animation and attack code while differing only in input source and decision logic.

---

# Main game mechanic
The core mechanic I focused on: a responsive AI fighter system that feels like a real opponent. The AI:
- Observes Player 1’s position and state.
- Decides when to dash-in, use light or heavy attacks, or retreat.
- Can interact with dynamic world objects (the ball, drones) so the match feels emergent rather than scripted.

This makes single-player practice against the AI feel like a real match rather than a passive demo.

---

# Hardest part to implement
The biggest challenge was integrating a clean **State Pattern** AI with Godot’s scene and inheritance system while keeping `Character` as the single source of movement/attack/animation logic. I wanted to:
- Keep `Character` responsibility focused (physics, animation, health).
- Let `AICharacter` override only the input/decision layer.

The difficulty came from ensuring the AI states could trigger character animations, root motion, dashes and attacks without duplicating movement or animation code. Once the architecture was settled (AI states call `Character` APIs rather than manipulate internals directly), adding new AI behaviours became straightforward.

---

# Most interesting part
Because movement and attack behaviour are strategy components, I can create entirely different fighters by swapping scripts in the editor. The AI can be given any of those strategies, so new opponent types are cheap to make — a very flexible system for prototyping distinct fighters quickly.

---

# Reflection on learning
Before this project I had not structured a Godot game with formal design patterns. Key takeaways:

- Implemented the **state pattern** in Godot for modular AI decision-making; states are easy to add and test.
- Used the **strategy pattern** to swap attack and movement components without rewriting `Character`.
- Improved my understanding of inheritance and composition in Godot so multiple character types share core logic but keep separate control layers.
- Set up autoloads for global sound management across scenes.
- Built a main menu and settings menu with sliders and toggles connected to Godot’s audio bus system.
- Learned practical workflow with Git (regular commits, useful commit messages, using issues to document learning progress).

---

# Video demo
**Link to video:** *(place your video link here — OneDrive / YouTube / Vimeo / Google Drive, please include access permissions in the repo)*

> Recommended length: 4–9 minutes. The video should demonstrate the prototype, show the code contribution, and explain what you learned.

---

# Course / Assignment details (provided spec)
**Assignment:** Assignment 1 — Due 8th August — 25%  
**Objective:** Learn to use a game engine (Unreal 5.6 or Godot 4.4). Produce a project demonstrating engine integration and learning. Use gitlab.ecs.vuw.ac.nz for repo and regular commits.

## Required submission README contents (this file contains the required information)
- Course code: **CGRA252**  
- Your name: **Simon McCallum**  
- Assignment number: **Assignment 1**  
- Title of the Technology / Game: **Piper Inns Hall — Blattle**  
- Link to video: *(add link here)*  
- Game Description: *(see above sections)*  
  - What is the main game mechanic: AI fighter system + modular character system.  
  - What was the hardest part to get working: AI state integration with Godot scenes and character architecture.  
  - What is the most interesting part: flexible strategy-pattern based swapability of movement/attack systems.  
- Reflection on learning: *(see Reflection on learning section above)*

## Marking rubric (for reference)
- Managing Inputs (I) — 25%  
- World Update (U) — 25%  
- Managing Outputs (O) — 25%  
- Integration of the Engine (E) — 25%  
- Video multiplier: 0.0 – 2.0

---

# Notes for assessors / future work
- The architecture supports fast iteration on new fighter types: create or swap movement/attack scripts in the editor to prototype new behaviours in minutes.
- The AI system currently focuses on positional and cooldown-based decision-making; future work could add prediction, combo-planning, and difficulty scaling.
- To test: run Play mode (human vs human) and AI mode (human vs AICharacter) to see both code paths share animation, physics and attack handling.

