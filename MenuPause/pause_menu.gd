extends CanvasLayer

@onready var resume_btn: Button = $BoxContainer/menu_holder/resume_btn
@onready var quit_btn: Button = $BoxContainer/menu_holder/quit_btn
@onready var hover_sound: AudioStreamPlayer = $BoxContainer/menu_holder/HoverSound
@onready var controls_btn: Button = $BoxContainer/menu_holder/controls_btn # ✅ ADICIONADO: Botão de Controles

# ⚠️ CONSTANTE ADICIONADA: Defina o caminho correto para sua cena de Controles
const CONTROLS_SCENE_PATH = "res://ControleScreen/controls_screen.tscn"

func _ready():
	visible = false
	resume_btn.mouse_entered.connect(_on_button_hover)
	quit_btn.mouse_entered.connect(_on_button_hover)
	resume_btn.focus_entered.connect(_on_button_hover)
	quit_btn.focus_entered.connect(_on_button_hover)
	
	# ✅ ADICIONADO: Conexão do botão de Controles
	if controls_btn:
		controls_btn.mouse_entered.connect(_on_button_hover)
		controls_btn.focus_entered.connect(_on_button_hover)
		controls_btn.pressed.connect(_on_controls_btn_pressed)
	else:
		push_error("Nó 'controls_btn' não encontrado. Verifique o caminho em @onready.")

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		visible = true
		get_tree().paused = true
		resume_btn.grab_focus()

func _on_resume_btn_pressed() -> void:
	hover_sound.play()
	get_tree().paused = false
	visible = false

func _on_quit_btn_pressed() -> void:
	hover_sound.play()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://StartScreen/start_screen.tscn")
	
func _on_controls_btn_pressed() -> void:
	hover_sound.play()
	
	# 1. Salva o caminho da cena atual do jogo antes de mudar.
	#    Isto é crucial para o botão "Voltar" na cena de Controles.
	if get_tree().current_scene:
		Global.last_scene_path = get_tree().current_scene.scene_file_path
	else:
		push_warning("Cena atual não encontrada. Não foi possível salvar o caminho para 'Voltar'.")

	# 2. Despausa e muda para a cena de Controles
	get_tree().paused = false 
	var error = get_tree().change_scene_to_file(CONTROLS_SCENE_PATH)
	
	if error != OK:
		push_error("Não foi possível carregar a cena de Controles: ", CONTROLS_SCENE_PATH)

func _on_button_hover() -> void:
	hover_sound.play()
