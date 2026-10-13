extends Control
class_name ClientWishPage

@onready var now_gua_sprite: AnimatedSprite2D = $effects/gua/now_gua

@onready var yin_label: Label = $spirit/Yao/yin
@onready var yang_label: Label = $spirit/Yao/yang

@onready var lunar_phase_now: Label = $effects/lunarPhaseNow/lunarPhase

@onready var spirit: Label = $spirit/status/spirit



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
	now_gua_sprite.play(ENUMS.gua2Binary(gua))

func renderLunarPhaseNow(lunar_phase:ENUMS.LunarPhase):
	lunar_phase_now.text="当前月相："+"\n"+ENUMS.lunarPhase2Text(lunar_phase)

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

func updateQi(spirit_now):
	spirit.text=ENUMS.qi2Text(spirit_now)

#TODO
func confirmWish():
	confirm_wish.emit(temp_gua)


func _on_sacrifice_pressed() -> void:
	go_to_sacrifice.emit()

func _on_eventstream_pressed() -> void:
	go_to_event.emit()
