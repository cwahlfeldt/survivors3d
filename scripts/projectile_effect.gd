extends Node3D

# Properties
var start_position: Vector3
var target_position: Vector3
var duration = 0.3
var impact_duration = 0.2

# References
@onready var projectile = $Projectile
@onready var trail = $Trail

func _ready():
	# Initialize positions
	if projectile:
		projectile.global_position = start_position
	
	if trail:
		trail.global_position = start_position
	
	# Start animation
	animate()

func setup(start_pos: Vector3, end_pos: Vector3, color: Color = Color(1, 0.7, 0.2)):
	start_position = start_pos
	target_position = end_pos
	
	# Apply color if the projectile exists
	if projectile and projectile.material_override:
		projectile.material_override.albedo_color = color
		projectile.material_override.emission = color
	
	if trail and trail.material_override:
		var trail_color = color.darkened(0.2)
		trail_color.a = 0.7
		trail.material_override.albedo_color = trail_color
		trail.material_override.emission = trail_color

func animate():
	# Animate projectile
	var proj_tween = create_tween()
	proj_tween.tween_property(projectile, "global_position", target_position, duration)
	
	# Animate trail
	var trail_tween = create_tween()
	trail_tween.tween_property(trail, "global_position", target_position, duration * 1.3)
	trail_tween.parallel().tween_property(trail, "scale", Vector3(0.5, 0.5, 0.5), duration * 1.3)
	
	# Impact effect
	proj_tween.tween_callback(create_impact)

func create_impact():
	# Create a mesh-based impact effect instead of CSG
	var impact = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.8
	sphere_mesh.height = 1.6
	impact.mesh = sphere_mesh
	
	var impact_material = StandardMaterial3D.new()
	impact_material.albedo_color = Color(1, 1, 0.3, 1.0)
	impact_material.emission_enabled = true
	impact_material.emission = Color(1, 1, 0.3, 1.0)
	impact_material.emission_energy = 5.0
	
	impact.material_override = impact_material
	add_child(impact)
	impact.global_position = target_position
	
	# Animate impact using scale instead of radius
	var impact_tween = create_tween()
	impact_tween.tween_property(impact, "scale", Vector3(1.5, 1.5, 1.5), impact_duration * 0.3)
	impact_tween.tween_property(impact, "scale", Vector3(0.01, 0.01, 0.01), impact_duration * 0.7)
	impact_tween.tween_callback(impact.queue_free)
	
	# Self-destruct after impact
	var cleanup_tween = create_tween()
	cleanup_tween.tween_interval(impact_duration + 0.1)
	cleanup_tween.tween_callback(queue_free)
