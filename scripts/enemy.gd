extends CharacterBody3D

# Preload the effect scenes
var projectile_effect_scene = preload("res://scenes/projectile_effect.tscn")
var damage_effect_scene = preload("res://scenes/damage_effect.tscn")
var explosion_effect_scene = preload("res://scenes/explosion_effect.tscn")

# Enemy properties
@export var health = 30.0
@export var max_health = 30.0
@export var speed = 4.0
@export var attack_damage = 20.0 # Increased damage
@export var attack_cooldown = 0.7 # Faster attack
@export var xp_value = 10

# State
var target = null
var attack_timer = 0.0
var can_attack = true

# References
@onready var health_bar = $HealthBar

func _ready():
	# Add to enemy group for targeting
	add_to_group("enemies")
	
	# Set up health bar
	health_bar.max_value = max_health
	health_bar.value = health
	
	# Scale health and damage based on game level
	var level_mult = 1.0 + (GameManager.level - 1) * 0.1
	max_health *= level_mult
	health = max_health
	attack_damage *= level_mult

func _physics_process(delta):
	# Track attack cooldown
	if not can_attack:
		attack_timer += delta
		if attack_timer >= attack_cooldown:
			attack_timer = 0.0
			can_attack = true
	
	# Always face target but maintain upright orientation
	if target:
		# Get direction to target
		var dir = target.global_position - global_position
		dir.y = 0  # Keep upright
		
		# Attack distance check - if close enough to attack
		if dir.length() < 2.0:
			# Look at target
			look_at(global_position + dir, Vector3.UP)
			
			if dir.length() > 0.5:
				# Move towards target if not super close
				dir = dir.normalized()
				velocity = dir * speed
			else:
				velocity = Vector3.ZERO
			
			# Attack if cooldown finished - now happens if within 2.0 units
			if can_attack:
				_attack_target()
				print("Enemy attacking from distance: ", dir.length())
		else:
			# Look at target
			look_at(global_position + dir, Vector3.UP)
			
			# Move towards target
			dir = dir.normalized()
			velocity = dir * speed
	
	# Apply movement
	set_velocity(velocity)
	move_and_slide()

func take_damage(amount):
	health -= amount
	health_bar.value = health
	
	# Create an instance of the damage effect scene
	var effect_instance = damage_effect_scene.instantiate()
	
	# Add to the scene tree
	get_tree().root.add_child(effect_instance)
	
	# Set up the effect with the enemy's position and a red color
	effect_instance.setup(global_position, Color(1, 0.3, 0.3, 0.8), 0.8, 0.2)
	
	if health <= 0:
		_die()

func _attack_target():
	can_attack = false
	
	# Apply damage to player - print debug info
	print("Enemy attacking player with damage: ", attack_damage)
	GameManager.take_damage(attack_damage)
	
	# Visual effect for attack
	_create_attack_effect()

func _create_attack_effect():
	# Calculate the forward direction and positions
	var forward_dir = -transform.basis.z.normalized()  # Forward direction
	var start_pos = global_position + Vector3(0, 1.0, 0)  # Start at enemy height
	var target_pos = start_pos + forward_dir * 2.0  # Project forward
	
	# Create an instance of the projectile effect
	var effect_instance = projectile_effect_scene.instantiate()
	
	# Add to the scene tree
	get_tree().root.add_child(effect_instance)
	
	# Set up the projectile with start and target positions, and a red color
	effect_instance.setup(
		start_pos, 
		target_pos,
		Color(1, 0.2, 0.2)  # Bright red
	)

func _die():
	# Notify game manager of enemy death
	GameManager.enemy_died()
	
	# Give experience to player
	GameManager.gain_experience(xp_value)
	
	# Create an instance of the explosion effect
	var effect_instance = explosion_effect_scene.instantiate()
	
	# Add to the scene tree
	get_tree().root.add_child(effect_instance)
	
	# Set up the explosion with the enemy's position and purple color
	effect_instance.setup(
		global_position,
		Color(0.9, 0.3, 0.9, 0.9), # Purple color
		1.0, # Size
		8    # Number of particles
	)
	
	# Remove enemy immediately
	queue_free()

func set_target(new_target):
	target = new_target
