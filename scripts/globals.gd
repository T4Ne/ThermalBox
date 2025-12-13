extends Node

var config: Dictionary = {
	"gravity" : Vector2(0, 5.0),
	"gravity_is_on" : true,
	"is_paused" : false,
	"default_cell_size" : 10.0,
	"default_simulation_area" : Vector2i(40, 30),
	"default_particle_radius" : 2.5,
	"time_step" : 0.008,
	"max_chunk_time_usec" : 2500.0,
	"neighbor_range" : 1,
	"default_particle_mass_by_type" : [1.5, 1.0, 1.0, 0.5],
	"interaction_range_r" : 4.0,
	"wall_thermal_coef" : 0.8,
	"pump_acceleration" : 100.0,
	"pump_max_speed" : 5.0,
	"strong_lennard" : [-100.0, 3.5],
	"weak_lennard" : [-20.0, 4.0]
}

func _ready() -> void:
	update_dependencies()

func update_dependencies() -> void:
	config["max_speed"] = ((config["default_particle_radius"] / config["time_step"]) / 4.0)
	config["max_accel"] = 2.0 * config["max_speed"] / config["time_step"]
	config["strong_repul"] = [-1000.0, config["interaction_range_r"]]
	config["weak_repul"] = [-500.0, config["interaction_range_r"]]
