extends Node2D

@onready var flash: Sprite2D = $Flash
@export var duration: float = 0.08

func _ready() -> void:
	await get_tree().create_timer(duration).timeout
	queue_free()
