extends Node3D

# Scene references
@onready var player = $Player
@onready var enemy_spawner = $EnemySpawner
@onready var hud = $HUD
@onready var upgrade_ui = $UpgradeUI
@onready var difficulty_timer = $DifficultyTimer

# Enemy scene reference
@export var enemy_scene: PackedScene

func _ready():
	# Set up references
	enemy_spawner.enemy_scene = enemy_scene
	enemy_spawner.player_node = player
	
	# Connect signals
	upgrade_ui.connect("upgrade_selected", Callable(self, "_on_upgrade_selected"))
	
	# Connect to HUD restart signal
	if hud.has_signal("restart_game"):
		hud.connect("restart_game", Callable(self, "_on_restart_game"))
	
	# Start the game
	GameManager.start_game()
	
	# Set up difficulty increase timer
	difficulty_timer.connect("timeout", Callable(self, "_on_difficulty_timer_timeout"))
	difficulty_timer.start()

func _on_upgrade_selected(upgrade):
	# Apply the upgrade to the player
	player.apply_upgrade(upgrade.effect, upgrade.amount)

func _on_restart_game():
	# Reset player position - the simplest approach that should work
	player.global_position = Vector3(0, 0.2, 0);
	
	# Stop any movement
	player.velocity = Vector3.ZERO
	
	print("Player restarted with reset transform")
	
	# Clear any existing enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()

func _on_difficulty_timer_timeout():
	if GameManager.game_running:
		GameManager.increase_difficulty()
