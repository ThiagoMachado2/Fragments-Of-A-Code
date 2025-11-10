# Enemy1.gd (Versão Patrulha Voadora com Lógica Corrigida)
extends CharacterBody2D

# Carrega a cena do projétil
const ENEMY_BULLET_SCENE = preload("res://enemy_1_bullet.tscn")

enum State { IDLE, PATROL, ATTACK, RETURNING } 
var current_state = State.IDLE

var health = 3
# --- CORREÇÃO: Começa andando para a ESQUERDA (padrão do sprite) ---
var patrol_speed = -30.0 
var player_node = null

@export_category("Patrol Behavior")
@export var patrol_distance: float = 100.0

var _patrol_start_position: Vector2
var _patrol_limit_left: float
var _patrol_limit_right: float

# Referências para os nós filhos
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_effect: AnimatedSprite2D = $AttackEffect
@onready var flying_effect: AnimatedSprite2D = $FlyingEffect
@onready var attack_timer: Timer = $AttackTimer
@onready var fire_point: Marker2D = $FirePoint
@onready var fire_point_default_x = fire_point.position.x
@onready var aggro_area: Area2D = $AggroArea
@onready var wall_ray: RayCast2D = $WallRay

func _ready():
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	aggro_area.body_entered.connect(_on_aggro_area_body_entered)
	aggro_area.body_exited.connect(_on_aggro_area_body_exited)
	
	add_to_group("Enemies")
	
	_patrol_start_position = global_position
	_patrol_limit_left = global_position.x - patrol_distance
	_patrol_limit_right = global_position.x + patrol_distance
	
	# --- CORREÇÃO: Garante que o raio comece apontando para a esquerda ---
	wall_ray.target_position.x = -abs(wall_ray.target_position.x)
	
	set_state(State.PATROL) # Começa patrulhando

func _physics_process(delta):
	# Este inimigo voa, então NÃO aplicamos gravidade
	# velocity.y += get_gravity() * delta

	match current_state:
		State.PATROL:
			patrol_state(delta)
		State.ATTACK:
			attack_state(delta)
		State.IDLE:
			pass
		State.RETURNING:
			returning_state(delta)
			
	move_and_slide()

# --- LÓGICA DOS ESTADOS ---

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
	
	# --- CORREÇÃO: Lógica de virar invertida ---
	if is_instance_valid(player_node):
		if player_node.global_position.x < global_position.x:
			# Jogador está à ESQUERDA (padrão)
			anim_sprite.flip_h = false
			fire_point.position.x = fire_point_default_x
		else:
			# Jogador está à DIREITA (virado)
			anim_sprite.flip_h = true
			fire_point.position.x = -fire_point_default_x

func returning_state(delta):
	anim_sprite.play("idle")
	flying_effect.play("fly")
	flying_effect.visible = true
	
	var direction_to_home = (_patrol_start_position - global_position).normalized()
	
	if global_position.distance_to(_patrol_start_position) < 5:
		# --- CORREÇÃO: Reseta para o padrão ESQUERDA ---
		velocity.x = 0
		anim_sprite.flip_h = false # Padrão (Esquerda)
		patrol_speed = -abs(patrol_speed) # Padrão (Esquerda)
		wall_ray.target_position.x = -abs(wall_ray.target_position.x) # Padrão (Esquerda)
		fire_point.position.x = fire_point_default_x
		
		set_state(State.PATROL)
		return

	velocity.x = direction_to_home.x * abs(patrol_speed)
	
	# --- CORREÇÃO: Lógica de virar invertida ---
	if velocity.x > 0: # Indo para a DIREITA
		anim_sprite.flip_h = true
	else: # Indo para a ESQUERDA
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
			velocity.x = 0
			flying_effect.visible = false
			attack_timer.stop()
		State.RETURNING:
			player_node = null
			attack_timer.stop()
			flying_effect.play("fly")
			flying_effect.visible = true

# --- FUNÇÕES DE AÇÃO ---

func turn_around():
	patrol_speed *= -1.0
	anim_sprite.flip_h = not anim_sprite.flip_h
	wall_ray.target_position.x *= -1.0
	
	# --- CORREÇÃO: Lógica do ponto de tiro invertida ---
	if anim_sprite.flip_h: # Se agora está virado para a DIREITA
		fire_point.position.x = -fire_point_default_x
	else: # Se agora está virado para a ESQUERDA (padrão)
		fire_point.position.x = fire_point_default_x

func shoot():
	if current_state != State.ATTACK:
		return

	anim_sprite.play("attack")
	attack_effect.play("fire")
	
	var bullet = ENEMY_BULLET_SCENE.instantiate()
	bullet.global_position = fire_point.global_position
	
	# --- CORREÇÃO: Lógica do tiro invertida ---
	if anim_sprite.flip_h: # flip_h = true é DIREITA
		bullet.direcao = Vector2.RIGHT
	else: # flip_h = false é ESQUERDA (padrão)
		bullet.direcao = Vector2.LEFT
	
	get_parent().add_child(bullet)

# --- SINAIS ---

func _on_attack_timer_timeout():
	if current_state == State.ATTACK:
		shoot()
		attack_timer.start()

func _on_aggro_area_body_entered(body):
	if body.name == "RobotoBase":
		player_node = body
		set_state(State.ATTACK)

func _on_aggro_area_body_exited(body):
	if body.name == "RobotoBase":
		set_state(State.RETURNING)

# --- VIDA E DANO ---
func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()
