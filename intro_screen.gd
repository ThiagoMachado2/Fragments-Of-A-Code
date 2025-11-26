extends Control

@export var text_scroll_speed = 40.0
@export var end_margin_offset = 250.0

@onready var text_node = $CanvasLayer/RichTextLabel
@onready var final_prompt_label = $CanvasLayer2/FinalPromptLabel
@onready var fade_fader = $CanvasLayer_FADER/FadeFader
@onready var exit_fader = $ExitFader

@onready var enter_echo_player = $EnterEchoPlayer
@onready var background_music = $BackgroundMusicPlayer

@onready var next_scene_path = "res://fase_1.tscn"

var text_finished = false
var prompt_active = false
var blink_timer: Timer

func _ready():
	exit_fader.hide()
	final_prompt_label.hide()
	
	background_music.play()
	
	fade_fader.color = Color(0, 0, 0, 1)
	
	var tween = create_tween()
	
	tween.tween_property(fade_fader, "color:a", 0.0, 3.0).set_ease(Tween.EASE_OUT)
	
	tween.finished.connect(_start_intro_sequence)

func _start_intro_sequence():
	
	blink_timer = Timer.new()
	blink_timer.wait_time = 0.5
	blink_timer.one_shot = false
	blink_timer.timeout.connect(_toggle_prompt_visibility)
	add_child(blink_timer)
	
	var end_timer = Timer.new()
	add_child(end_timer)

	var total_height = text_node.get_content_height()
	var viewport_height = get_viewport_rect().size.y
	var initial_y = text_node.position.y
	
	var total_distance = (initial_y + total_height + viewport_height) - end_margin_offset
	total_distance = max(0.0, total_distance)
	
	var time_needed = total_distance / text_scroll_speed
	
	end_timer.wait_time = time_needed
	end_timer.one_shot = true
	
	end_timer.timeout.connect(_show_final_prompt)
	end_timer.start()


func _process(delta):
	if not text_finished:
		text_node.position.y -= text_scroll_speed * delta

func _toggle_prompt_visibility():
	final_prompt_label.visible = not final_prompt_label.visible

func _input(event):
	if event.is_action_pressed("ui_accept"):
		
		if not text_finished or prompt_active:
			_change_scene(next_scene_path)
			

func _show_final_prompt():
	text_finished = true
	prompt_active = true
	
	if is_instance_valid(fade_fader):
		fade_fader.queue_free()
	
	final_prompt_label.show()
	final_prompt_label.visible = true
	
	blink_timer.start()

func _change_scene(path: String):
	text_finished = true
	prompt_active = false
	
	if is_instance_valid(blink_timer):
		blink_timer.stop()
	
	exit_fader.show()
	exit_fader.color = Color(0, 0, 0, 0)
	
	var initial_color = Color(1, 1, 1, 1)
	text_node.modulate = initial_color
	final_prompt_label.modulate = initial_color
	
	var target_transparent_color = Color(1, 1, 1, 0)
	
	var transition_duration = 1.2 
	
	var tween = create_tween()
	
	tween.tween_property(exit_fader, "color:a", 1.0, transition_duration).set_ease(Tween.EASE_IN)
	
	tween.tween_property(text_node, "modulate", target_transparent_color, transition_duration).set_ease(Tween.EASE_IN)
	
	tween.tween_property(final_prompt_label, "modulate", target_transparent_color, transition_duration).set_ease(Tween.EASE_IN)
	
	tween.tween_property(background_music, "volume_db", -60.0, transition_duration).set_ease(Tween.EASE_IN)
	
	enter_echo_player.play()
	
	await tween.finished
	
	get_tree().change_scene_to_file(path)
