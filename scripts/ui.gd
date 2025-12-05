class_name UI
extends CanvasLayer

var edge_offset: Vector2 = Vector2(60.0, 60.0)

@onready var SimulationViewRect: ColorRect = get_node("Control/SimulationViewArea/SimulationViewRect")
@onready var SimulationViewPos: Control = get_node("Control/SimulationViewArea/SimulationViewRect/SimulationViewPos")
@onready var SelectedLabel: Label = get_node("Control/BottomBar/ItemButtons/Selected")
@onready var simulation_render_state: SimulationRenderState
@onready var main_box: MainBox = get_node("MainBox")
@onready var Pause: Button = get_node("Control/SideBar/MainControls/Pause")
@onready var Gravity: Button = get_node("Control/SideBar/MainControls/Gravity")
@onready var FPSLabel: Label = get_node("Control/SideBar/MainControls/FPSLabel")
@onready var Countlabel: Label = get_node("Control/SideBar/MainControls/CountLabel")

enum Items {REMOVEWALL, PARTICLE1, PARTICLE2, PARTICLE3, PARTICLE4, 
WALLNEUTRAL, WALLCOLD, WALLHOT, PUMP, DIODE, SPAWNER, DRAIN}

var selected_item: Items = Items.REMOVEWALL
var place_25: bool = false

func _ready() -> void:
	var simulation_true_size: Vector2i = Globals.default_cell_size * Globals.default_simulation_area
	simulation_render_state = SimulationRenderState.new(simulation_true_size, edge_offset)
	main_box.set_simulation_view(simulation_render_state)

func _process(delta: float) -> void:
	_update_simulation_view_info()
	display_info(main_box.real_tps, main_box.world_state.particle_count)
	main_box.frame(delta)

func _update_simulation_view_info() -> void:
	simulation_render_state.update_simulation_view_size(SimulationViewRect.get_global_rect().size)
	simulation_render_state.update_simulation_view_position(SimulationViewPos.get_global_position())

func set_sim_view(render_state_instance: SimulationRenderState) -> void:
	simulation_render_state = render_state_instance

func toggle_pause() -> void:
	Globals.is_paused = not Globals.is_paused
	if Globals.is_paused:
		Pause.text = "Resume"
	else:
		Pause.text = "Pause"

func _handle_item_placement(mouse_position: Vector2) -> void:
	var type: int
	match selected_item:
		Items.REMOVEWALL:
			type = 0
			main_box.place_wall(type)
		Items.WALLNEUTRAL:
			type = 1
			main_box.place_wall(type)
		Items.WALLCOLD:
			type = 2
			main_box.place_wall(type)
		Items.WALLHOT:
			type = 3
			main_box.place_wall(type)
		Items.PUMP:
			type = 4
			main_box.place_pump(type)
		Items.DIODE:
			type = 8
			main_box.place_pump(type)
		Items.SPAWNER:
			type = 12
			main_box.place_wall(type)
		Items.DRAIN:
			type = 17
			main_box.place_wall(type)
		Items.PARTICLE1:
			type = 0
			main_box.place_particle(type, mouse_position, place_25)
		Items.PARTICLE2:
			type = 1
			main_box.place_particle(type, mouse_position, place_25)
		Items.PARTICLE3:
			type = 2
			main_box.place_particle(type, mouse_position, place_25)
		Items.PARTICLE4:
			type = 3
			main_box.place_particle(type, mouse_position, place_25)

func _on_particle_1_item_pressed() -> void:
	selected_item = Items.PARTICLE1
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PARTICLE
	SelectedLabel.text = "Selected: Particle 1"

func _on_simulation_view_gui_input(_event: InputEvent) -> void:
	if Input.is_action_pressed("primary action"):
		_handle_item_placement(main_box.get_global_mouse_position())

func _on_pause_pressed() -> void:
	toggle_pause()

func _on_reset_pressed() -> void:
	main_box.reinitialize_sim()

func _on_gravity_pressed() -> void:
	Globals.gravity_is_on = not Globals.gravity_is_on
	if Globals.gravity_is_on:
		Gravity.text = "Gravity Off"
	else:
		Gravity.text = "Gravity On"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("simulation toggle"):
		toggle_pause()
	if event.is_action_pressed("reduce energy"):
		main_box.reduce_energy()

func _on_particle_2_item_pressed() -> void:
	selected_item = Items.PARTICLE2
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PARTICLE
	SelectedLabel.text = "Selected: Particle 2"

func _on_particle_3_item_pressed() -> void:
	selected_item = Items.PARTICLE3
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PARTICLE
	SelectedLabel.text = "Selected: Particle 3"

func display_info(real_tps: float, count: int) -> void:
	var tps: int = roundi(real_tps)
	FPSLabel.text = "FPS: %d" % tps
	Countlabel.text = "Count: %d" % count

func _on_place_many_toggled(toggled_on: bool) -> void:
	place_25 = toggled_on

func _on_particles_reset_pressed() -> void:
	main_box.delete_particles()

func _on_wall_neutral_pressed() -> void:
	selected_item = Items.WALLNEUTRAL
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.WALL
	SelectedLabel.text = "Selected: Neutral Wall"

func _on_wall_cold_pressed() -> void:
	selected_item = Items.WALLCOLD
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.WALL
	SelectedLabel.text = "Selected: Cold Wall"

func _on_wall_hot_pressed() -> void:
	selected_item = Items.WALLHOT
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.WALL
	SelectedLabel.text = "Selected: Hot Wall"

func _on_wall_none_pressed() -> void:
	selected_item = Items.REMOVEWALL
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.WALL
	SelectedLabel.text = "Selected: Remove Wall"

func _on_pump_pressed() -> void:
	selected_item = Items.PUMP
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PUMP
	SelectedLabel.text = "Selected: Pump"

func _on_particle_4_item_pressed() -> void:
	selected_item = Items.PARTICLE4
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PARTICLE
	SelectedLabel.text = "Selected: Particle 4"

func _on_diode_pressed() -> void:
	selected_item = Items.DIODE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PUMP
	SelectedLabel.text = "Selected: Diode"

func _on_spawner_pressed() -> void:
	selected_item = Items.SPAWNER
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.WALL
	SelectedLabel.text = "Selected: Spawner"

func _on_drain_pressed() -> void:
	selected_item = Items.DRAIN
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.WALL
	SelectedLabel.text = "Selected: Drain"
