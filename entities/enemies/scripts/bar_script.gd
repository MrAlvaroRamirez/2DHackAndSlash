extends Sprite

onready var life : float = owner.enemy_life

var temp_life = life;

onready var particle_node = get_node("Particles2D")

func _on_worm_damaged(damage):
	# Particle animation
	particle_node.position.x = -6 + (frame * 3)
	particle_node.restart()
	particle_node.emitting = true
	
	# Make bar decrease
	
	frame = 5 - stepify(damage, life/5)/(life/5)
	
	if (frame == 5 and damage > 0):
		frame = 4
