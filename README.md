# ♠ Truco2D

**Truco2D** is a digital 2D adaptation of the classic card game **Truco Paulista**, built with **Godot Engine v4.4.1**.  
Designed for both single-player and multiplayer play, it features animated cards, bots with multiple difficulty levels, and follows the [official rulebook](https://www.jogatina.com/regras-como-jogar-truco.html).

---

## 🎮 Overview

Truco is a legendary Brazilian card game full of strategy, bluffing, and energy. This project brings it to life on desktop and mobile with:

- Local and online matches
- Turn-based logic and AI-controlled opponents
- Modular, scalable 2D architecture
- Ready for mobile and desktop deployment

---

## ✨ Features

✅ Truco Paulista rules faithfully implemented  
✅ Multiplayer rooms (host or join by code)  
✅ Bots with 4 difficulty levels (Easy, Normal, Hard, Expert)  
✅ 2D interface with smooth card interactions and hover effects  
✅ Post-match menu for rematches with bot level options  
✅ Designed for Android and Steam compatibility  

---

## 🗂️ Project Structure

```bash
Truco2D/
├── assets/               # Card textures, UI, sounds
├── scenes/
│   ├── main.tscn         # Main 2D gameplay scene
│   ├── deck.tscn         # Deck node
│   ├── card.tscn         # Card prefab
│   └── menu.tscn         # Menu interface
├── scripts/
│   ├── main.gd           # Core logic (turns, hands, UI)
│   ├── card.gd           # Card hover/flip behavior
│   ├── gameManager.gd    # Score system, Pe, round logic
│   └── network.gd        # Multiplayer logic (WIP)
├── ui/                   # Label, Score, Button, Panel nodes
├── project.godot         # Godot configuration
└── README.md             # You're here!
```

---

## 🚀 Getting Started

### ✅ Requirements

- [Godot Engine v4.4.1](https://godotengine.org/)
- Vulkan-compatible GPU
- (Optional) Android SDK for mobile deployment

### 🛠 Setup Instructions

```bash
# 1. Clone the repository
git clone https://github.com/LeMajaw/Truco2D.git
cd Truco2D

# 2. Open Godot and import the project
#    (Choose the project.godot file from the cloned folder)

# 3. (Optional) Setup Android export templates
#    - Install Android SDK & export templates
#    - Configure paths in Godot > Editor > Editor Settings > Android

# 4. Run the game
#    - Press F5 to test on desktop
#    - Use Export or F6 to run on Android device
```
