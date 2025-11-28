extends Node

var gravity: Vector2 = Vector2(0, 5.0)
var gravity_is_on: bool = true
var is_paused: bool = false
var default_cell_size: int = 10
var default_simulation_area: Vector2i = Vector2i(40, 30)
var default_particle_mass: float = 1.0
var default_particle_radius: float = 2.5
var time_step: float = 0.015
var lightspeed: float = ((default_particle_radius / time_step) / 2.0)*0.9
var max_accel: float = 2.0 * lightspeed / time_step

enum Items {REMOVEWALL, PARTICLE1, PARTICLE2, PARTICLE3, WALLNEUTRAL, WALLCOLD, WALLHOT, PUMP}
enum ItemPlaceMode {PARTICLE, WALL, PUMP}

# ++ = strong attraction
# + = weak attraction
# - = neutral / very weak
# -- = repulsive
# TODO: particle interactions: 
# 1-1: +
# 2-2: -
# 3-3: -
# 1-2: ++
# 1-3: --
# 2-3: ++
# TODO: force calculations with:
# Harmonic spring
# Morse potential * 
# Lennard-Jones
