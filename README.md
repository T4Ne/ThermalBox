# ThermalBox
A high-performance particle and thermal fluid effects simulator built with Godot 4.5 and C++ (GDExtension).

<img width="1161" height="861" alt="Screenshot 2025-12-17 014907" src="https://github.com/user-attachments/assets/bd2eb36d-d4c3-472c-8b55-0f37f6b2a43a" />


## 1. Technical Architecture (GDExtension Components)
The simulation logic is decoupled from Godot's built-in physics and implemented via custom C++ classes:
* **WorldState**: Manages the global simulation data, including particle positions (`PackedVector2Array`), velocities, and cellular grid states (e.g., `NORMWALL`, `COLDWALL`, `SPAWNER`).
* **MovementHandler**: Executes physics calculations using **Verlet Integration**. It handles inter-particle forces (Weak/Strong Lennard-Jones and Repulsion) and interactions with specialized cells like Pumps and Diodes.
* **Scheduler**: Controls the simulation time-step and distributes workloads across chunks for multithreaded processing.
* **Chunk**: Acts as a data-parallel unit representing specific segments of the grid to optimize cache locality and thread distribution.

## 2. Input Mapping
The following hardware inputs are hardcoded in `project.godot`:

| Action | Input | Function |
| :--- | :--- | :--- |
| **Simulation Toggle** | `Space` | Pause or resume the physics processing. |
| **Primary Action** | `Left Click` | Place particles or interact with the grid. |
| **Secondary Action** | `Right Click` | Secondary interaction (e.g., removal or alternative placement). |
| **Clear Particles** | `E` | Instantly deletes all active particles in the simulation. |
| **Toggle Big Selection** | `Q` | Switches between single-cell and multi-cell selection modes. |
| **Toggle Gravity** | `G` | Enables or disables the downward acceleration vector. |
| **Toggle Cooling** | `C` | Activates global thermal energy reduction. |

## 3. Installation and Compilation

### Environment Requirements
* **Godot Engine**: Version 4.5 (configured for GL Compatibility mode).
* **Build Tool**: SCons (for compiling the GDExtension).
* **Dependencies**: You **must** have the `godot-cpp` library installed and correctly path-linked in your environment to compile the source code.

### Running the Project
1. **Via Executable**: Run the binaries located in the `executables/` directory.
2. **Via Godot Editor**: Open `project.godot` in the Godot 4.5 editor. Ensure the `sim_module.gdextension` file is recognized. Run the main scene (`main_box.tscn`).

### Compiling from Source
Navigate to the `gdextension/` directory and execute the following:
```bash
scons platform=<your_platform> target=template_debug
```

## 5. License
This project is released under the CC0 1.0 Universal (CC0 1.0) Public Domain Dedication. You may copy, modify, and distribute the code without restriction.
