extends Area2D
class_name Attack

@export var damage: int = 1

func _ready():
	monitoring = true

func _on_life_span_timeout() -> void:
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("_apply_damage"):
		body._apply_damage(damage)
