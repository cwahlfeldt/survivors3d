extends Node3D

# Spawning properties
@export var spawn_radius_min = 15.0
@export var spawn_radius_max = 25.0
@export var enemy_scene: PackedScene
@export var player_node: Node

# Enemy types (could be expanded with more enemy types)
var enemy_types = ["basic"]

func _ready():
	# Connect to game manager's signals
	GameManager.connect("level_up", Callable(self, "_on_level_up"))
	
	# Set up timer to handle spawn waves
	var timer = Timer.new()
	timer.wait_time = 1.0  # Check every second
	timer.autostart = true
	timer.connect("timeout", Callable(self, "_on_spawn_timer"))
	add_child(timer)

func _on_spawn_timer():
	if GameManager.game_running and player_node and GameManager.current_enemies < GameManager.max_enemies:
		spawn_enemy()

func spawn_enemy():
	if not enemy_scene or not player_node:
		return
	
	# Choose a spawn position around the player
	var spawn_position = _get_random_spawn_position()
	
	# Create the enemy
	var enemy_instance = enemy_scene.instantiate()
	get_tree().root.add_child(enemy_instance)
	
	# Set enemy properties
	enemy_instance.global_position = spawn_position
	enemy_instance.set_target(player_node)
	
	# Increase enemy count in game manager
	GameManager.current_enemies += 1

func _get_random_spawn_position():
	# Get a random angle
	var angle = randf() * 2.0 * PI
	
	# Get random distance between min and max radius
	var distance = spawn_radius_min + randf() * (spawn_radius_max - spawn_radius_min)
	
	# Calculate position
	var spawn_pos = Vector3(
		player_node.global_position.x + cos(angle) * distance,
		player_node.global_position.y,  # Keep the same Y level as player
		player_node.global_position.z + sin(angle) * distance
	)
	
	return spawn_pos

func _on_level_up():
	# Potentially spawn more enemies when leveling up
	if randf() < 0.3:  # 30% chance to spawn a bonus wave
		for i in range(5):
			spawn_enemy()
