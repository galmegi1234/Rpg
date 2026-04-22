extends Node

# Central damage / hit calculation — stateless utility functions.

func calculate_damage(attacker_attack: int, defender_defense: int) -> int:
	var base_dmg: int  = maxi(1, attacker_attack - defender_defense)
	var variance: int  = int(base_dmg * 0.2)
	var final_dmg: int = base_dmg + randi_range(-variance, variance)
	if randi() % 100 < 5:
		final_dmg = int(final_dmg * 1.75)
	return maxi(1, final_dmg)

func calculate_xp_reward(enemy_level: int, player_level: int) -> int:
	var base_xp: int = enemy_level * 15
	var level_diff   := player_level - enemy_level
	var modifier     := clampf(1.0 - level_diff * 0.1, 0.1, 2.0)
	return max(1, int(base_xp * modifier))

func calculate_gold_drop(enemy_level: int) -> int:
	return randi_range(enemy_level * 2, enemy_level * 5)

func is_dodge(attacker_speed: int, defender_speed: int) -> bool:
	var dodge_chance := clampf(float(defender_speed - attacker_speed) * 0.5, 0.0, 40.0)
	return randi() % 100 < int(dodge_chance)

func knockback_vector(from_pos: Vector2, to_pos: Vector2, force: float) -> Vector2:
	var dir := (to_pos - from_pos).normalized()
	return dir * force
