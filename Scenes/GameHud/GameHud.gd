# GameHUD.gd
extends CanvasLayer

@onready var score_label = $PanelContainer/HBoxContainer/Label
var killfeed_container
var mission_container

func _ready():
	show()
	update_score_display(GlobalHandler.student_score, GlobalHandler.seagull_score)
	
	killfeed_container = VBoxContainer.new()
	mission_container = VBoxContainer.new()
	
	add_child(mission_container)
	add_child(killfeed_container)
	killfeed_container.position.y += 80
	mission_container.position.y += 40
	
	
func _process(delta):
	if !GlobalHandler.is_seagull || Input.is_action_pressed("pan_camera"):
		$Crosshair.visible = true
	else:
		$Crosshair.visible = false
	
	
func update_score_display(student_score, seagull_score):
	score_label.text = "Walking: %d | Seagulls: %d" % [student_score, seagull_score]

func add_kill(killfeed):

	# Create and configure labels for the kill entry
	var killfeed_label = Label.new()
	killfeed_label.text = killfeed
	
	killfeed_container.add_child(killfeed_label)
	
func add_mission(mission):
	print("adding mission")
	var mission_label = Label.new()
	mission_label.text = mission
	
	mission_container.add_child(mission_label)
	
func reset_killfeed():
	print("hud resetting killfeed")
	for each in killfeed_container.get_children():
		killfeed_container.remove_child(each)
		each.free()
		
func reset_mission():
	for each in mission_container.get_children():
		mission_container.remove_child(each)
		each.free()
	
