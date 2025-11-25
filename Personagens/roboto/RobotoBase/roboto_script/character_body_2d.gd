# RobotoBase.gd (Atualizado com FirePoint)
extends CharacterBody2D

signal health_updated(current_health)

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
# --- NOVO: Referência para o FirePoint ---
@onready var fire_point: Marker2D = $FirePoint

const SPEED = 150.0
@export var jump_force: float = -350.0        # Altura do pulo normal 
@export var double_jump_force: float = -290.0 # Altura do pulo duplo
const SHOOT_DURATION := 1
const BULLET_SCENE = preload("res://Personagens/roboto/RobotoBase/bullet/bullet.tscn")
const MUZZLE_SCENE = preload("res://Personagens/roboto/RobotoBase/bullet/muzzle.tscn")

@export var fire_rate: float = 0.3

# --- Variáveis de HP ---
@export var max_health: int = 10 # Total de pips de vida
var current_health: int

# --- Variáveis de Habilidade ---
@export var DASH_SPEED: float = 350.0
@export var DASH_DURATION: float = 0.2
const MAX_JUMPS = 2

var habilidades = {
	"PuloDuplo": false,
	"Dash": false
}

var _jumps_made = 0
var _dash_timer = 0.0
var _dash_direction = 1.0
var was_on_floor: bool = true
var shoot_timer: float = 0.0
var fire_cooldown: float = 0.0
var is_hit: bool = false
var is_dead: bool = false

var _fire_point_default_x: float

func _ready() -> void:
	current_health = max_health
	
	if anim.animation == "":
		anim.play("idle")
		
	anim.animation_finished.connect(_on_animation_finished)
	
	# Salva a posição X do FirePoint ---
	_fire_point_default_x = fire_point.position.x
		
	var tela_puzzle = get_tree().root.get_node("Fase1/TelaPuzzle")
	if tela_puzzle:
		tela_puzzle.puzzle_resolvido.connect(_on_habilidade_desbloqueada)
	else:
		push_warning("Não foi possível encontrar a TelaPuzzle!")

func _physics_process(delta: float) -> void:
	
	if is_dead:
		velocity += get_gravity() * delta
		move_and_slide()
		return
	if is_hit:
		move_and_slide()
		return
	
	if _dash_timer > 0:
		_dash_timer -= delta
		velocity.x = _dash_direction * DASH_SPEED
		velocity.y = 0
		
		# Deixa o sprite meio transparente (50% opacidade)
		modulate.a = 0.5
			
		_play_if_not("dash")
		move_and_slide()
		return
	else:
		# Garante que o sprite volte ao normal (100% opacidade) quando o dash acabar
		modulate.a = 1.0
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_on_floor():
		_jumps_made = 0

	if Input.is_action_just_pressed("up"):
		var max_jumps_allowed = 1
		if habilidades["PuloDuplo"]:
			max_jumps_allowed = MAX_JUMPS
		if _jumps_made < max_jumps_allowed:
			# Se for o primeiro pulo (jumps_made é 0), usa força normal
			# Se for o segundo pulo (jumps_made é 1), usa força do pulo duplo
			if _jumps_made == 0:
				velocity.y = jump_force
			else:
				velocity.y = double_jump_force
				
			_jumps_made += 1

	if Input.is_action_just_pressed("dash") and habilidades["Dash"]:
		_dash_timer = DASH_DURATION
		_dash_direction = 1.0 if not anim.flip_h else -1.0

	var direction_input := Input.get_axis("left", "right")
	
	# --- Vira o FirePoint ---
	if direction_input > 0:
		anim.flip_h = false
		fire_point.position.x = _fire_point_default_x
	elif direction_input < 0:
		anim.flip_h = true
		fire_point.position.x = -_fire_point_default_x

	if direction_input != 0:
		velocity.x = direction_input * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

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

# --- (Função take_damage e _on_animation_finished permanecem iguais) ---
func take_damage(amount):
	# Se o dash estiver ativo (_dash_timer > 0), o jogador é invulnerável.
	if _dash_timer > 0:
		return
		
	if current_health <= 0 or is_hit:
		return
	is_hit = true
	current_health -= amount
	health_updated.emit(current_health)
	print("Roboto levou dano! Vida restante: ", current_health)
	if current_health <= 0:
		is_dead = true
		anim.play("death")
	else:
		anim.play("hit")
	
func _on_animation_finished():
	if anim.animation == "hit":
		is_hit = false
		anim.play("idle")
	elif anim.animation == "death":
		get_tree().reload_current_scene()

# --- (Função _on_habilidade_desbloqueada e _play_if_not permanecem iguais) ---
func _on_habilidade_desbloqueada(nome_habilidade: String):
	if habilidades.has(nome_habilidade):
		habilidades[nome_habilidade] = true
		print("Roboto desbloqueou: ", nome_habilidade)
	else:
		print("Recebida habilidade desconhecida: ", nome_habilidade)

func _play_if_not(name: String) -> void:
	if is_hit or is_dead:
		return
	if anim.animation != name:
		anim.play(name)

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

# --- (Funções de tiro agora usam o FirePoint) ---
func _start_shoot_animation(direction_input: float) -> void:
	shoot_timer = SHOOT_DURATION
	_spawn_bullet()
	_show_muzzle_flash()

func _spawn_bullet() -> void:
	var bullet = BULLET_SCENE.instantiate()
	var direction = -1 if anim.flip_h else 1
	
	# Define a posição de spawn usando o FirePoint
	bullet.global_position = fire_point.global_position 
	
	# Pega a variável "speed" exportada do script da bala
	var bullet_script_speed = bullet.get("speed") 
	# Define a variável "velocity" DENTRO do script da bala
	bullet.set("velocity", Vector2(direction * bullet_script_speed, 0)) 
	
	# --------------------------
	
	get_tree().current_scene.add_child(bullet)

func _show_muzzle_flash() -> void:
	var muzzle_flash = MUZZLE_SCENE.instantiate()
	muzzle_flash.global_position = fire_point.global_position

	var flash_sprite = muzzle_flash.get_node_or_null("Flash")
	if flash_sprite:
		flash_sprite.flip_h = anim.flip_h

	get_tree().current_scene.add_child(muzzle_flash)
