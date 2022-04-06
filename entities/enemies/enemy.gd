extends KinematicBody2D

export(int) var speed = 40
onready var player = get_parent().get_node("Player")
#onready var nav = get_tree().get_root().get_node("GameManager/Navigation2D")
onready var bar = get_node("bar")

onready var worm_anim = $AnimationPlayer

onready var hp_transform = $HealthBar/Sprite
var hp = 5

var walking_around = false
var chasing_player = false

#default 0.14
var knock_time = 0.2
var last_time = 0.2
var attacking = false
onready var attack_timer: Timer = get_node("Timer")
var stunned = false
var dead = false
var wait_til_next = 0
var way:Vector2

var movedir = Vector2(0,0)

var hit_fx = load("res://entities/FX/hit.tscn")

var direction = "right"

onready var explosion_fx = load("res://boom.tscn")

func _process(delta):
	if attacking == true && !dead:
		do_damage(delta)
	
	if !stunned && !dead:
		if global_position.distance_to(player.global_position) > 10:
			var wy = get_path()
			if wy == false || way == Vector2.ZERO:
				movedir = (player.global_position - global_position).normalized()
			else:
				movedir = way
			move_and_slide(movedir * speed,Vector2(0,0))
			anim_play("run_")
	else:
		move_and_slide(-movedir * (speed*2.8),Vector2(0,0))

func get_path():
	if wait_til_next == 0:
		wait_til_next = randi()%20+5	
		var cast = get_world_2d().direct_space_state
		var result = cast.intersect_ray(global_position, player.global_position, [], 32)
		if result.empty():
			way = Vector2.ZERO
			return false
		else:
			#way = nav.get_simple_path(global_position, player.global_position, true)[1]
			#way = (way - global_position).normalized()
			return true
	else :
		wait_til_next -= 1
		return true
	
func do_damage(delta):
	if stunned: return
	if !attack_timer.is_stopped(): return	
	attack_timer.set_wait_time(last_time)
	attack_timer.start()

func take_damage(damage_points):
	hp -= damage_points
	
	bar.frame += 1
	
	var hit_effect = hit_fx.instance()
	get_parent().add_child(hit_effect)
	hit_effect.playing = true
	hit_effect.get_child(0).playing = true
	hit_effect.set_position(global_position)
	
	if hp <=0:
		dead = true
		worm_anim.playback_speed = 3.5
		worm_anim.play("die_" + direction)
		hp_transform.scale = Vector2(0,1)
		stunned = true
	
	stunned = true
	attack_timer.stop()
	attack_timer.set_wait_time(knock_time)
	attack_timer.start()
	
	#hp_transform.scale = Vector2(float(hp)/20,1)
	
	#var pos = hp_transform.get_position()
	#pos.x = -11 *   (1- (float(hp)/20))
	#hp_transform.set_position(pos)
	$CharSprite.material.set_shader_param("new",Color("00ffffff"))
	
func anim_play(type):
	if abs(movedir.x) >= abs(movedir.y):
		if movedir.x < 0:
			direction = "left"
		else:
			direction = "right"
	else:
		if movedir.y < 0:
			direction = "back"
		else:
			direction = "front"
			
	var anim = type + direction
	
	if worm_anim.current_animation != anim:
		worm_anim.play(anim)

func _on_AnimationPlayer_animation_finished(anim_name):
	if "die" in anim_name:
		var explosion = explosion_fx.instance()
		explosion.position = global_position + Vector2(0,6)
		get_node("/root/Node2D/YSort").add_child(explosion)
		queue_free()
		return
		
func _on_Timer_timeout():
	attack_timer.stop()
	if dead:
		speed = 0
		worm_anim.play("die")
		return
		
	if stunned:
		stunned = false
		$CharSprite.material.set_shader_param("new",Color("00000000"))
	elif attacking:
		last_time = 0.1
		#player.knockback(global_position, true)

func _on_Area2D_area_entered(area):
	if "player" in area.name:
		attacking = true

func _on_Area2D_area_exited(area):
	if "player" in area.name:
		last_time = attack_timer.time_left
		attacking = false
