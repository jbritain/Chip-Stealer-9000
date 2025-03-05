# GameHUD.gd
extends CanvasLayer

@onready var score_label = $PanelContainer/HBoxContainer/Label
var killfeed_container

func _ready():
	show()
	update_score_display(GlobalHandler.student_score, GlobalHandler.seagull_score)
	killfeed_container = VBoxContainer.new()
	
	add_child(killfeed_container)
	killfeed_container.position.y += 80
	
func _process(delta):
	if !GlobalHandler.is_seagull || Input.is_action_pressed("pan_camera"):
		visible = true
	else:
		visible = false
	
	
func update_score_display(student_score, seagull_score):
	score_label.text = "Walking: %d | Seagulls: %d" % [student_score, seagull_score]

func add_kill(killfeed):

	# Create and configure labels for the kill entry
	var killfeed_label = Label.new()
	killfeed_label.text = killfeed
	
	killfeed_container.add_child(killfeed_label)
	
func reset_killfeed():
	print("hud resetting killfeed")
	for each in killfeed_container.get_children():
		killfeed_container.remove_child(each)
		each.free()
	
