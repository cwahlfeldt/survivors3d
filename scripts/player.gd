extends CharacterBody3D

# Movement properties
@export var speed = 10.0
@export var acceleration = 15.0
@export var deceleration = 20.0

# Combat properties
@export var attack_radius = 5.0
@export var attack_rate = 1.0
@export var attack_damage = 10.0

# Upgrade properties
var fire_rate_multiplier = 1.0
var damage_multiplier = 1.0
var area_multiplier = 1.0
var speed_multiplier = 1.0

# References
@onready var attack_timer = $AttackTimer
@onready var attack_area = $AttackArea/CollisionShape3D
@onready var camera = $Camera3D
@onready var health_bar = $HealthBar

# State
var attack_cooldown = 0.0
var can_attack = true
var targets = []

func _ready():
	# Set up attack area
	attack_area.shape.radius = attack_radius
	attack_timer.wait_time = 1.0 / attack_rate
	attack_timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))
	
	# Connect to game manager signals
	GameManager.connect("level_up", Callable(self, "_on_level_up"))
	GameManager.connect("player_hit", Callable(self, "_on_player_hit"))
	
	# Initialize health bar
	health_bar.max_value = GameManager.player_max_health
	health_bar.value = GameManager.player_health

func _physics_process(delta):
	# Handle movement
	var input_dir = Vector3.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	
	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized()
		
		# Calculate the desired velocity
		var target_velocity = input_dir * speed * speed_multiplier
		
		# Smoothly interpolate to the target velocity
		velocity = velocity.lerp(target_velocity, acceleration * delta)
	else:
		# Decelerate when no input
		velocity = velocity.lerp(Vector3.ZERO, deceleration * delta)
	
	# Apply movement
	set_velocity(velocity)
	move_and_slide()
	
	# Handle attacking
	if can_attack and not targets.is_empty():
		attack()

func _on_attack_timer_timeout():
	can_attack = true

func attack():
	can_attack = false
	attack_timer.start()
	
	# Find the closest enemy
	var closest_enemy = null
	var closest_distance = INF
	
	for enemy in targets:
		if enemy and is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_enemy = enemy
	
	# Attack the closest enemy
	if closest_enemy and is_instance_valid(closest_enemy):
		# Apply damage
		var damage = attack_damage * damage_multiplier
		closest_enemy.take_damage(damage)
		
		# Create direct visual effect for immediate feedback
		var simple_effect = CSGSphere3D.new()
		simple_effect.radius = 0.3
		var simple_material = StandardMaterial3D.new()
		simple_material.albedo_color = Color(1, 0.7, 0, 1.0)
		simple_material.emission_enabled = true
		simple_material.emission = Color(1, 0.7, 0, 1.0)
		simple_material.emission_energy = 3.0
		simple_effect.material_override = simple_material
		
		get_tree().root.add_child(simple_effect)
		simple_effect.global_position = global_position + Vector3(0, 1, 0)
		
		# Create visual effect for attack through the system
		_create_attack_effect(closest_enemy.global_position)
		
		# Simple animation and cleanup
		var direct_tween = get_tree().create_tween()
		direct_tween.tween_property(simple_effect, "global_position", closest_enemy.global_position, 0.2)
		direct_tween.tween_callback(simple_effect.queue_free)

# Preload the effect scenes
var projectile_effect_scene = preload("res://scenes/projectile_effect.tscn")
var damage_effect_scene = preload("res://scenes/damage_effect.tscn")

func _create_attack_effect(target_position):
	# Create an instance of the projectile effect
	var effect_instance = projectile_effect_scene.instantiate()
	
	# Add to the root scene for visibility
	get_tree().root.add_child(effect_instance)
	
	# Set up the effect with start and end positions
	var start_pos = global_position + Vector3(0, 1.0, 0)  # Slightly elevated
	effect_instance.setup(start_pos, target_position, Color(1, 0.8, 0.2))  # Yellow-orange color

func _on_attack_area_body_entered(body):
	if body.is_in_group("enemies"):
		targets.append(body)

func _on_attack_area_body_exited(body):
	if body.is_in_group("enemies"):
		targets.erase(body)

func _on_level_up():
	# Show upgrade UI in the main scene
	pass

func _on_player_hit(damage):
	# Debug print to verify damage is received
	print("Player hit! Damage: ", damage, " New health: ", GameManager.player_health)
	
	# Update health bar
	health_bar.value = GameManager.player_health
	
	# Create an instance of the damage effect
	var effect_instance = damage_effect_scene.instantiate()
	
	# Add to the scene tree
	get_tree().root.add_child(effect_instance)
	
	# Set up the effect with the player's position and a red color
	effect_instance.setup(
		global_position,
		Color(1, 0.3, 0.3, 0.8),  # Red color
		1.5,  # Larger size for player
		0.4   # Longer duration
	)

func apply_upgrade(upgrade_type, amount):
	match upgrade_type:
		"fire_rate":
			fire_rate_multiplier += amount
			attack_timer.wait_time = 1.0 / (attack_rate * fire_rate_multiplier)
		"damage":
			damage_multiplier += amount
		"max_health":
			GameManager.player_max_health += amount
			health_bar.max_value = GameManager.player_max_health
			GameManager.player_health += amount
			health_bar.value = GameManager.player_health
		"speed":
			speed_multiplier += amount
		"area":
			area_multiplier += amount
			attack_area.shape.radius = attack_radius * area_multiplier
