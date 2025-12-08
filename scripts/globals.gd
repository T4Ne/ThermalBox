extends Node

var gravity: Vector2 = Vector2(0, 5.0)
var gravity_is_on: bool = true
var is_paused: bool = false
var default_cell_size: int = 10
var default_simulation_area: Vector2i = Vector2i(40, 30)
var default_particle_mass: float = 1.0
var default_particle_radius: float = 2.5
var time_step: float = 0.016
var lightspeed: float = ((default_particle_radius / time_step) / 2.0) * 0.9
var max_accel: float = 2.0 * lightspeed / time_step
var min_chunk_time_usec: float = 2000.0
var neighbor_range: int = 1
var default_particle_mass_by_type: PackedFloat32Array = [1.5, 1.0, 1.0, 0.5]
var interaction_range_r: float = 4.0
var wall_thermal_coef: float = 0.8
var pump_acceleration: float = 100.0
var pump_max_speed: float = 5.0
