extends Area2D

var direction: Vector2
var speed := 150
var lifetime := 3.0

func setup(start_pos: Vector2, new_direction: Vector2):
	position = start_pos
	direction = new_direction


func _process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Blobs"):
		body.hit(Enum.Tool.SWORD, direction * -1)
	queue_free()
