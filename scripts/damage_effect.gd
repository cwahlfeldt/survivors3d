extends Node3D

# Properties
var effect_position: Vector3
var effect_color = Color(1, 0.3, 0.3, 0.8)  # Default red
var effect_size = 0.8
var effect_duration = 0.2
var particle_count = 5

# References
@onready var main_flash = $MainFlash

# State
var particles = []

func _ready():
	# Position main flash
	if main_flash:
		main_flash.global_position = effect_position
	
	# Create particle effects
	create_particles()
	
	# Start animation
	animate()

func setup(position: Vector3, color: Color = Color(1, 0.3, 0.3, 0.8), size: float = 0.8, duration: float = 0.2):
	effect_position = position
	effect_color = color
	effect_size = size
	effect_duration = duration
	
	# Apply color if already created
	if main_flash and main_flash.material_override:
		main_flash.material_override.albedo_color = effect_color
		main_flash.material_override.emission = effect_color
		
		# Update the mesh size using scale instead of radius
		if main_flash.mesh and "radius" in main_flash.mesh:
			main_flash.mesh.radius = effect_size
		else:
			# If not directly accessible, use scale as fallback
			main_flash.scale = Vector3(effect_size, effect_size, effect_size)

func create_particles():
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.2
		
		# Create particle material
		var part_material = StandardMaterial3D.new()
		var part_color = effect_color.lightened(0.2)
		part_color.a = 0.7
		
		part_material.albedo_color = part_color
		part_material.emission_enabled = true
		part_material.emission = part_color
		part_material.emission_energy = 1.5
		part_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		# Apply material
		particle.material_override = part_material
		
		# Add to scene
		add_child(particle)
		particle.global_position = effect_position
		
		# Random direction for particle
		var angle = randf() * PI * 2.0
		var dir = Vector3(cos(angle), 0.5, sin(angle))
		var distance = randf_range(0.5, 1.0)
		
		# Store for animation
		particles.append({
			"node": particle,
			"material": part_material,
			"target_pos": effect_position + dir * distance
		})

func animate():
	# Animate main flash
	var flash_tween = create_tween()
	flash_tween.tween_property(main_flash, "scale", Vector3(1.5, 1.5, 1.5), effect_duration)
	flash_tween.parallel().tween_property(main_flash.material_override, "albedo_color:a", 0.0, effect_duration)
	flash_tween.parallel().tween_property(main_flash.material_override, "emission:a", 0.0, effect_duration)
	
	# Animate particles
	for p in particles:
		var p_tween = create_tween()
		p_tween.tween_property(p.node, "global_position", p.target_pos, effect_duration)
		p_tween.parallel().tween_property(p.node, "radius", 0.01, effect_duration)
		p_tween.parallel().tween_property(p.material, "albedo_color:a", 0.0, effect_duration)
	
	# Self-destruct after animation
	var cleanup_tween = create_tween()
	cleanup_tween.tween_interval(effect_duration * 1.2)
	cleanup_tween.tween_callback(queue_free)
