extends Node2D
var Scheduler
@onready var Renderer := get_node("UI/ParticleRenderer")
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
var simulation_view_resolution: Vector2
var simulation_view_scale: float



func _ready() -> void:
	Scheduler = preload("res://scripts/scheduler.gd").Scheduler.new()


func _process(_delta: float) -> void:
	pass
	


func _physics_process(delta: float) -> void:
	if is_paused:
		return
	Scheduler.step(delta, particle_count, particle_positions, particle_velocities, particle_accelerations,
	particle_radii, particle_masses)
	Renderer.render(particle_count, particle_positions, particle_radii)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Place particle"):
		place_particle()
	

func place_particle() -> void:
	var mouse_position := get_global_mouse_position()
	var default_velocity := Vector2.ZERO
	var default_radius := 10.0
	var default_mass := 1.0
	add_particle(mouse_position, default_velocity, default_radius, default_mass)
	

func add_particle(p_position: Vector2, p_velocity: Vector2, p_radius: float, p_mass: float) -> void:
		assert(
			particle_velocities.size() == particle_count
			and particle_radii.size() == particle_count
			and particle_masses.size() == particle_count
			and particle_accelerations.size() == particle_count,
			"ParticleDataDeSyncError: particle arrays have mismatched sizes"
		)
		particle_count += 1
		particle_positions.append(p_position)
		particle_velocities.append(p_velocity)
		particle_accelerations.append(Vector2.ZERO)
		particle_radii.append(p_radius)
		particle_masses.append(p_mass)
