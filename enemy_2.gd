# Enemy2.gd
extends CharacterBody2D

# Carrega a cena do projétil
const ENEMY_BULLET_SCENE = preload("res://enemy_2_bullet.tscn")

# Enum para os estados
enum State { PATROL, ATTACK }
var current_state = State.PATROL

var health = 5
var patrol_speed = -40.0
var player_node = null

# VARIÁVEIS DE TERRITÓRIO
@export_category("Patrol Behavior")
@export var patrol_distance: float = 200.0 # Distância (em pixels) que ele pode andar

var _patrol_limit_left: float
var _patrol_limit_right: float

# Referências para os nós filhos
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_effect: AnimatedSprite2D = $AttackEffect
@onready var attack_timer: Timer = $AttackTimer
@onready var aggro_area: Area2D = $AggroArea
@onready var fire_point: Marker2D = $FirePoint
@onready var fire_point_default_x = fire_point.position.x

# --- RAIOS ---
@onready var wall_ray: RayCast2D = $WallRay
@onready var ledge_ray: RayCast2D = $LedgeRay
@onready var wall_ray_default_x = wall_ray.target_position.x
@onready var ledge_ray_default_x = ledge_ray.position.x
# ----------------------------------

func _ready():
	# Conecta os sinais que ainda usamos
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	aggro_area.body_entered.connect(_on_aggro_area_body_entered)
	aggro_area.body_exited.connect(_on_aggro_area_body_exited)
	
	add_to_group("Enemies")
	set_state(State.PATROL)
	# Salva a posição X inicial e calcula os limites do território
	_patrol_limit_left = global_position.x - patrol_distance
	_patrol_limit_right = global_position.x + patrol_distance
	
	
func _physics_process(delta):
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
	# (Verifica DEPOIS de mover)
	if current_state == State.PATROL:
		# Causa 1: Bateu na beirada OU bateu na parede
		var physical_boundary = not ledge_ray.is_colliding() or wall_ray.is_colliding()
		
		# Causa 2: Atingiu o limite do território
		var at_left_limit = (patrol_speed < 0 and global_position.x < _patrol_limit_left)
		var at_right_limit = (patrol_speed > 0 and global_position.x > _patrol_limit_right)
		
		# Se atingir QUALQUER limite (físico ou de território), vire.
		if physical_boundary or at_left_limit or at_right_limit:
			turn_around()

# --- LÓGICA DOS ESTADOS ---

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

# --- FUNÇÕES DE AÇÃO ---

func turn_around():
	patrol_speed *= -1.0
	anim_sprite.flip_h = not anim_sprite.flip_h
	
	# Atualiza os raios e o ponto de tiro com base na nova direção
	# (Esta é a lógica correta que já estava na sua _on_aggro_area_body_exited)
	if anim_sprite.flip_h: # Se agora está virado para a DIREITA
		wall_ray.target_position.x = -wall_ray_default_x
		ledge_ray.position.x = -ledge_ray_default_x
		fire_point.position.x = -fire_point_default_x
	else: # Se agora está virado para a ESQUERDA
		wall_ray.target_position.x = wall_ray_default_x
		ledge_ray.position.x = ledge_ray_default_x
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
		player_node = null # Limpa a referência do jogador
		
		# Sincroniza a velocidade e os raios com a direção atual do sprite
		
		if anim_sprite.flip_h:
			# Se flip_h é TRUE, o inimigo estava olhando para a DIREITA
			patrol_speed = 40.0 # Atualiza a velocidade para a DIREITA
			# para apontar para a DIREITA
			wall_ray.target_position.x = -wall_ray_default_x 
			ledge_ray.position.x = -ledge_ray_default_x
		else:
			# Se flip_h é FALSE, o inimigo estava olhando para a ESQUERDA
			patrol_speed = -40.0 # Atualiza a velocidade para a ESQUERDA
			# pontar para a ESQUERDA
			wall_ray.target_position.x = wall_ray_default_x
			ledge_ray.position.x = ledge_ray_default_x
			
		# Volta a Patrulhar
		set_state(State.PATROL)

# --- VIDA E DANO ---
func take_damage(amount):
	# ... (função take_damage permanece a mesma) ...
	health -= amount
	if health <= 0:
		queue_free()
