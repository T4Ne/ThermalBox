extends Node

var gravity: Vector2 = Vector2(0, 5.0)
var gravity_is_on: bool = true
var is_paused: bool = false
var default_cell_size: int = 10
var default_simulation_area: Vector2i = Vector2i(40, 30)
var default_particle_mass: float = 1.0
var default_particle_radius: float = 2.5
var interaction_range_r: float = 4.0
var interaction_range: float = interaction_range_r * default_particle_radius
var particle_strong_interaction_params: Array = [1.0, 100.0, default_particle_radius]
var particle_weak_interaction_params: Array = [1.0, 50.0, default_particle_radius]
var particle_strong_repulsion_params: Array = [400.0, interaction_range_r]
var particle_weak_repulsion_params: Array = [200.0, interaction_range_r]

enum InteractionParams {A, D, R}
enum RepulsionParams {A, D}
enum InteractionType {STRONGINTER, WEAKINTER, STRONGREPUL, WEAKREPUL}
enum Items {NONE, PARTICLE1, PARTICLE2, PARTICLE3, WALL}

func get_interaction_type(type: int, other_type: int) -> InteractionType:
	if type > other_type:
		var temp: int = type
		type = other_type
		other_type = temp
	match type:
		1:
			match other_type:
				1:
					return InteractionType.STRONGINTER
				2:
					return InteractionType.STRONGINTER
				3:
					return InteractionType.STRONGREPUL
				_:
					assert(false)
		2:
			match other_type:
				2:
					return InteractionType.WEAKINTER
				3:
					return InteractionType.WEAKINTER
				_:
					assert(false)
		3:
			match other_type:
				3:
					return InteractionType.WEAKREPUL
				_:
					assert(false)
		_:
			assert(false)
	
	return InteractionType


# ++ = strong attraction
# + = weak attraction
# - = neutral / very weak
# -- = repulsive
# TODO: particle interactions: 
# 1-1: ++
# 2-2: +
# 3-3: -
# 1-2: ++
# 1-3: --
# 2-3: +
# TODO: force calculations with:
# Harmonic spring
# Morse potential * 
# Lennard-Jones
