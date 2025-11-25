extends CanvasLayer

@onready var resume_btn: Button = $BoxContainer/menu_holder/resume_btn
@onready var quit_btn: Button = $BoxContainer/menu_holder/quit_btn
@onready var hover_sound: AudioStreamPlayer = $BoxContainer/menu_holder/HoverSound

func _ready():
	visible = false
	resume_btn.mouse_entered.connect(_on_button_hover)
	quit_btn.mouse_entered.connect(_on_button_hover)
	resume_btn.focus_entered.connect(_on_button_hover)
	quit_btn.focus_entered.connect(_on_button_hover)

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

func _on_button_hover() -> void:
	hover_sound.play() 
