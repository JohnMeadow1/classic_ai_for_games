extends Node2D


func _draw():
	draw_circle(Vector2.ZERO, 100.0, Color(1.0, 0.0, 0.0, 0.443))

func _ready() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)
