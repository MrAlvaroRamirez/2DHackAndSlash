extends KinematicBody2D

export(String) var npc_name

export(bool) var walking_around = false
export(bool) var following_player = false
export(bool) var attack_mode = false
export(int) var want_to_say = 0 setget set_say

export(bool) var walk = false
export(bool) var idle = false
export(bool) var left = false
var talking: bool = false setget set_interact

var steping = false
var step_smoke = load("res://entities/FX/step.tscn")

onready var player = get_parent().get_node("Player")
onready var timer = $Timer

onready var nav = get_tree().get_root().get_node("GameManager/Navigation2D")
var going_to:Vector2
var start_point:Vector2
var moving_to:bool
var wait_til_next = 0
var way:Vector2

var movedir = Vector2(0,0)
var direction = "right"
var near: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	if walking_around:
		start_point = global_position
		timer.start()

func set_say(value):
	want_to_say = value
	if value == 0:
		pass
		#$Interact.visible = false
	else:
		pass
		#$Interact.visible = true

func set_interact(value):
	talking = value
	if value == true:
		pass
		#$Interact.visible = false
	else:
		pass
		#$Interact.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if walk || idle:
		if left:
			movedir = Vector2(-1,0)
		else:
			movedir = Vector2(1,0)
		if walk:
			if !steping : next_step()
			anim_play("run_")
		if idle:
			anim_play("idle_")
			steping = false
		return
	
	if following_player == true && !talking:	
		var dist = global_position.distance_to(player.global_position)
		if near:
			if dist > 40:
				var wy = get_path()
				if wy == false || way == Vector2.ZERO:
					movedir = (player.global_position - global_position).normalized()
				else:
					movedir = way
				move_and_slide(movedir * 60,Vector2(0,0))
				near = false
		else:
			if dist > 16:
				var wy = get_path()
				if wy == false || way == Vector2.ZERO:
					movedir = (player.global_position - global_position).normalized()
				else:
					movedir = way
				move_and_slide(movedir * 60,Vector2(0,0))
			else:
				near = true
				movedir = Vector2(0,0)
				
	elif walking_around && !talking:
		if moving_to:
			movedir = (going_to - global_position).normalized()
			move_and_slide(movedir * 35,Vector2(0,0))
			if global_position.distance_to(going_to) <= 1:
				movedir = Vector2(0,0)
				moving_to = false
				timer.wait_time = randi()%4+1
				timer.start()
	
	if movedir.round() != Vector2(0,0):
		if !steping : next_step()
		anim_play("run_")
	else:
		anim_play("idle_")
		steping = false

func next_step():
	steping = true
	timer.set_wait_time(.6)
	timer.start()

func get_path():
	if wait_til_next == 0:
		wait_til_next = randi()%20+5	
		var cast = get_world_2d().direct_space_state
		var result = cast.intersect_ray(global_position, player.global_position, [], 32)
		if result.empty():
			way = Vector2.ZERO
			return false
		else:
			way = nav.get_simple_path(global_position, player.global_position, true)[1]
			way = (way - global_position).normalized()
			return true
	else :
		wait_til_next -= 1
		return true

func reset_direction(pos):
	if((pos.x - global_position.x) > 0):
		direction = "right"
	else:
		direction = "left"

func anim_play(type):
	if movedir.round() != Vector2(0,0):
		if movedir.x < 0:
			direction = "left"
		else:
			direction = "right"
			
	var anim = type + direction
	
	if $AnimationPlayer.current_animation != anim:
		$AnimationPlayer.play(anim)


func _on_Timer_timeout():
	moving_to = true
	going_to = start_point + Vector2(rand_range(-20,20),rand_range(-20,20))
	
	if steping:		
		steping = false
		var step_instance = step_smoke.instance()
		get_parent().add_child(step_instance)
		step_instance.playing = true
		step_instance.set_position(global_position - Vector2(0,0.1))
