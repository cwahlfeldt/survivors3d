extends Control

signal upgrade_selected(upgrade)

# UI References
@onready var upgrade_container = $Panel/UpgradeContainer
@onready var title_label = $Panel/TitleLabel

# Upgrade option scene (will be created later)
@export var upgrade_option_scene: PackedScene

# State
var available_upgrades = []
var current_player = null

func _ready():
	# Hide the UI initially
	visible = false
	
	# Connect to game manager signals
	GameManager.connect("level_up", Callable(self, "_on_level_up"))

func _on_level_up():
	show_upgrades()

func show_upgrades():
	# Pause the game
	get_tree().paused = true
	
	# Get a random selection of upgrades
	available_upgrades = _get_random_upgrades(3)  # Show 3 options
	
	# Clear existing options
	for child in upgrade_container.get_children():
		child.queue_free()
	
	# Create new upgrade options
	for upgrade in available_upgrades:
		var option = upgrade_option_scene.instantiate()
		upgrade_container.add_child(option)
		
		# Set up the option
		option.set_upgrade_data(upgrade)
		option.connect("pressed", Callable(self, "_on_upgrade_selected").bind(upgrade))
	
	# Show the UI
	visible = true

func _get_random_upgrades(count):
	var all_upgrades = GameManager.available_upgrades.duplicate()
	var selected = []
	
	# Filter out upgrades that are already at max level
	var filtered_upgrades = []
	for upgrade in all_upgrades:
		var current_level = 0
		
		# Check if player already has this upgrade
		for selected_upgrade in GameManager.selected_upgrades:
			if selected_upgrade.effect == upgrade.effect:
				current_level = selected_upgrade.level
				break
		
		# Only add upgrades that aren't maxed out
		if current_level < upgrade.max_level:
			var new_upgrade = upgrade.duplicate()
			new_upgrade.level = current_level + 1
			filtered_upgrades.append(new_upgrade)
	
	# If we have fewer available upgrades than requested count, use all available
	count = min(count, filtered_upgrades.size())
	
	# Randomly select upgrades
	for i in range(count):
		if filtered_upgrades.size() > 0:
			var idx = randi() % filtered_upgrades.size()
			selected.append(filtered_upgrades[idx])
			filtered_upgrades.remove_at(idx)
	
	return selected

func _on_upgrade_selected(upgrade):
	# Update the player's selected upgrades
	var found = false
	for i in range(GameManager.selected_upgrades.size()):
		if GameManager.selected_upgrades[i].effect == upgrade.effect:
			GameManager.selected_upgrades[i].level = upgrade.level
			found = true
			break
	
	if not found:
		GameManager.selected_upgrades.append(upgrade)
	
	# Apply the upgrade to the player
	emit_signal("upgrade_selected", upgrade)
	
	# Hide the UI and unpause the game
	visible = false
	get_tree().paused = false
