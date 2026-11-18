extends Node2D
class_name AgentDebugDraw

@onready var agent: Botek = get_parent() as Botek
var last_debug_enabled := false

func _physics_process(_delta: float) -> void:
	if Steering.is_debug_draw or last_debug_enabled != Steering.is_debug_draw:
		queue_redraw()
	last_debug_enabled = Steering.is_debug_draw

func _draw() -> void:
	if agent.is_selected:
		draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 32, Color.YELLOW, 2.0)
	if not Steering.is_debug_draw:
		return

	draw_circle(Vector2.ZERO, Steering.view_range, Color(1.0, 1.0, 1.0, 0.1))
	if agent.behavior == Botek.Behavior.WANDER:
		draw_circle(agent.circle_center, Steering.wander_radius, Color(0.0, 1.0, 1.0, 0.1))
		draw_line(
			agent.circle_center,
			agent.circle_center + agent.circle_displacement,
			Color(1.0, 1.0, 1.0, 0.2),
			2.0
		)
	if agent.behavior in [Botek.Behavior.SEEK, Botek.Behavior.ARRIVAL]:
		draw_vector(to_local(agent.destination), Color.SKY_BLUE, 1.0)
	if agent.behavior == Botek.Behavior.PATH_FOLLOW:
		for i in range(agent.path.size() - 1):
			draw_line(to_local(agent.path[i]), to_local(agent.path[i + 1]), Color.WHITE)

	draw_vector(agent.steering, Color(0.0, 1.0, 0.0, 0.3), 3.0)
	draw_vector(agent.desired_velocity, Color(0.0, 0.0, 1.0, 0.3), 3.0)
	draw_vector(agent.precited_position, Color(0.982, 0.0, 0.115, 0.3), 3.0)

func draw_vector(vector: Vector2, color: Color, arrow_size: float) -> void:
	if vector.length_squared() <= 1.0:
		return
	var direction := vector.normalized()
	var points := PackedVector2Array([
		vector + direction * arrow_size * 2.0,
		vector + direction.rotated(PI / 2.0) * arrow_size,
		vector + direction.rotated(-PI / 2.0) * arrow_size
	])
	draw_polygon(points, PackedColorArray([color]))
	draw_line(Vector2.ZERO, vector, color, arrow_size)
