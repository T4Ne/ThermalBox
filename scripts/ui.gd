class_name UI
extends CanvasLayer

var edge_offset: Vector2 = Vector2(60.0, 60.0)

@onready var SimulationViewRect: ColorRect = get_node("Control/SimulationViewArea/SimulationViewRect")
@onready var SimulationViewPos: Control = get_node("Control/SimulationViewArea/SimulationViewRect/SimulationViewPos")
@onready var SelectedLabel: Label = get_node("Control/BottomBar/ItemButtons/Selected")
@onready var simulation_view: SimulationViewData
@onready var main_box: MainBox = get_node("MainBox")
@onready var Pause: Button = get_node("Control/SideBar/MainControls/Pause")
@onready var Gravity: Button = get_node("Control/SideBar/MainControls/Gravity")
@onready var FPSLabel: Label = get_node("Control/SideBar/MainControls/FPSLabel")
@onready var Countlabel: Label = get_node("Control/SideBar/MainControls/CountLabel")

var selected_item: Globals.Items = Globals.Items.NONE
var place_25: bool = false

func _ready() -> void:
	var simulation_true_size: Vector2i = Globals.default_cell_size * Globals.default_simulation_area
	simulation_view = SimulationViewData.new(simulation_true_size, edge_offset)
	main_box.set_simulation_view(simulation_view)
	main_box.ui_info.connect(display_info)

func _process(_delta: float) -> void:
	_update_simulation_view_info()

func _update_simulation_view_info() -> void:
	simulation_view.update_simulation_view_size(SimulationViewRect.get_global_rect().size)
	simulation_view.update_simulation_view_position(SimulationViewPos.get_global_position())

func set_sim_view(sim_view: SimulationViewData) -> void:
	simulation_view = sim_view

func toggle_pause() -> void:
	Globals.is_paused = not Globals.is_paused
	if Globals.is_paused:
		Pause.text = "Resume"
	else:
		Pause.text = "Pause"

func _handle_item_placement(mouse_position: Vector2) -> void:
	var type: int
	match selected_item:
		Globals.Items.NONE:
			return
		Globals.Items.WALL:
			main_box.place_wall(mouse_position)
		Globals.Items.PARTICLE1:
			type = 1
			main_box.place_particle(type, mouse_position, place_25)
		Globals.Items.PARTICLE2:
			type = 2
			main_box.place_particle(type, mouse_position, place_25)
		Globals.Items.PARTICLE3:
			type = 3
			main_box.place_particle(type, mouse_position, place_25)

func _on_particle_1_item_pressed() -> void:
	selected_item = Globals.Items.PARTICLE1
	SelectedLabel.text = "Selected: Particle 1"

func _on_wall_item_pressed() -> void:
	selected_item = Globals.Items.WALL
	SelectedLabel.text = "Selected: Wall"

func _on_simulation_view_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("primary action"):
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
	selected_item = Globals.Items.PARTICLE2
	SelectedLabel.text = "Selected: Particle 2"

func _on_particle_3_item_pressed() -> void:
	selected_item = Globals.Items.PARTICLE3
	SelectedLabel.text = "Selected: Particle 3"

func _on_a_edit_text_submitted(new_text: String) -> void:
	Globals.particle_strong_interaction_params[Globals.InteractionParams.A] = float(new_text)

func _on_d_edit_text_submitted(new_text: String) -> void:
	Globals.particle_strong_interaction_params[Globals.InteractionParams.D] = float(new_text)

func _on_r_edit_text_submitted(new_text: String) -> void:
	Globals.particle_strong_interaction_params[Globals.InteractionParams.R] = float(new_text)

func display_info(tps: int, count: int) -> void:
	FPSLabel.text = "FPS: %d" % tps
	Countlabel.text = "Count: %d" % count

func _on_place_many_toggled(toggled_on: bool) -> void:
	place_25 = toggled_on

func _on_particles_reset_pressed() -> void:
	main_box.delete_particles()
