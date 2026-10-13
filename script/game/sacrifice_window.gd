extends Control
class_name ClientSacrificePage


@onready var guy: TextureProgressBar = $RatioSetWindow/ResultPreview/Now/Guy
@onready var people: TextureProgressBar = $RatioSetWindow/ResultPreview/Now/people
@onready var animal: TextureProgressBar = $RatioSetWindow/ResultPreview/Now/animal
@onready var grain: TextureProgressBar = $RatioSetWindow/ResultPreview/Now/grain

@onready var guy_pre: TextureProgressBar = $RatioSetWindow/ResultPreview/Pre/GuyPre
@onready var people_pre: TextureProgressBar = $RatioSetWindow/ResultPreview/Pre/peoplePre
@onready var animal_pre: TextureProgressBar = $RatioSetWindow/ResultPreview/Pre/animalPre
@onready var grain_pre: TextureProgressBar = $RatioSetWindow/ResultPreview/Pre/grainPre


@onready var sacrifice_bar_pre: TextureProgressBar = $SacrificeBar/BarPre
@onready var sacrifice_bar: TextureProgressBar = $SacrificeBar/Bar

@onready var yao_pre_num: Label = $SacrificeBar/Qi/Label



#玩家调整的比例
var total_ratio:float
var people_ratio:float
var animal_ratio:float
var garin_ratio:float




signal go_to_event
signal go_to_wish
signal confirm_sacrifice(people_ratio:float,animal_ratio:float,garin_ratio:float,total_ratio:float)
signal preview_sacrifice_result(people_ratio:float,animal_ratio:float,garin_ratio:float,total_ratio:float)




#接受的是百分比
func renderPreviewBars(pre_people,pre_animal,pre_grain,pre_guy,sacrifice_value,new_yao_num):
	guy_pre.set_value_no_signal(pre_guy*guy_pre.max_value)
	people_pre.set_value_no_signal(pre_people*people_pre.max_value)
	animal_pre.set_value_no_signal(pre_animal*animal_pre.max_value)
	grain_pre.set_value_no_signal(pre_grain*grain_pre.max_value)
	if new_yao_num == 0:
		sacrifice_bar_pre.set_value_no_signal(sacrifice_value*sacrifice_bar_pre.max_value)
		yao_pre_num.text=""
	else:
		sacrifice_bar_pre.set_value_no_signal(sacrifice_bar_pre.max_value)
		yao_pre_num.text="+%d"%new_yao_num


#接受的是百分比
func renderBars(people_,animal_,grain_,guy_,sacrifice_value,new_yao_num):
	guy.set_value_no_signal(guy_*guy.max_value)
	people.set_value_no_signal(people_*people.max_value)
	animal.set_value_no_signal(animal_*animal.max_value)
	grain.set_value_no_signal(grain_*grain.max_value)
	sacrifice_bar.set_value_no_signal(sacrifice_value*sacrifice_bar.max_value)


func applyBarsAnimation(people,animal,grain,guy,sacrifice_value):
	pass

func spawnYaoAnimation(yao_num:int):
	pass




func _on_eventstream_pressed() -> void:
	go_to_event.emit()

func _on_wish_pressed() -> void:
	go_to_wish.emit()



#确认祭祀
func _on_confirmsacrifice_pressed() -> void:
	confirm_sacrifice.emit(people_ratio,animal_ratio,garin_ratio,total_ratio)




#调整比例滑条时实时计算预览结果

func _on_total_value_changed(value: float) -> void:
	total_ratio=value/100.0
	preview_sacrifice_result.emit(people_ratio,animal_ratio,garin_ratio,total_ratio)

func _on_people_value_changed(value: float) -> void:
	people_ratio=value/100.0
	preview_sacrifice_result.emit(people_ratio,animal_ratio,garin_ratio,total_ratio)

func _on_animal_value_changed(value: float) -> void:
	animal_ratio=value/100.0
	preview_sacrifice_result.emit(people_ratio,animal_ratio,garin_ratio,total_ratio)

func _on_grain_value_changed(value: float) -> void:
	garin_ratio=value/100.0
	preview_sacrifice_result.emit(people_ratio,animal_ratio,garin_ratio,total_ratio)
