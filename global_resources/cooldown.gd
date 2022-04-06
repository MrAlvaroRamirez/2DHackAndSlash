var time = 0.0

func _init(max_time):
	self.time = max_time

func tick(delta):
	time = max(time - delta, 0)

func is_ready():
	if time > 0:
		return false
	return true
