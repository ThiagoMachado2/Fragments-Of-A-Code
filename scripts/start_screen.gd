extends Control

# Caminhos para os AudioStreamPlayer
@onready var hover_sound = $MarginContainer/HBoxContainer/VBoxContainer/HoverSound
@onready var click_sound = $MarginContainer/HBoxContainer/VBoxContainer/ClickSound

func _ready() -> void:
	# Hover e Pressed
	for btn in get_tree().get_nodes_in_group("menu_buttons"):
		if btn is Button:
			# Conecta hover sound
			btn.connect("mouse_entered", Callable(self, "_on_button_hover"))
			# Conecta click sound
			btn.connect("pressed", Callable(self, "_on_button_pressed"))

func _on_button_hover() -> void:
	if hover_sound and hover_sound.stream:
		if hover_sound.playing:
			hover_sound.stop()
		hover_sound.play()

func _on_button_pressed() -> void:
	if click_sound and click_sound.stream:
		if click_sound.playing:
			click_sound.stop()
		click_sound.play()

func _on_new_game_btn_pressed() -> void:
	_on_button_pressed()
	# get_tree().change_scene_to_file("res://caminho/da_sua_cena.tscn")

func _on_carregar_game_btn_pressed() -> void:
	_on_button_pressed()
	# get_tree().change_scene_to_file("res://caminho/da_sua_cena.tscn")

func _on_options_btn_pressed() -> void:
	_on_button_pressed()
	# get_tree().change_scene_to_file("res://caminho/da_sua_cena.tscn")

func _on_credits_btn_pressed() -> void:
	_on_button_pressed()
	# get_tree().change_scene_to_file("res://caminho/da_sua_cena.tscn")

func _on_quit_btn_pressed() -> void:
	_on_button_pressed()
	get_tree().quit()
