extends Node3D

# Properties
var explosion_position: Vector3
var explosion_color = Color(0.9, 0.3, 0.9, 0.9)  # Default purple for death
var explosion_size = 1.0
var particle_count = 8

# References
@onready var main_explosion = $MainExplosion

# State
var particles = []

func _ready():
	# Position main explosion
	if main_explosion:
		main_explosion.global_position = explosion_position
	
	# Create particle effects
	create_particles()
	
	# Start animation
	animate()

func setup(position: Vector3, color: Color = Color(0.9, 0.3, 0.9, 0.9), size: float = 1.0, num_particles: int = 8):
	explosion_position = position
	explosion_color = color
	explosion_size = size
	particle_count = num_particles
	
	# Apply color if already created
	if main_explosion and main_explosion.material_override:
		main_explosion.material_override.albedo_color = explosion_color
		main_explosion.material_override.emission = explosion_color
		
		# Update mesh size if possible
		if main_explosion.mesh and "radius" in main_explosion.mesh:
			main_explosion.mesh.radius = explosion_size
		else:
			# Otherwise use scale
			main_explosion.scale = Vector3(explosion_size, explosion_size, explosion_size)

func create_particles():
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = explosion_size * 0.3
		
		# Slightly different color for each particle
		var part_material = StandardMaterial3D.new()
		var hue_offset = randf_range(-0.1, 0.1)
		var part_color = Color(
			explosion_color.r + hue_offset,
			explosion_color.g - hue_offset,
			explosion_color.b, 
			explosion_color.a - 0.1
		)
		
		part_material.albedo_color = part_color
		part_material.emission_enabled = true
		part_material.emission = part_color
		part_material.emission_energy = 2.0
		part_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		particle.material_override = part_material
		add_child(particle)
		
		# Random direction for particle
		var angle = randf() * PI * 2.0
		var elevation = randf_range(-PI/4, PI/4)
		var dir = Vector3(
			cos(angle) * cos(elevation),
			sin(elevation),
			sin(angle) * cos(elevation)
		)
		var distance = randf_range(1.5, 3.0) * explosion_size
		
		# Position at center
		particle.global_position = explosion_position
		
		# Store for animation
		particles.append({
			"node": particle,
			"material": part_material,
			"dir": dir,
			"distance": distance
		})

func animate():
	# Animate main explosion
	var tween = create_tween()
	
	# Animate the main explosion using scale since MeshInstance3D doesn't have radius property
	tween.tween_property(main_explosion, "scale", Vector3(2, 2, 2), 0.3)
	tween.tween_property(main_explosion, "scale", Vector3(0.01, 0.01, 0.01), 0.2)
	
	# Animate particles in parallel
	for p in particles:
		var p_tween = create_tween()
		var target_pos = explosion_position + p.dir * p.distance
		p_tween.tween_property(p.node, "global_position", target_pos, 0.5)
		p_tween.parallel().tween_property(p.node, "radius", 0.01, 0.5)
		p_tween.parallel().tween_property(p.material, "albedo_color:a", 0.0, 0.5)
		p_tween.parallel().tween_property(p.material, "emission:a", 0.0, 0.5)
	
	# Self-destruct after animation
	var cleanup_tween = create_tween()
	cleanup_tween.tween_interval(0.7) # Wait for explosion to complete
	cleanup_tween.tween_callback(queue_free)
