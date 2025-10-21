extends Node2D
var Scheduler
@onready var UI := get_node("UI")
var is_paused := false
var particle_count := 0
var particle_positions: PackedVector2Array = []
var particle_velocities: PackedVector2Array = []
var particle_accelerations: PackedVector2Array = []
var particle_radii: PackedFloat32Array = []
var particle_masses: PackedFloat32Array = []
var grid_size: int = 100
var simulation_area := Vector2(80, 60)



func _ready() -> void:
	Scheduler = preload("res://scripts/scheduler.gd").Scheduler.new()
	UI.set_sim_view_size(simulation_area * grid_size)


func _process(_delta: float) -> void:
	UI.draw_particles(grid_size, particle_count, particle_positions, particle_radii)


func _physics_process(delta: float) -> void:
	if is_paused:
		return
	Scheduler.step(delta, particle_count, particle_positions, particle_velocities, particle_accelerations,
	particle_radii, particle_masses)


func place_particle(mouse_position) -> void:
	var simulation_view_position = UI.get_simulation_view_position()
	var simulation_view_scale = UI.get_simulation_view_scale()
	var particle_simulation_position = (mouse_position - simulation_view_position) / simulation_view_scale
	var particle_velocity = Vector2.ZERO
	var particle_radius = randf_range(20.0,50.0)
	var particle_mass = 1.0
	add_particle_to_sim(particle_simulation_position, particle_velocity, particle_radius, particle_mass)


func add_particle_to_sim(particle_position: Vector2, particle_velocity: Vector2, particle_radius: float, particle_mass: float) -> void:
		assert(
			particle_velocities.size() == particle_count
			and particle_radii.size() == particle_count
			and particle_masses.size() == particle_count
			and particle_accelerations.size() == particle_count,
			"ParticleDataDeSyncError: particle arrays have mismatched sizes"
		)
		particle_count += 1
		particle_positions.append(particle_position)
		particle_velocities.append(particle_velocity)
		particle_accelerations.append(Vector2.ZERO)
		particle_radii.append(particle_radius)
		particle_masses.append(particle_mass)


func _on_simulation_view_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("Place particle"):
		place_particle(get_global_mouse_position())
