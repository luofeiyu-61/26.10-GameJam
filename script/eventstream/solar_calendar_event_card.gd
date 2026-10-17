extends Control


@onready var event_name: Label = $ColorRect/title/event_name
@onready var good: Label = $ColorRect/yiji/good
@onready var bad: Label = $ColorRect/yiji/bad


func writeText(event:EventCard):
	event_name.text=event.display_name
	good.text="宜："
	for gua in event.result_good.meet_gua:
		good.text+=ENUMS.gua2Text(gua)+"、"
	good.text.trim_suffix("、")
	bad.text="忌："
	for gua in event.result_bad.meet_gua:
		bad.text+=ENUMS.gua2Text(gua)+"、"
	bad.text.trim_suffix("、")
