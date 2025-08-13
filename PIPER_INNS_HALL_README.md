# Assignment 1

**Course:** CGRA252  
**Student:** Piper Inns Hall
**Name:** Blattle

---

## Project information

- **Project:** CGRA252 / 2025 / Assignment 1  
- **Main Commits:** 33
- **Branches:** 9  

---

# Table of Contents

1. [Overview](#overview)
2. [What I Built (Game Description)](#what-i-built-game-description)
   1. [Controls (Player 2)](#controls-player-2)
   2. [Player / AI Architecture Summary](#player--ai-architecture-summary)
      1. [Inheritance-Based Design](#inheritance-based-design)
      2. [Composition-Based Design](#composition-based-design)
      3. [Design Patterns Used](#design-patterns-used)
3. [Main Game Mechanic](#main-game-mechanic)
4. [Hardest Part to Implement](#hardest-part-to-implement)
5. [Most Interesting Part](#most-interesting-part)
6. [Reflection on Learning](#reflection-on-learning)
7. [Video Demo](#video-demo)

---

# Overview

This repository contains the code for **Blattle**, a local two-player fighting
prototype built in **Godot 4.4**. My primary work was implementing **Player 2**
(human-controlled) and an **AI fighter system**, plus the attack system and
architecture that lets both human and AI fighters share behaviour cleanly.

---

# What I built (Game description)

- A `Character` base class that encapsulates movement, physics and
  health logic.
- A `Player` subclass of `Character` used for Player 2.
- An `AI` subclass of `Charachter` that replaces input with an AI
  brain so the game can run in AI mode.
- A modular attack system (`LightAttack` / `HeavyAttack` inherits from
  `Attack`) that can be extended by writing short scripts and assigning them
  in the editor. 
- The Main Menu. 
-In Game music handling.

## Controls (Player 2)

- Movement: `I` `J` `K` `L`  
- Light attack: ``;`` (semicolon)  
- Heavy attack: `'` (single-quote)  
- Dash: `Enter`

> Player 1 was implemented by my teammate Leo and uses a separate control mapping.

## Player / AI architecture summary

### Inheritance based design

- `Character` (base): movement, physics, health, and behaviour handling,
  as well as a "buffered input" system.
- `Player` (human): adds input handling on top of `Character`.
- `AICharacter` (AI): replaces input with a **State-based** brain that
  decides actions (idle, chase, attack, retreat, etc.) and calls the shared
  `Character` APIs to move/attack.
- Attack system: `Attack` is extended by `LightAttack` and
  `HeavyAttack`. Attacks are assigned to characters in the editor as separate
  scripts/resources.

### Compositon based design

The `jump`, `dash` and `attack` (Separate to the `Attack` class) are
dubbed: "behaviours". They are Godot `Resources` Nodes, that can be drag and
dropped onto my `Character` class. The `Character` does not need to know
what resource it has, because each resource has the same base functions:
`update()`, and `perform()` Because  of this I can easily prototype many
different resources, and create different types of player characters with
different abilities, as standard in 2d platform fighters such as Super Smash
Bros. This is a clear example of composition, mixed with the strategy pattern.

### Design patterns used

- **Strategy Pattern**: movement and attack behaviours are detachable
  strategy components. I can swap a character’s movement or attack
  implementation in the editor without modifying the base `Character` code.
- **State Pattern**: the AI brain runs as a state machine (idle > chase >
  attack > retreat). Each state encapsulates its decision rules and
  transitions.

This structure lets human and AI fighters reuse the same movement, animation
and attack code while differing only in input source and decision logic.

---

# Main game mechanic

The core mechanic I focused on: a responsive AI fighter system that feels like
a real opponent. The AI:
- Observes Player 1’s position and state.
- Decides when to dash-in, use light or heavy attacks, or retreat.
- Can interact with dynamic world objects (the ball, drones) so the match
  feels emergent rather than scripted.

This makes single-player practice against the AI feel like a real match rather
than a passive demo.

---

# Hardest part to implement

The biggest challenge was integrating a clean **State Pattern** based AI with
Godot’s inheritance system while keeping `Character` as the single source of
movement/attack/animation logic. 

I wanted to:
- Keep `Character` responsibility focused on physics, animation, health.
- Let `AI` override only the input layer.

The difficulty came from ensuring the AI states could trigger character
animations, root motion, dashes and attacks without duplicating movement or
animation code. Once the architecture was settled (AI states call `Character`
APIs rather than manipulate internals directly), adding new AI behaviours
became straightforward.

---

# Most interesting part

The dash, jump, and attack behaviours are strategy components, built using
Godot's `Resources` Nodes. Because  of this I can create entirely different
fighters by swapping scripts in the editor. The AI can be given any of those
strategies, so new opponent types are cheap to make. This creates a very
flexible system for prototyping distinct fighters quickly.

---

# Reflection on learning

Before this project I had never used formal design patterns, or inheritance, in
a Godot project. I implemented a state pattern for the AI, which makes decision
logic modular and states easy to add and test. I used the strategy pattern so
jump, dodge, and attack behaviours can be swapped without modifying the Character
base class. I improved my understanding of inheritance and composition in Godot
so different character types share core logic while keeping separate control
layers. The attack system uses inheritance too, with a base `Attack` class
extended by `LightAttack` and `HeavyAttack`. I set up "autoloads" for the
first time for global sound management so audio persists across scenes, and I
built a main menu and settings menu with sliders and toggles hooked into
Godot’s audio bus system. This was my first ever menu in Godot as well.

Overall, I learnt a lot making this project, and I have gotten significantly
better at Godot while doing so. I hope to take these learned skills and use
them in many more projects to come.

---

# Video demo

[**Link to video**]() 

---

