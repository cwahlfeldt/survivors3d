extends Button

# UI References
@onready var name_label = $VBoxContainer/NameLabel
@onready var level_label = $VBoxContainer/LevelLabel
@onready var description_label = $VBoxContainer/DescriptionLabel

# Upgrade data
var upgrade_data = null

func set_upgrade_data(data):
	upgrade_data = data
	
	# Update UI
	name_label.text = data.name
	level_label.text = "Level " + str(data.level) + "/" + str(data.max_level)
	description_label.text = data.description
	
	# Visual feedback based on rarity/power
	match data.effect:
		"damage":
			modulate = Color(1.0, 0.5, 0.5)  # Red tint
		"fire_rate":
			modulate = Color(0.5, 0.5, 1.0)  # Blue tint
		"max_health":
			modulate = Color(0.5, 1.0, 0.5)  # Green tint
		"speed":
			modulate = Color(1.0, 1.0, 0.5)  # Yellow tint
		"area":
			modulate = Color(0.8, 0.5, 1.0)  # Purple tint
