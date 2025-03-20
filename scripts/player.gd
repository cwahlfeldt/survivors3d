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

func _create_attack_effect(target_position):
	# Add a simpler, more direct implementation that doesn't rely on dynamic scripts
	# This should help with debugging and ensuring the projectile is visible
	
	# Create the projectile
	var projectile = CSGSphere3D.new()
	projectile.radius = 0.5  # Even larger for visibility
	
	# Create bright glowing material
	var proj_material = StandardMaterial3D.new()
	proj_material.albedo_color = Color(1, 0.8, 0.2, 1.0)  # Yellow-orange
	proj_material.emission_enabled = true
	proj_material.emission = Color(1, 0.8, 0.2, 1.0)
	proj_material.emission_energy = 5.0  # Very bright glow
	
	# Apply material to projectile
	projectile.material_override = proj_material
	
	# Add directly to the root scene for maximum visibility
	get_tree().root.add_child(projectile)
	
	# Position it to start from player's position but slightly elevated
	projectile.global_position = global_position + Vector3(0, 1.0, 0)
	
	# Create a trail
	var trail = CSGSphere3D.new()
	trail.radius = 0.3
	var trail_material = StandardMaterial3D.new()
	trail_material.albedo_color = Color(1, 0.5, 0.0, 0.8)
	trail_material.emission_enabled = true
	trail_material.emission = Color(1, 0.5, 0.0, 0.8)
	trail_material.emission_energy = 3.0
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail.material_override = trail_material
	
	get_tree().root.add_child(trail)
	trail.global_position = global_position + Vector3(0, 1.0, 0)
	
	# Create animation tweens
	var proj_tween = get_tree().create_tween()
	proj_tween.tween_property(projectile, "global_position", target_position, 0.3)
	
	var trail_tween = get_tree().create_tween()
	trail_tween.tween_property(trail, "global_position", target_position, 0.4)
	
	# Handle impact effect
	proj_tween.tween_callback(func():
		# Create impact flash
		var impact = CSGSphere3D.new()
		impact.radius = 0.8
		
		var impact_material = StandardMaterial3D.new()
		impact_material.albedo_color = Color(1, 1, 0.3, 1.0)
		impact_material.emission_enabled = true
		impact_material.emission = Color(1, 1, 0.3, 1.0)
		impact_material.emission_energy = 5.0
		
		impact.material_override = impact_material
		get_tree().root.add_child(impact)
		impact.global_position = target_position
		
		# Animate impact and clean up
		var impact_tween = get_tree().create_tween()
		impact_tween.tween_property(impact, "radius", 1.2, 0.1)
		impact_tween.tween_property(impact, "radius", 0.01, 0.2)
		impact_tween.tween_callback(impact.queue_free)
		
		# Clean up projectile
		projectile.queue_free()
	)
	
	# Clean up trail after delay
	trail_tween.tween_callback(func():
		trail.queue_free()
	)

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
	
	# Create a damage effect manager with position data
	var effect_manager = Node.new()
	effect_manager.name = "PlayerDamageEffect"
	
	# Store position as metadata (which works for any object)
	var pos = global_position
	effect_manager.set_meta("player_position", pos)
	
	# Add to scene
	get_tree().root.add_child(effect_manager)
	
	# Add a script to manage the effect
	effect_manager.set_script(GDScript.new())
	effect_manager.get_script().source_code = """
extends Node

var flash
var material
var shield_effect
var shield_material

func _ready():
	# Get stored position from metadata
	var player_position = get_meta("player_position")
	
	# Create flash effect (inner sphere)
	flash = CSGSphere3D.new()
	flash.radius = 1.2  # Slightly larger than player
	
	# Create flash material with more vibrant color
	material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.2, 0.2, 0.8)  # Brighter red
	material.emission_enabled = true
	material.emission = Color(1, 0.2, 0.2, 0.8)
	material.emission_energy = 2.0  # More glow
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# Apply material
	flash.material_override = material
	
	# Add to scene
	add_child(flash)
	flash.global_position = player_position
	
	# Create shield-like outer effect
	shield_effect = CSGSphere3D.new()
	shield_effect.radius = 1.5  # Larger than flash
	
	# Create shield material
	shield_material = StandardMaterial3D.new()
	shield_material.albedo_color = Color(1, 0.5, 0.5, 0.4)  # Light red, more transparent
	shield_material.emission_enabled = true
	shield_material.emission = Color(1, 0.5, 0.5, 0.4)
	shield_material.emission_energy = 1.0
	shield_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# Apply shield material
	shield_effect.material_override = shield_material
	
	# Add shield to scene
	add_child(shield_effect)
	shield_effect.global_position = player_position
	
	# Animate inner flash
	var flash_tween = get_tree().create_tween()
	flash_tween.tween_property(flash, "scale", Vector3(1.5, 1.5, 1.5), 0.2)
	flash_tween.parallel().tween_property(material, "albedo_color:a", 0.0, 0.3)
	flash_tween.parallel().tween_property(material, "emission:a", 0.0, 0.3)
	
	# Animate shield effect
	var shield_tween = get_tree().create_tween()
	shield_tween.tween_property(shield_effect, "scale", Vector3(2.0, 2.0, 2.0), 0.4)
	shield_tween.parallel().tween_property(shield_material, "albedo_color:a", 0.0, 0.4)
	shield_tween.parallel().tween_property(shield_material, "emission:a", 0.0, 0.4)
	shield_tween.tween_callback(queue_free)  # Queue free the manager itself after shield animation
"""

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
