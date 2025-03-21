# Survivors3D

Survivors3D is a 3D implementation of the popular auto-battler/survival roguelite genre inspired by games like Vampire Survivors. Built with the Godot Engine, this game features a player character that automatically attacks nearby enemies while the player focuses on movement and strategy.

## Game Features

- **3D Environment**: Fully 3D gameplay with an overhead camera perspective
- **Auto-attack System**: Your character automatically attacks the nearest enemy
- **Enemy Waves**: Progressively more difficult waves of enemies spawn around you
- **Experience System**: Earn XP by defeating enemies to level up
- **Upgrade System**: Choose from different upgrades each time you level up
- **Simple Controls**: WASD keys for movement
- **Visual Effects**: Projectiles, damage effects, and death animations

## How to Play

1. **Movement**: Use WASD keys to move your character around
2. **Combat**: Your character will automatically attack nearby enemies
3. **Leveling**: Defeat enemies to gain experience and level up
4. **Upgrades**: Choose one upgrade each time you level up
5. **Survive**: Try to survive as long as possible against increasingly difficult waves

## Project Structure

The game is organized into the following directories:

- **assets/**: Contains game resources (currently empty, using primitive shapes)
- **scenes/**: Contains Godot scene files
  - main.tscn: Main game scene
  - player.tscn: Player character scene
  - enemy.tscn: Enemy scene
  - projectile_effect.tscn: Visual effect for projectiles
  - damage_effect.tscn: Visual effect for damage
  - explosion_effect.tscn: Visual effect for explosions
  - upgrade_ui.tscn: UI for selecting upgrades
  - hud.tscn: Heads-up display with game information
- **scripts/**: Contains GDScript files
  - game_manager.gd: Global game state and logic
  - player.gd: Player behavior and controls
  - enemy.gd: Enemy AI and behavior
  - projectile_effect.gd: Projectile effect logic
  - damage_effect.gd: Damage effect logic
  - explosion_effect.gd: Explosion effect logic
  - upgrade_ui.gd: Upgrade selection UI logic
  - hud.gd: HUD logic
  - main.gd: Main scene controller

## Design Philosophy

The game follows these design principles:

1. **Modular Structure**: Each component is separated into its own scene and script
2. **Minimal Dependencies**: Components are designed to be easily modified or replaced
3. **Clean Visual Effects**: All effects are based on primitive shapes for a clean look
4. **Gameplay First**: Focus on the core gameplay loop rather than graphics

## Possible Feature Additions

### Short-term Enhancements

1. **Different Enemy Types**: Add various enemy behaviors (ranged, area, boss)
2. **Additional Weapons**: Implement different weapon types (area attack, projectile, melee)
3. **Passive Items**: Add items that give passive bonuses to the player
4. **Sound Effects**: Add audio for attacks, damage, level up, etc.
5. **Background Music**: Add soundtrack with different tracks for different stages
6. **Simple Terrain**: Add obstacles in the environment
7. **Mini-map**: Add a radar or mini-map to show enemies around the player
8. **Power-ups**: Add temporary power-ups that drop from enemies
9. **Dash Ability**: Add a dash/dodge movement ability

### Medium-term Features

1. **Character Selection**: Allow players to choose from different character types
2. **Character Classes**: Implement different playstyles (warrior, mage, archer)
3. **Advanced Upgrade Tree**: More complex upgrade paths with dependencies
4. **Enemy Spawning Patterns**: More sophisticated wave patterns
5. **Boss Encounters**: Special enemies with unique mechanics
6. **Biomes/Areas**: Different visual themes for areas with unique enemies
7. **Environmental Hazards**: Elements like lava, spikes, or traps
8. **Local Co-op**: Allow 2-4 players to play together on one machine
9. **Save System**: Save progress and unlocks between runs

### Long-term Ambitions

1. **Procedural Generation**: Random level generation for each run
2. **Meta-progression**: Permanent upgrades between runs
3. **Custom 3D Models**: Replace primitives with custom models
4. **Particle Effects**: Advanced particle systems for more polished visuals
5. **Story Mode**: Add a narrative with cutscenes and dialogue
6. **Online Multiplayer**: Network play capabilities
7. **Custom Runs**: Allow players to customize game parameters
8. **Mod Support**: Allow players to create and share mods
9. **Leaderboards**: Online leaderboards for comparing high scores
10. **Daily Challenges**: Special runs with fixed parameters

## Technical Requirements

- Godot Engine 4.x
- No additional plugins required (currently)

## Credits

Developed as a learning project for Godot Engine development.

## License

[Insert your preferred license here]

## Contributing

Contributions are welcome! Feel free to fork the repository and submit pull requests.

1. Fork the project
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request