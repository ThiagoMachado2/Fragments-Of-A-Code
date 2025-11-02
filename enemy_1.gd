# Enemy1.gd
extends CharacterBody2D

# Carrega a cena do projétil
const ENEMY_BULLET_SCENE = preload("res://enemy_1_bullet.tscn")

# Enum para os estados da IA
enum State { IDLE, ATTACK }
var current_state = State.IDLE

var health = 3

# Referências para os nós filhos
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_ray_left: RayCast2D = $RayCastRight
@onready var detection_ray_right: RayCast2D =$RayCastLeft
@onready var fire_point: Marker2D = $FirePoint
@onready var attack_timer: Timer = $AttackTimer

# --- NOVA VARIÁVEL ---
# Armazena a posição X padrão do FirePoint
var fire_point_default_x: float

func _ready():
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	set_state(State.IDLE)
	add_to_group("Enemies")
	
	# --- NOVO EM _READY ---
	# Salva a posição X inicial do FirePoint
	fire_point_default_x = fire_point.position.x

func _physics_process(delta):
	# Aplica gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

	# --- Lógica da IA ---
	var player_on_left = check_player(detection_ray_left)
	var player_on_right = check_player(detection_ray_right)
	
	if player_on_left:
		# Se o jogador for detectado à esquerda
		set_state(State.ATTACK)
		anim_sprite.flip_h = true  # Vira o sprite para a esquerda
		# --- ATUALIZAÇÃO DO FIREPOINT ---
		fire_point.position.x = -fire_point_default_x
		
	elif player_on_right:
		# Se o jogador for detectado à direita
		set_state(State.ATTACK)
		anim_sprite.flip_h = false # Vira o sprite para a direita
		# --- ATUALIZAÇÃO DO FIREPOINT ---
		fire_point.position.x = fire_point_default_x
		
	else:
		# Se nenhum raio detectar o jogador
		set_state(State.IDLE)

# Função helper que verifica um raio específico
func check_player(ray: RayCast2D):
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider and collider.name == "RobotoBase":
			return collider # Retorna o nó do jogador
	return null # Não encontrou o jogador

# Função que controla a troca de estados
func set_state(new_state):
	if new_state == current_state:
		return
	
	current_state = new_state
	
	match current_state:
		State.IDLE:
			anim_sprite.play("idle")
			attack_timer.stop()
		State.ATTACK:
			anim_sprite.play("attack")
			attack_timer.start()

# Chamado quando o AttackTimer chega a zero
func _on_attack_timer_timeout():
	shoot()
	# Verifica se o jogador AINDA está na mira para continuar atirando
	if check_player(detection_ray_left) or check_player(detection_ray_right):
		attack_timer.start()
	else:
		set_state(State.IDLE)

func shoot():
	anim_sprite.play("attack")
	anim_sprite.frame = 0

	var bullet = ENEMY_BULLET_SCENE.instantiate()
	bullet.global_position = fire_point.global_position
	
	# O tiro agora usa o 'flip_h' do sprite para decidir a direção
	if anim_sprite.flip_h:
		bullet.direcao = Vector2.RIGHT
	else:
		bullet.direcao = Vector2.LEFT
	
	get_parent().add_child(bullet)

# --- Vida e Dano ---
func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()
