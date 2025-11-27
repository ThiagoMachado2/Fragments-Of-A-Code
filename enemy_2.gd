extends CharacterBody2D

const ENEMY_BULLET_SCENE = preload("res://enemy_2_bullet.tscn")

enum State { PATROL, ATTACK, DEATH }
var current_state = State.PATROL

var health = 5
var patrol_speed = -40.0
var player_node = null

# --- VARIÁVEIS DO HIT FLASH ---
var damage_tween: Tween = null
const FLASH_COLOR = Color(1.0, 0.2, 0.2, 1.0)
# ------------------------------

@export_category("Patrol Behavior")
@export var patrol_distance: float = 200.0

var _patrol_limit_left: float
var _patrol_limit_right: float

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_effect: AnimatedSprite2D = $AttackEffect
@onready var attack_timer: Timer = $AttackTimer
@onready var aggro_area: Area2D = $AggroArea
@onready var fire_point: Marker2D = $FirePoint
@onready var fire_point_default_x = fire_point.position.x
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var explosion_sound: AudioStreamPlayer = $ExplosionSound 

# --- RAIOS ---
@onready var wall_ray: RayCast2D = $WallRay
@onready var ledge_ray: RayCast2D = $LedgeRay
@onready var wall_ray_default_x = wall_ray.target_position.x
@onready var ledge_ray_default_x = ledge_ray.position.x
# ----------------------------------

func _ready():
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	aggro_area.body_entered.connect(_on_aggro_area_body_entered)
	aggro_area.body_exited.connect(_on_aggro_area_body_exited)
	
	add_to_group("Enemies")
	set_state(State.PATROL)
	
	_patrol_limit_left = global_position.x - patrol_distance
	_patrol_limit_right = global_position.x + patrol_distance
	
	wall_ray.target_position.x = -abs(wall_ray_default_x)
	ledge_ray.position.x = -abs(ledge_ray_default_x)
	
	
func _physics_process(delta):
	# 🛑 CORREÇÃO ESSENCIAL: Ignora toda a lógica de movimento se estiver morto.
	if current_state == State.DEATH:
		return
		
	# Aplica gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Executa a lógica do estado atual
	match current_state:
		State.PATROL:
			patrol_state(delta)
		State.ATTACK:
			attack_state(delta)
			
	move_and_slide()
	
	# --- LÓGICA DE VIRAR MOVIDA PARA CÁ ---
	if current_state == State.PATROL:
		var physical_boundary = not ledge_ray.is_colliding() or wall_ray.is_colliding()
		
		var at_left_limit = (patrol_speed < 0 and global_position.x < _patrol_limit_left)
		var at_right_limit = (patrol_speed > 0 and global_position.x > _patrol_limit_right)
		
		if physical_boundary or at_left_limit or at_right_limit:
			turn_around()

# ----------------------------------------------------------------------
## 🗺️ Lógica dos Estados
# ----------------------------------------------------------------------

func patrol_state(delta):
	anim_sprite.play("walk")
	velocity.x = patrol_speed

func attack_state(delta):
	velocity.x = 0
	anim_sprite.play("attack")
	
	if is_instance_valid(player_node):
		if player_node.global_position.x < global_position.x:
			anim_sprite.flip_h = false
			fire_point.position.x = fire_point_default_x
		else:
			anim_sprite.flip_h = true
			fire_point.position.x = -fire_point_default_x

func set_state(new_state):
	if new_state == current_state:
		return
		
	current_state = new_state
	
	match current_state:
		State.PATROL:
			player_node = null
			attack_timer.stop()
		State.ATTACK:
			attack_timer.start()
		State.DEATH:
			velocity = Vector2.ZERO
			attack_timer.stop()

# ----------------------------------------------------------------------
## 🔫 Funções de Ação
# ----------------------------------------------------------------------

func turn_around():
	patrol_speed *= -1.0
	anim_sprite.flip_h = not anim_sprite.flip_h
	
	if anim_sprite.flip_h:
		wall_ray.target_position.x = -abs(wall_ray_default_x)
		ledge_ray.position.x = -abs(ledge_ray_default_x)
		fire_point.position.x = -fire_point_default_x
	else:
		wall_ray.target_position.x = abs(wall_ray_default_x)
		ledge_ray.position.x = abs(ledge_ray_default_x)
		fire_point.position.x = fire_point_default_x

func shoot():
	if current_state != State.ATTACK:
		return

	attack_effect.play("fire")
	
	var bullet = ENEMY_BULLET_SCENE.instantiate()
	bullet.global_position = fire_point.global_position
	
	if anim_sprite.flip_h:
		bullet.direcao = Vector2.RIGHT
	else:
		bullet.direcao = Vector2.LEFT
	
	get_parent().add_child(bullet)

# ----------------------------------------------------------------------
## 📢 SINAIS
# ----------------------------------------------------------------------

func _on_attack_timer_timeout():
	if current_state == State.ATTACK:
		shoot()
		attack_timer.start()

func _on_aggro_area_body_entered(body):
	if current_state == State.DEATH:
		return
		
	if body.name == "RobotoBase":
		player_node = body
		set_state(State.ATTACK)

func _on_aggro_area_body_exited(body):
	if current_state == State.DEATH:
		return
		
	if body.name == "RobotoBase":
		player_node = null
		
		if anim_sprite.flip_h:
			patrol_speed = abs(patrol_speed)
			wall_ray.target_position.x = -abs(wall_ray_default_x)
			ledge_ray.position.x = -abs(ledge_ray_default_x)
		else:
			patrol_speed = -abs(patrol_speed)
			wall_ray.target_position.x = abs(wall_ray_default_x)
			ledge_ray.position.x = abs(ledge_ray_default_x)
			
		set_state(State.PATROL)

# ----------------------------------------------------------------------
## ❤️ VIDA E MORTE
# ----------------------------------------------------------------------

func take_damage(amount):
	if health <= 0:
		return 

	health -= amount
	
	if damage_tween:
		damage_tween.kill()
		
	anim_sprite.modulate = Color.WHITE
	
	damage_tween = create_tween()
	
	damage_tween.tween_property(anim_sprite, "modulate", FLASH_COLOR, 0.05)
	damage_tween.tween_property(anim_sprite, "modulate", Color.WHITE, 0.2).set_delay(0.05)
	
	if health <= 0:
		_die()
		
func _die():
	set_state(State.DEATH) 
	
	if is_instance_valid(collision_shape):
		# Desativa a colisão para que ele não interaja com o mapa/jogador enquanto explode
		collision_shape.set_deferred("disabled", true)
	
	explosion_sound.play() 
	
	if anim_sprite.sprite_frames.has_animation("death"):
		anim_sprite.play("death")
		
		await anim_sprite.animation_finished
		
	else:
		print("Aviso: Animação 'death' não encontrada. Usando Timer para remover.")
		await get_tree().create_timer(0.5).timeout 
		
	queue_free()
