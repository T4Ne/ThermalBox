class_name UI
extends CanvasLayer

@onready var SimulationViewRect: ColorRect = get_node("Control/SimulationViewArea/SimulationViewRect")
@onready var SimulationViewPos: Control = get_node("Control/SimulationViewArea/SimulationViewRect/SimulationViewPos")
@onready var simulation_view: SimulationViewData
@onready var SelectedLabel: Label = get_node("Control/BottomBar/ItemButtons/Selected")

enum Items {NONE, PARTICLE1, WALL}
var selected_item: Items = Items.NONE
var item_buttons: Array = []

func _process(_delta: float) -> void:
	_update_simulation_view_info()

func _update_simulation_view_info() -> void:
	simulation_view.update_simulation_view_size(SimulationViewRect.get_global_rect().size)
	simulation_view.update_simulation_view_position(SimulationViewPos.get_global_position())

func set_sim_view(sim_view: SimulationViewData) -> void:
	simulation_view = sim_view

func _on_particle_1_item_pressed() -> void:
	selected_item = Items.PARTICLE1
	SelectedLabel.text = "Selected: Particle 1"

func _on_wall_item_pressed() -> void:
	selected_item = Items.WALL
	SelectedLabel.text = "Selected: Wall"
