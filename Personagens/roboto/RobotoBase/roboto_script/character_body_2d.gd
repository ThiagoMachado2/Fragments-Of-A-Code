extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 150.0
const JUMP_VELOCITY = -400.0
const SHOOT_DURATION := 1
const BULLET_SCENE = preload("res://Personagens/roboto/RobotoBase/bullet/bullet.tscn")
const MUZZLE_SCENE = preload("res://Personagens/roboto/RobotoBase/bullet/muzzle.tscn")

@export var bullet_offset: Vector2 = Vector2(10, 5)
@export var fire_rate: float = 0.3  
#@onready var muzzle: Sprite2D = $Muzzle

var was_on_floor: bool = true
var shoot_timer: float = 0.0
var fire_cooldown: float = 0.0

func _ready() -> void:
	if anim.animation == "":
		anim.play("idle")
#	if muzzle:
#		muzzle.visible = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction_input := Input.get_axis("left", "right")
	if direction_input > 0:
		anim.flip_h = false
	elif direction_input < 0:
		anim.flip_h = true

	if direction_input != 0:
		velocity.x = direction_input * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# controlar cadência de tiro
	fire_cooldown = max(fire_cooldown - delta, 0)

	if Input.is_action_just_pressed("shoot") and fire_cooldown <= 0:
		_start_shoot_animation(direction_input)
		fire_cooldown = fire_rate

	if shoot_timer > 0:
		shoot_timer -= delta
		var anim_to_play = _get_shoot_animation(direction_input)
		_play_if_not(anim_to_play)
	else:
		var anim_to_play = _get_movement_animation(direction_input)
		_play_if_not(anim_to_play)

	was_on_floor = is_on_floor()
	move_and_slide()

func _play_if_not(name: String) -> void:
	if anim.animation != name:
		anim.play(name)

func _start_shoot_animation(direction_input: float) -> void:
	shoot_timer = SHOOT_DURATION
	_spawn_bullet()
	_show_muzzle_flash()

func _get_shoot_animation(direction_input: float) -> String:
	if is_on_floor():
		if abs(direction_input) < 1:
			return "shoot_idle"
		else:
			return "shoot_run"
	else:
		if velocity.y < 0:
			return "shoot_jump"
		else:
			return "shoot_fall"

func _get_movement_animation(direction_input: float) -> String:
	if is_on_floor():
		if direction_input != 0:
			return "run"
		else:
			return "idle"
	else:
		if velocity.y < 0:
			return "jump"
		else:
			return "fall"

func _spawn_bullet() -> void:
	var bullet = BULLET_SCENE.instantiate()
	var direction = -1 if anim.flip_h else 1
	var offset = Vector2(bullet_offset.x * direction, bullet_offset.y)
	bullet.global_position = global_position + offset
	bullet.velocity = Vector2(direction * bullet.speed, 0)
	get_tree().current_scene.add_child(bullet)

func _show_muzzle_flash() -> void:
	# Cria uma nova instância do muzzle flash
	var muzzle_flash = MUZZLE_SCENE.instantiate()

	# Define a direção e posição
	var direction = -1 if anim.flip_h else 1
	var offset = Vector2(bullet_offset.x * direction, bullet_offset.y)
	muzzle_flash.global_position = global_position + offset

	# Vira o flash para o lado certo (precisamos ajustar o muzzle.gd)
	# Vamos assumir que o sprite dentro de muzzle.tscn se chama "Flash"
	var flash_sprite = muzzle_flash.get_node_or_null("Flash")
	if flash_sprite:
		flash_sprite.flip_h = anim.flip_h

	# 4. Adiciona o flash à cena
	get_tree().current_scene.add_child(muzzle_flash)
