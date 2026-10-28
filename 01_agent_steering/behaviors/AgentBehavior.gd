extends RefCounted
class_name AgentBehavior

var is_timer_ready := true

func enter(_agent) -> void:
	pass

func exit(_agent) -> void:
	pass

func timer_timeout() -> void:
	is_timer_ready = true


func calculate_steering(_agent:Botek, _delta: float) -> Vector2:
	return Vector2.ZERO

func seek(agent:Botek, target: Vector2) -> Vector2:
	var target_velocity :Vector2= agent.position.direction_to(target) * Steering.max_speed
	return agent.steer_toward(target_velocity)

func flee(agent:Botek, target: Vector2) -> Vector2:
	var target_velocity := target.direction_to(agent.position) * Steering.max_speed
	return agent.steer_toward(target_velocity)

func arrival(agent:Botek, target: Vector2) -> Vector2:
	var direction := agent.position.direction_to(target)
	var distance := agent.position.distance_to(target)
	var arrival_range := maxf(Steering.view_range, 0.001)
	var arrival_progress := minf(distance / arrival_range, 1.0)
	var target_velocity := direction * Steering.max_speed * arrival_progress
	return agent.steer_toward(target_velocity)

func predict_position(agent:Botek, target_position: Vector2, target_velocity: Vector2) -> Vector2:
	var prediction_time := agent.position.distance_to(target_position) / maxf(Steering.max_speed, 0.001)
	agent.precited_position = target_velocity * prediction_time
	return target_position + agent.precited_position
