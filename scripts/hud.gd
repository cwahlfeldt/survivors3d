extends Control

# UI References
@onready var score_label = $ScoreLabel
@onready var time_label = $TimeLabel
@onready var level_label = $LevelLabel
@onready var xp_bar = $XPBar
@onready var health_bar = $HealthBar
@onready var game_over_panel = $GameOverPanel
@onready var final_score_label = $GameOverPanel/VBoxContainer/FinalScoreLabel
@onready var restart_button = $GameOverPanel/VBoxContainer/RestartButton

# Declare the restart_game signal
signal restart_game

func _ready():
	# Hide game over panel initially
	game_over_panel.visible = false
	
	# Connect to game manager signals
	GameManager.connect("experience_gained", Callable(self, "_on_experience_gained"))
	GameManager.connect("level_up", Callable(self, "_on_level_up"))
	GameManager.connect("player_hit", Callable(self, "_on_player_hit"))
	GameManager.connect("game_over", Callable(self, "_on_game_over"))
	
	# Set up XP bar
	xp_bar.max_value = GameManager.experience_to_next_level
	xp_bar.value = 0
	
	# Set up health bar
	health_bar.max_value = GameManager.player_max_health
	health_bar.value = GameManager.player_health
	
	# Connect restart button
	restart_button.connect("pressed", Callable(self, "_on_restart_button_pressed"))
	
	# Initialize labels
	_update_labels()

func _process(delta):
	if GameManager.game_running:
		_update_labels()

func _update_labels():
	# Update score
	score_label.text = "Score: " + str(GameManager.score)
	
	# Update time
	var minutes = int(GameManager.time_elapsed / 60)
	var seconds = int(GameManager.time_elapsed) % 60
	time_label.text = "Time: %02d:%02d" % [minutes, seconds]
	
	# Update level
	level_label.text = "Level: " + str(GameManager.level)

func _on_experience_gained(amount):
	# Update XP bar
	xp_bar.max_value = GameManager.experience_to_next_level
	xp_bar.value = GameManager.player_experience
	
	# Simple XP gain visualization
	var xp_popup = Label.new()
	xp_popup.text = "+" + str(amount) + " XP"
	xp_popup.modulate = Color(0.5, 1.0, 0.5, 1.0)  # Green
	add_child(xp_popup)
	
	# Position it randomly near the XP bar
	xp_popup.position = xp_bar.position + Vector2(randf_range(-50, 50), randf_range(-20, 20))
	
	# Animate and remove
	var tween = get_tree().create_tween()
	tween.tween_property(xp_popup, "modulate:a", 0.0, 1.0)
	tween.tween_property(xp_popup, "position:y", xp_popup.position.y - 30, 1.0)
	tween.tween_callback(xp_popup.queue_free)

func _on_level_up():
	# Update XP bar
	xp_bar.max_value = GameManager.experience_to_next_level
	xp_bar.value = GameManager.player_experience
	
	# Level up effect
	var level_popup = Label.new()
	level_popup.text = "LEVEL UP!"
	level_popup.modulate = Color(1.0, 1.0, 0.0, 1.0)  # Yellow
	level_popup.add_theme_font_size_override("font_size", 32)
	add_child(level_popup)
	
	# Position it in the center
	level_popup.position = Vector2(get_viewport_rect().size.x / 2 - 80, get_viewport_rect().size.y / 2 - 50)
	
	# Animate and remove
	var tween = get_tree().create_tween()
	tween.tween_property(level_popup, "scale", Vector2(1.5, 1.5), 0.5)
	tween.tween_property(level_popup, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(level_popup, "modulate:a", 0.0, 0.5)
	tween.tween_callback(level_popup.queue_free)

func _on_player_hit(damage):
	# Update health bar with explicit update
	print("HUD updating health bar. New health: ", GameManager.player_health)
	health_bar.value = GameManager.player_health
	
	# Damage popup
	var damage_popup = Label.new()
	damage_popup.text = "-" + str(damage)
	damage_popup.modulate = Color(1.0, 0.2, 0.2, 1.0)  # Red
	add_child(damage_popup)
	
	# Position it near the health bar
	damage_popup.position = health_bar.position + Vector2(randf_range(-30, 30), randf_range(-10, 10))
	
	# Animate and remove
	var tween = get_tree().create_tween()
	tween.tween_property(damage_popup, "modulate:a", 0.0, 0.8)
	tween.tween_property(damage_popup, "position:y", damage_popup.position.y - 20, 0.8)
	tween.tween_callback(damage_popup.queue_free)

func _on_game_over():
	# Show game over panel
	game_over_panel.visible = true
	
	# Update final score
	final_score_label.text = "Final Score: " + str(GameManager.score)

func _on_restart_button_pressed():
	print("Restart button pressed")
	
	# Hide game over panel
	game_over_panel.visible = false
	
	# Restart game
	GameManager.start_game()
	
	# Emit signal to reset the main scene
	emit_signal("restart_game")
	print("Restart game signal emitted")
