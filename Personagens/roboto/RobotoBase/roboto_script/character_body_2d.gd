# RobotoBase.gd (Final: Max Health = 4, com Dano por Contato)
extends CharacterBody2D

signal health_updated(current_health)

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var fire_point: Marker2D = $FirePoint
@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound 
@onready var damage_sound: AudioStreamPlayer2D = $DamageSound 
@onready var death_sound: AudioStreamPlayer2D = $DeathSound 
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound

const SPEED = 150.0
const CONTACT_DAMAGE = 1 # NOVO: Dano que o inimigo causa ao encostar
@export var jump_force: float = -350.0 	 	 
@export var double_jump_force: float = -290.0
const SHOOT_DURATION := 0.1
const BULLET_SCENE = preload("res://Personagens/roboto/RobotoBase/bullet/bullet.tscn")
const MUZZLE_SCENE = preload("res://Personagens/roboto/RobotoBase/bullet/muzzle.tscn")

@export var fire_rate: float = 0.3

# --- Variáveis de HP ---
@export var max_health: int = 4 
var current_health: int

# --- Variáveis de Habilidade ---
@export var DASH_SPEED: float = 350.0
@export var DASH_DURATION: float = 0.2
const MAX_JUMPS = 2

var habilidades = {
	"PuloDuplo": false,
	"Dash": false
}

# --- Variáveis de Limite de Queda ---
@export var death_fall_y: float = 600.0 


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
	
	_fire_point_default_x = fire_point.position.x
	
	if is_instance_valid(shoot_sound):
		shoot_sound.volume_db = -10.0
		
	var tela_puzzle = get_tree().root.get_node("Fase1/TelaPuzzle")
	if tela_puzzle:
		tela_puzzle.puzzle_resolvido.connect(_on_habilidade_desbloqueada)
	else:
		push_warning("Não foi possível encontrar a TelaPuzzle!")

func _physics_process(delta: float) -> void:
	
	# --- VERIFICAÇÃO DE MORTE POR QUEDA ---
	if global_position.y > death_fall_y:
		if not is_dead:
			_trigger_death_by_fall()
		return
	# --------------------------------------
	
	if is_dead:
		velocity += get_gravity() * delta
		move_and_slide()
		return
	
	# --- Aplica gravidade fora do chão E fora do Dash ---
	if not is_on_floor() and _dash_timer <= 0:
		velocity += get_gravity() * delta

	# Se estiver em hit, aplica o knockback (se houver, senão move_and_slide) e retorna
	if is_hit:
		move_and_slide()
		return
	
	if _dash_timer > 0:
		_dash_timer -= delta
		velocity.x = _dash_direction * DASH_SPEED
		velocity.y = 0
		
		modulate.a = 0.5
			
		_play_if_not("dash")
		move_and_slide()
		return
	else:
		modulate.a = 1.0
	
	if is_on_floor():
		_jumps_made = 0

	if Input.is_action_just_pressed("up"):
		var max_jumps_allowed = 1
		if habilidades["PuloDuplo"]:
			max_jumps_allowed = MAX_JUMPS
		if _jumps_made < max_jumps_allowed:
			if _jumps_made == 0:
				velocity.y = jump_force
			else:
				velocity.y = double_jump_force
			
			_play_jump_sound()
			
			_jumps_made += 1

	if Input.is_action_just_pressed("dash") and habilidades["Dash"]:
		_dash_timer = DASH_DURATION
		_dash_direction = 1.0 if not anim.flip_h else -1.0

	var direction_input := Input.get_axis("left", "right")
	
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
	
	# --- DETECÇÃO DE DANO POR CONTATO (NOVO) ---
	if not is_dead and not is_hit and _dash_timer <= 0:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			# Verifica se o objeto colidido está no grupo "enemy"
			if is_instance_valid(collider) and collider.is_in_group("enemy"):
				take_damage(CONTACT_DAMAGE)
				break 


func take_damage(amount):
	if _dash_timer > 0:
		return
		
	if current_health <= 0 or is_hit:
		return
	
	_play_damage_sound()
	
	is_hit = true
	current_health -= amount
	health_updated.emit(current_health)
	print("Roboto levou dano! Vida restante: ", current_health)
	
	if current_health <= 0:
		_play_death_sound() 
		
		is_dead = true
		anim.play("death")
	else:
		anim.play("hit")

func _trigger_death_by_fall():
	if is_dead:
		return
	
	is_dead = true
	current_health = 0
	health_updated.emit(current_health)
	
	_play_death_sound()
	
	anim.play("death")
	
func _on_animation_finished():
	if anim.animation == "hit":
		is_hit = false
		
		if not is_on_floor():
			velocity.y = 0 
			
		anim.play("idle")
	elif anim.animation == "death":
		get_tree().reload_current_scene()

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

# --- Funções de Áudio e Tiro ---
func _start_shoot_animation(direction_input: float) -> void:
	shoot_timer = SHOOT_DURATION
	_spawn_bullet()
	_show_muzzle_flash()
	_play_shoot_sound()

func _spawn_bullet() -> void:
	var bullet = BULLET_SCENE.instantiate()
	var direction = -1 if anim.flip_h else 1
	
	bullet.global_position = fire_point.global_position 
	
	var bullet_script_speed = bullet.get("speed") 
	bullet.set("velocity", Vector2(direction * bullet_script_speed, 0)) 
	
	get_tree().current_scene.add_child(bullet)

func _show_muzzle_flash() -> void:
	var muzzle_flash = MUZZLE_SCENE.instantiate()
	muzzle_flash.global_position = fire_point.global_position

	var flash_sprite = muzzle_flash.get_node_or_null("Flash")
	if flash_sprite:
		flash_sprite.flip_h = anim.flip_h

	get_tree().current_scene.add_child(muzzle_flash)

func _play_shoot_sound() -> void:
	if is_instance_valid(shoot_sound) and shoot_sound.stream != null:
		shoot_sound.play()
	elif not is_instance_valid(shoot_sound):
		push_warning("Nó AudioStreamPlayer2D (ShootSound) não foi encontrado ou é inválido.")
	else:
		push_warning("AudioStream para o som de tiro não foi configurado.")

func _play_damage_sound() -> void:
	if is_instance_valid(damage_sound) and damage_sound.stream != null:
		damage_sound.play()
	elif not is_instance_valid(damage_sound):
		push_warning("Nó AudioStreamPlayer2D (DamageSound) não foi encontrado ou é inválido.")
	else:
		push_warning("AudioStream para o som de dano não foi configurado.")

func _play_death_sound() -> void:
	if is_instance_valid(death_sound) and death_sound.stream != null:
		death_sound.play()
	elif not is_instance_valid(death_sound):
		push_warning("Nó AudioStreamPlayer2D (DeathSound) não foi encontrado ou é inválido.")
	else:
		push_warning("AudioStream para o som de morte não foi configurado.")
		
func _play_jump_sound() -> void:
	if is_instance_valid(jump_sound) and jump_sound.stream != null:
		jump_sound.play()
	elif not is_instance_valid(jump_sound):
		push_warning("Nó AudioStreamPlayer2D (JumpSound) não foi encontrado ou é inválido.")
	else:
		push_warning("AudioStream para o som de pulo não foi configurado.")
