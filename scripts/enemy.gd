extends CharacterBody3D

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
	
	# Create a damage effect manager with position data
	var effect_manager = Node.new()
	effect_manager.name = "EnemyDamageEffect"
	
	# Store position as metadata (which works for any object)
	var pos = global_position
	effect_manager.set_meta("enemy_position", pos)
	
	# Add to scene
	get_tree().root.add_child(effect_manager)
	
	# Add a script to manage the effect
	effect_manager.set_script(GDScript.new())
	effect_manager.get_script().source_code = """
extends Node

var flash
var material
var particles = []

func _ready():
	# Get stored position from metadata
	var enemy_position = get_meta("enemy_position")
	
	# Create main flash effect
	flash = CSGSphere3D.new()
	flash.radius = 0.8  # Slightly larger than enemy
	
	# Create flash material with more vibrant color
	material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.3, 0.3, 0.8)  # Brighter red
	material.emission_enabled = true
	material.emission = Color(1, 0.3, 0.3, 0.8)
	material.emission_energy = 2.0  # More glow
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# Apply material
	flash.material_override = material
	
	# Add main flash to scene
	add_child(flash)
	flash.global_position = enemy_position
	
	# Create impact particles (smaller spheres)
	for i in range(5):
		var particle = CSGSphere3D.new()
		particle.radius = 0.2
		
		# Create particle material
		var part_material = StandardMaterial3D.new()
		part_material.albedo_color = Color(1, 0.5, 0.5, 0.7)
		part_material.emission_enabled = true
		part_material.emission = Color(1, 0.5, 0.5, 0.7)
		part_material.emission_energy = 1.5
		part_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		# Apply material
		particle.material_override = part_material
		
		# Add to scene
		add_child(particle)
		particle.global_position = enemy_position
		
		# Random direction for particle
		var angle = randf() * PI * 2.0
		var dir = Vector3(cos(angle), 0.5, sin(angle))
		var distance = randf_range(0.5, 1.0)
		
		# Store for reference
		particles.append({
			"node": particle,
			"material": part_material,
			"target_pos": enemy_position + dir * distance
		})
	
	# Animate main flash
	var flash_tween = get_tree().create_tween()
	flash_tween.tween_property(flash, "scale", Vector3(1.5, 1.5, 1.5), 0.15)
	flash_tween.parallel().tween_property(material, "albedo_color:a", 0.0, 0.2)
	flash_tween.parallel().tween_property(material, "emission:a", 0.0, 0.2)
	
	# Animate particles
	for p in particles:
		var p_tween = get_tree().create_tween()
		p_tween.tween_property(p.node, "global_position", p.target_pos, 0.2)
		p_tween.parallel().tween_property(p.node, "radius", 0.01, 0.2)
		p_tween.parallel().tween_property(p.material, "albedo_color:a", 0.0, 0.2)
	
	# Clean up after all animations complete
	flash_tween.tween_callback(queue_free)  # Queue free the manager itself
"""
	
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
	# Create a more visible attack effect manager
	var effect_manager = Node.new()
	effect_manager.name = "EnemyAttackEffectManager"
	
	# Add to scene first so it's part of the tree
	add_child(effect_manager)
	
	# Store the forward direction and position
	var forward_dir = -transform.basis.z.normalized()  # Forward direction
	var start_pos = global_position + Vector3(0, 1.0, 0)  # Start at enemy height
	var target_pos = start_pos + forward_dir * 2.0  # Project forward
	
	effect_manager.set_meta("start_position", start_pos)
	effect_manager.set_meta("target_position", target_pos)
	
	# Add a script to manage the effect
	effect_manager.set_script(GDScript.new())
	effect_manager.get_script().source_code = """
extends Node

var effect
var material

func _ready():
	# Get stored positions
	var start_position = get_meta("start_position")
	var target_position = get_meta("target_position")
	
	# Create a more visible projectile effect
	effect = CSGSphere3D.new()
	effect.radius = 0.3
	
	# Create a brighter material with emission
	material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.2, 0.2, 1.0)  # Bright red
	material.emission_enabled = true
	material.emission = Color(1, 0.2, 0.2, 1.0)
	material.emission_energy = 3.0
	
	# Apply material
	effect.material_override = material
	
	# Add to scene
	add_child(effect)
	effect.global_position = start_position
	
	# Animate with more visible effect
	var tween = get_tree().create_tween()
	tween.tween_property(effect, "global_position", target_position, 0.3)
	
	# Impact effect
	tween.tween_callback(func():
		effect.radius = 0.6
		
		var impact_tween = get_tree().create_tween()
		impact_tween.tween_property(effect, "radius", 0.01, 0.2)
		impact_tween.tween_callback(queue_free)  # Clean up the entire manager
	)
"""

func _die():
	# Notify game manager of enemy death
	GameManager.enemy_died()
	
	# Give experience to player
	GameManager.gain_experience(xp_value)
	
	# Create a separate manager node for death effects to prevent the "lambda capture freed" error
	var effect_manager = Node.new()
	effect_manager.name = "DeathEffectManager"
	
	# Store position as metadata (which works for any object)
	var pos = global_position
	effect_manager.set_meta("death_position", pos)
	
	# Add to scene
	get_tree().root.add_child(effect_manager)
	
	# Add a script to manage the effect
	effect_manager.set_script(GDScript.new())
	effect_manager.get_script().source_code = """
extends Node

var effect
var material
var particles = []

func _ready():
	# Get stored position from metadata
	var death_position = get_meta("death_position")
	
	# Create main explosion effect
	effect = CSGSphere3D.new()
	effect.radius = 1.0
	
	# Create material with glow
	material = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.3, 0.9, 0.9)  # Brighter purple
	material.emission_enabled = true
	material.emission = Color(0.9, 0.3, 0.9, 0.9)
	material.emission_energy = 3.0  # More energy
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# Apply material
	effect.material_override = material
	
	# Add to scene
	add_child(effect)
	effect.global_position = death_position
	
	# Add particle-like effects (small spheres that fly outward)
	for i in range(8):
		var particle = CSGSphere3D.new()
		particle.radius = 0.3
		
		# Slightly different color for each particle
		var part_material = StandardMaterial3D.new()
		var hue_offset = randf_range(-0.1, 0.1)
		part_material.albedo_color = Color(0.9 + hue_offset, 0.3 - hue_offset, 0.9, 0.8)
		part_material.emission_enabled = true
		part_material.emission = Color(0.9 + hue_offset, 0.3 - hue_offset, 0.9, 0.8)
		part_material.emission_energy = 2.0
		part_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		particle.material_override = part_material
		add_child(particle)
		
		# Random direction for particle
		var angle = randf() * PI * 2.0
		var elevation = randf_range(-PI/4, PI/4)
		var dir = Vector3(cos(angle) * cos(elevation), sin(elevation), sin(angle) * cos(elevation))
		var distance = randf_range(1.5, 3.0)
		
		# Position at center
		particle.global_position = death_position
		
		# Store for reference
		particles.append({"node": particle, "material": part_material, "dir": dir, "distance": distance})
	
	# Animate main explosion
	var tween = get_tree().create_tween()
	tween.tween_property(effect, "radius", 2.0, 0.3)
	tween.tween_property(effect, "radius", 0.01, 0.2)
	
	# Animate particles in parallel
	for p in particles:
		var p_tween = get_tree().create_tween()
		var target_pos = death_position + p.dir * p.distance
		p_tween.tween_property(p.node, "global_position", target_pos, 0.5)
		p_tween.parallel().tween_property(p.node, "radius", 0.01, 0.5)
		p_tween.parallel().tween_property(p.material, "albedo_color:a", 0.0, 0.5)
		p_tween.parallel().tween_property(p.material, "emission:a", 0.0, 0.5)
	
	# Clean up after all animations
	tween.tween_callback(queue_free)
"""
	
	# Remove enemy immediately
	queue_free()

func set_target(new_target):
	target = new_target
