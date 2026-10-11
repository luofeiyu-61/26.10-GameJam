extends Control
class_name ClientWishPage

@onready var now_gua_sprite: AnimatedSprite2D = $effects/gua/now_gua

@onready var yin_label: Label = $spirit/Yao/yin
@onready var yang_label: Label = $spirit/Yao/yang


var temp_gua:ENUMS.Gua

signal go_to_event
signal go_to_sacrifice
signal confirm_wish (gua:ENUMS.Gua)


func _ready() -> void:
	#debug
	var gua_popup:PopupMenu= $WishWindow/GuaMenuButton.get_popup()
	gua_popup.id_pressed.connect(changeGua)

#debug
func changeGuaDisplay(gua:ENUMS.Gua):
	match gua:
		ENUMS.Gua.Kun:
			now_gua_sprite.play("000")
		ENUMS.Gua.Gen:
			now_gua_sprite.play("001")
		ENUMS.Gua.Kan:
			now_gua_sprite.play("010")
		ENUMS.Gua.Xun:
			now_gua_sprite.play("011")
		ENUMS.Gua.Zhen:
			now_gua_sprite.play("100")
		ENUMS.Gua.Li:
			now_gua_sprite.play("101")
		ENUMS.Gua.Dui:
			now_gua_sprite.play("110")
		ENUMS.Gua.Qian:
			now_gua_sprite.play("110")
		ENUMS.Gua.NONE:
			now_gua_sprite.play("none")


#debug
func changeGua(gua_index:int):
	match gua_index:
		0:temp_gua=ENUMS.Gua.Qian
		1:temp_gua=ENUMS.Gua.Dui
		2:temp_gua=ENUMS.Gua.Li
		3:temp_gua=ENUMS.Gua.Zhen
		4:temp_gua=ENUMS.Gua.Xun
		5:temp_gua=ENUMS.Gua.Kan
		6:temp_gua=ENUMS.Gua.Gen
		7:temp_gua=ENUMS.Gua.Kun
	changeGuaDisplay(temp_gua)


func updateYao(yin:int,yang:int):
	yin_label.text="阴爻:%d"%yin
	yang_label.text="阳爻:%d"%yang



#TODO
func confirmWish():
	confirm_wish.emit(temp_gua)


func _on_sacrifice_pressed() -> void:
	go_to_sacrifice.emit()

func _on_eventstream_pressed() -> void:
	go_to_event.emit()
