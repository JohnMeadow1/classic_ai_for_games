extends CanvasLayer

@onready var behavior_option: OptionButton = %behavior
@onready var agent_count_input: SpinBox = %agent_count
@onready var selected_only_toggle: CheckButton = %selected_only
@onready var collision_avoidance_toggle: CheckButton = %collision_avoidance

var controller: BoidController

func _ready():
	randomize()
	Steering.alignment_rate  = %alignment.value
	Steering.cohesion_rate   = %cohesion.value
	Steering.separation_rate = %separation.value
	
	Steering.friction         = %friction.value
	Steering.view_range       = %view_range.value 
	Steering.view_range_squared = Steering.view_range * Steering.view_range
	Steering.view_range_fov    = deg_to_rad( %range_fov.value * 0.5 )
	
	Steering.separation_range = %separation_range.value
	Steering.separation_range_squared = Steering.separation_range * Steering.separation_range
	Steering.separation_range_fov    = deg_to_rad( %separation_fov.value * 0.5 )
	
	Steering.max_speed        = %max_speed.value

	behavior_option.add_item("Seek", Botek.Behavior.SEEK)
	behavior_option.add_item("Flee", Botek.Behavior.FLEE)
	behavior_option.add_item("Arrival", Botek.Behavior.ARRIVAL)
	behavior_option.add_item("Wander", Botek.Behavior.WANDER)
	behavior_option.add_item("Pursuit", Botek.Behavior.PURSUIT)
	behavior_option.add_item("Evade", Botek.Behavior.EVADE)
	behavior_option.select(behavior_option.get_item_index(Botek.Behavior.WANDER))

	behavior_option.item_selected.connect(_on_behavior_selected)
	agent_count_input.value_changed.connect(_on_agent_count_changed)
	selected_only_toggle.toggled.connect(_on_selected_only_toggled)
	collision_avoidance_toggle.toggled.connect(_on_collision_avoidance_toggled)
	call_deferred("_connect_controller")

func _connect_controller() -> void:
	controller = get_tree().get_first_node_in_group("agent_controller") as BoidController
	if controller == null:
		push_error("UI could not find a BoidController in the scene.")
		return

	#controller.agent_count_changed.connect(update_count)
	controller.selected_agent_changed.connect(update_selected_agent)
	controller.set_behavior(behavior_option.get_selected_id())
	controller.set_selected_only(selected_only_toggle.button_pressed)
	controller.set_collision_avoidance_enabled(collision_avoidance_toggle.button_pressed)
	agent_count_input.set_value_no_signal(controller.agents.size())
	
	#update_count(controller.agents.size())
	update_selected_agent(controller.selected_agent)

func _on_behavior_selected(index: int) -> void:
	if controller != null:
		controller.set_behavior(behavior_option.get_item_id(index))

func _on_agent_count_changed(value: float) -> void:
	if controller != null:
		controller.set_agent_count(roundi(value))

func _on_selected_only_toggled(enabled: bool) -> void:
	if controller != null:
		controller.set_selected_only(enabled)

func _on_collision_avoidance_toggled(enabled: bool) -> void:
	if controller != null:
		controller.set_collision_avoidance_enabled(enabled)

func update_selected_agent(agent: Botek) -> void:
	if is_instance_valid(agent):
		behavior_option.select(behavior_option.get_item_index(agent.behavior))
	%selected_agent.text = (
		"Selected: %s" % agent.name
		if is_instance_valid(agent)
		else "Selected: none"
	)

func _on_alignment_value_changed(value):
	Steering.alignment_rate = value

func _on_cohesion_value_changed(value):
	Steering.cohesion_rate = value

func _on_separation_value_changed(value):
	Steering.separation_rate = value

func _on_friction_value_changed(value):
	Steering.friction = value

func _on_view_range_value_changed(value):
	Steering.view_range = value
	Steering.view_range_squared = value * value
	
func _on_separation_range_value_changed(value):
	Steering.separation_range = value
	Steering.separation_range_squared = value * value

func _on_range_fov_value_changed(value):
	Steering.view_range_fov = deg_to_rad(value * 0.5)

func _on_separation_fov_value_changed(value):
	Steering.separation_range_fov = deg_to_rad(value * 0.5)

func _on_space_wrap_toggled(button_pressed):
	Steering.space_wrap = button_pressed


func _on_hide_parameters_toggled(toggled_on: bool) -> void:
	%Parameters.visible = toggled_on

#func update_count(in_value):
#	%count.text = "Agents: %d" % in_value


func _on_hide_behavior_toggled(toggled_on: bool) -> void:
	%AgentControls.visible = toggled_on


func _on_debug_draw_toggled(toggled_on: bool) -> void:
	Steering.is_debug_draw = toggled_on
