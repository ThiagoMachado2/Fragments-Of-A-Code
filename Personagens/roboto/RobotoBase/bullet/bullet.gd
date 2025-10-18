extends Node2D

@onready var area: Area2D = $Area2D
@onready var sprite: Sprite2D = $Area2D/Sprite2D

@export var speed: float = 500
var velocity: Vector2 = Vector2.ZERO
var has_hit: bool = false

func _ready() -> void:
	if area:
		area.area_entered.connect(_on_area_entered)
	else:
		push_warning("Bullet: Area2D não encontrada — colisões não funcionarão.")

func _physics_process(delta: float) -> void:
	if not has_hit:
		position += velocity * delta

	# Destroi se sair da tela
	if not get_viewport_rect().has_point(global_position):
		queue_free()

func _on_area_entered(area_entered: Area2D) -> void:
	if has_hit:
		return
	has_hit = true
	queue_free()
