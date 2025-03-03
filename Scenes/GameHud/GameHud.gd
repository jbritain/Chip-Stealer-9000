# GameHUD.gd
extends CanvasLayer

@onready var score_label = $PanelContainer/HBoxContainer/Label

func _ready():
	show()
	update_score_display(GlobalHandler.student_score, GlobalHandler.seagull_score)

func update_score_display(student_score, seagull_score):
	score_label.text = "Walking: %d | Seagulls: %d" % [student_score, seagull_score]
