extends CharacterBody2D

const ENEMY_BULLET_SCENE = preload("res://enemy_1_bullet.tscn")

enum State {IDLE, PATROL, ATTACK, RETURNING, DEATH}
var current_state = State.IDLE

var health = 3
var patrol_speed = -30.0
var player_node = null

# --- VARIÁVEIS DO HIT FLASH ---
var damage_tween: Tween = null
const FLASH_COLOR = Color(1.0, 0.2, 0.2, 1.0)
# ------------------------------

@export_category("Patrol Behavior")
@export var patrol_distance: float = 100.0

var _patrol_start_position: Vector2
var _patrol_limit_left: float
var _patrol_limit_right: float

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_effect: AnimatedSprite2D = $AttackEffect
@onready var flying_effect: AnimatedSprite2D = $FlyingEffect
@onready var attack_timer: Timer = $AttackTimer
@onready var fire_point: Marker2D = $FirePoint
@onready var fire_point_default_x = fire_point.position.x
@onready var aggro_area: Area2D = $AggroArea
@onready var wall_ray: RayCast2D = $WallRay
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
# 🔊 NOVA REFERÊNCIA: Certifique-se que o nome do nó está correto
@onready var explosion_sound: AudioStreamPlayer = $ExplosionSound 

func _ready():
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	aggro_area.body_entered.connect(_on_aggro_area_body_entered)
	aggro_area.body_exited.connect(_on_aggro_area_body_exited)
	
	add_to_group("Enemies")
	
	_patrol_start_position = global_position
	_patrol_limit_left = global_position.x - patrol_distance
	_patrol_limit_right = global_position.x + patrol_distance
	
	wall_ray.target_position.x = -abs(wall_ray.target_position.x)
	
	set_state(State.PATROL)

func _physics_process(delta):
	match current_state:
		State.PATROL:
			patrol_state(delta)
		State.ATTACK:
			attack_state(delta)
		State.RETURNING:
			returning_state(delta)
		# IDLE e DEATH impedem a lógica de movimento
		State.IDLE, State.DEATH: 
			pass
			
	move_and_slide()

# ----------------------------------------------------------------------
## 🗺️ Lógica dos Estados (Sem Alteração)
# ----------------------------------------------------------------------

func patrol_state(delta):
	anim_sprite.play("idle")
	flying_effect.play("fly")
	flying_effect.visible = true
	
	velocity.x = patrol_speed
	
	var at_wall = wall_ray.is_colliding()
	var at_left_limit = (patrol_speed < 0 and global_position.x < _patrol_limit_left)
	var at_right_limit = (patrol_speed > 0 and global_position.x > _patrol_limit_right)
	
	if at_wall or at_left_limit or at_right_limit:
		turn_around()

func attack_state(delta):
	velocity.x = 0
	flying_effect.play("fly")
	flying_effect.visible = true
	anim_sprite.play("aiming")
	
	if is_instance_valid(player_node):
		if player_node.global_position.x < global_position.x:
			anim_sprite.flip_h = false
			fire_point.position.x = fire_point_default_x
		else:
			anim_sprite.flip_h = true
			fire_point.position.x = -fire_point_default_x

func returning_state(delta):
	anim_sprite.play("idle")
	flying_effect.play("fly")
	flying_effect.visible = true
	
	var direction_to_home = (_patrol_start_position - global_position).normalized()
	
	if global_position.distance_to(_patrol_start_position) < 5:
		velocity.x = 0
		anim_sprite.flip_h = false
		patrol_speed = -abs(patrol_speed)
		wall_ray.target_position.x = -abs(wall_ray.target_position.x)
		fire_point.position.x = fire_point_default_x
		
		set_state(State.PATROL)
		return

	velocity.x = direction_to_home.x * abs(patrol_speed)
	
	if velocity.x > 0:
		anim_sprite.flip_h = true
	else:
		anim_sprite.flip_h = false
			
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
		State.IDLE:
			velocity = Vector2.ZERO
			flying_effect.visible = false
			attack_timer.stop()
		State.RETURNING:
			player_node = null
			attack_timer.stop()
			flying_effect.play("fly")
			flying_effect.visible = true
		State.DEATH:
			velocity = Vector2.ZERO
			flying_effect.visible = false
			attack_timer.stop()

# ----------------------------------------------------------------------
## 🔫 Funções de Ação (Sem Alteração)
# ----------------------------------------------------------------------

func turn_around():
	patrol_speed *= -1.0
	anim_sprite.flip_h = not anim_sprite.flip_h
	wall_ray.target_position.x *= -1.0
	
	if anim_sprite.flip_h:
		fire_point.position.x = -fire_point_default_x
	else:
		fire_point.position.x = fire_point_default_x

func shoot():
	if current_state != State.ATTACK:
		return

	anim_sprite.play("attack")
	
	var bullet = ENEMY_BULLET_SCENE.instantiate()
	bullet.global_position = fire_point.global_position
	
	if anim_sprite.flip_h:
		bullet.direcao = Vector2.RIGHT
	else:
		bullet.direcao = Vector2.LEFT
	
	get_parent().add_child(bullet)

# --- SINAIS (Sem Alteração) ---

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
		set_state(State.RETURNING)

# ----------------------------------------------------------------------
## ❤️ Vida e Morte (Com Som)
# ----------------------------------------------------------------------

func take_damage(amount):
	if health <= 0:
		return 

	health -= amount
	
	# --- Lógica do Hit Flash ---
	if damage_tween:
		damage_tween.kill()
		
	anim_sprite.modulate = Color.WHITE
	
	damage_tween = create_tween()
	
	damage_tween.tween_property(anim_sprite, "modulate", FLASH_COLOR, 0.05)
	damage_tween.tween_property(anim_sprite, "modulate", Color.WHITE, 0.2).set_delay(0.05)
	# ---------------------------
	
	if health <= 0:
		_die()
		
func _die():
	# 1. Muda o estado para DEATH, parando o movimento
	set_state(State.DEATH) 
	
	# 2. Desativa a colisão
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", true)
	
	# 🔊 TOCA O SOM DA EXPLOSÃO
	explosion_sound.play() 
	
	# 3. Toca a animação de morte
	if anim_sprite.sprite_frames.has_animation("death"):
		anim_sprite.play("death")
		
		# 4. Espera a animação de morte terminar
		await anim_sprite.animation_finished
		
	else:
		# Fallback se a animação 'death' não existir
		print("Aviso: Animação 'death' não encontrada. Usando Timer para remover.")
		await get_tree().create_timer(0.5).timeout 
		
	# 5. Remove o inimigo
	queue_free()
