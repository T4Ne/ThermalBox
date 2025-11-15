extends Node

var gravity: Vector2 = Vector2(0, 10.0)
var gravity_is_on: bool = true
var is_paused: bool = false
var default_cell_size: int = 10
var default_simulation_area: Vector2i = Vector2i(40, 30)
var default_particle_mass: float = 1.0
var default_particle_radius: float = 2.5
var interaction_range: float = 7.0 * default_particle_radius
var particle_1_interaction_params: Array = [0.0, 0.0, 0.0]

enum Params {A, D, R}
enum Items {NONE, PARTICLE1, PARTICLE2, PARTICLE3, WALL}

# ++ = strong attraction
# + = weak attraction
# 0 = neutral / very weak
# – = repulsive
# TODO: particle interactions: 
# 1-1: ++ 
# 2-2: 0 
# 3-3: -
# 1-2: +
# 1-3: ++
# 2-3: +
# TODO: force calculations with:
# Harmonic spring
# Morse potential * 
# Lennard-Jones
