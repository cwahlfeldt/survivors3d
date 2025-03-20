extends Node

# Game state
var score = 0
var level = 1
var time_elapsed = 0
var game_running = false

# Player stats
var player_health = 100
var player_max_health = 100
var player_experience = 0
var player_level = 1
var experience_to_next_level = 100

# Enemy spawning
var enemy_spawn_timer = 0
var enemy_spawn_interval = 2.0
var max_enemies = 50
var current_enemies = 0
var difficulty_multiplier = 1.0

# Upgrades and weapons
var available_upgrades = []
var selected_upgrades = []

signal experience_gained(amount)
signal level_up
signal player_hit(damage)
signal game_over

func _ready():
	initialize_upgrades()

func _process(delta):
	if game_running:
		time_elapsed += delta
		
		# Handle enemy spawning
		enemy_spawn_timer += delta
		if enemy_spawn_timer >= enemy_spawn_interval and current_enemies < max_enemies:
			enemy_spawn_timer = 0
			spawn_enemy()

func initialize_upgrades():
	# Define available upgrades
	available_upgrades = [
		{
			"name": "Fire Rate",
			"description": "Increases attack speed by 10%",
			"max_level": 5,
			"effect": "fire_rate",
			"amount": 0.1
		},
		{
			"name": "Damage",
			"description": "Increases attack damage by 15%",
			"max_level": 5,
			"effect": "damage",
			"amount": 0.15
		},
		{
			"name": "Health",
			"description": "Increases max health by 20",
			"max_level": 5,
			"effect": "max_health",
			"amount": 20
		},
		{
			"name": "Speed",
			"description": "Increases movement speed by 10%",
			"max_level": 3,
			"effect": "speed",
			"amount": 0.1
		},
		{
			"name": "Area",
			"description": "Increases attack area by 15%",
			"max_level": 3,
			"effect": "area",
			"amount": 0.15
		}
	]

func start_game():
	score = 0
	level = 1
	time_elapsed = 0
	player_health = player_max_health
	player_experience = 0
	player_level = 1
	experience_to_next_level = 100
	enemy_spawn_interval = 2.0
	current_enemies = 0
	difficulty_multiplier = 1.0
	selected_upgrades = []
	game_running = true

func end_game():
	game_running = false
	emit_signal("game_over")

func gain_experience(amount):
	player_experience += amount
	emit_signal("experience_gained", amount)
	
	if player_experience >= experience_to_next_level:
		player_level += 1
		player_experience -= experience_to_next_level
		experience_to_next_level = int(experience_to_next_level * 1.2)
		emit_signal("level_up")

func take_damage(amount):
	player_health -= amount
	emit_signal("player_hit", amount)
	
	if player_health <= 0:
		end_game()

func spawn_enemy():
	current_enemies += 1
	# The actual spawning happens in the main scene

func enemy_died():
	current_enemies -= 1
	score += 10

func increase_difficulty():
	level += 1
	difficulty_multiplier += 0.1
	enemy_spawn_interval = max(0.5, enemy_spawn_interval - 0.1)
	max_enemies += 5
