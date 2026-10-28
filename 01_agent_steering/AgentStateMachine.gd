extends Node
class_name AgentStateMachine

signal behavior_changed(previous_behavior: int, current_behavior: int)

var agent: Node2D
var behavior_scripts: Dictionary = {}
var behavior_instances: Dictionary = {}
var current_behavior_id := -1
var current_behavior: AgentBehavior
var is_configured := false

func configure(in_agent: Node2D, in_behavior_scripts: Dictionary) -> void:
	agent = in_agent
	behavior_scripts = in_behavior_scripts
	is_configured = true

func change_behavior(behavior_id: int) -> bool:
	if not is_configured or not behavior_scripts.has(behavior_id):
		push_warning("Ignoring unsupported steering behavior: %d" % behavior_id)
		return false
	if behavior_id == current_behavior_id:
		return true

	var next_behavior := _get_behavior(behavior_id)
	if next_behavior == null:
		push_error("Could not instantiate steering behavior: %d" % behavior_id)
		return false

	var previous_behavior_id := current_behavior_id
	if current_behavior != null:
		current_behavior.exit(agent)
	current_behavior_id = behavior_id
	current_behavior = next_behavior
	current_behavior.enter(agent)
	behavior_changed.emit(previous_behavior_id, current_behavior_id)
	return true

func calculate_steering(delta: float) -> Vector2:
	if current_behavior == null:
		return Vector2.ZERO
	return current_behavior.calculate_steering(agent, delta)

func calculate_behavior(behavior_id: int, delta: float) -> Vector2:
	if not behavior_scripts.has(behavior_id):
		push_warning("Ignoring unsupported steering behavior: %d" % behavior_id)
		return Vector2.ZERO
	var behavior := _get_behavior(behavior_id)
	if behavior == null:
		push_error("Could not instantiate steering behavior: %d" % behavior_id)
		return Vector2.ZERO
	return behavior.calculate_steering(agent, delta)

func _get_behavior(behavior_id: int) -> AgentBehavior:
	if behavior_instances.has(behavior_id):
		return behavior_instances[behavior_id]

	var behavior_script: Script = behavior_scripts[behavior_id]
	var instance := behavior_script.new() as AgentBehavior
	if instance == null:
		return null
	behavior_instances[behavior_id] = instance
	return instance
