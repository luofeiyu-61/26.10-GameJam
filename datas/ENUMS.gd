extends Node
class_name ENUMS

#region 事件卡片相关

enum TimeLength { Short=1 , Normal=2 , Long=3} #时间持续时间

enum TriggerType {Fixed=0,Condition=1,Random=2}

enum EventLevel {Common,Heavy,Story}

enum EventType {Good,Normal,Bad}

enum ResultType {Good,Normal,Bad }

enum MeetWhich {Air,Guy,Earth,People,Animal,Grain}

enum MeetType {MoreThan=1,LessThan=-1} #>= <=

#endregion

enum LunarPhase {
	NewMoon,			#新月
	WaxingCrescent,		#蛾眉月
	FirstQuarter,		#上弦月
	WaxingGibbous,		#盈凸月
	FullMoon,			#满月 
	WaningGibbous,		#亏凸月
	LastQuarter,		#下弦
	WaningCrescent,		#残月
	NONE
	}

enum SolarTerm {
	LiChun,YuShui,JingZhe,ChunFen,QingMing,GuYu,
	LiXia,XiaoMan,MangZhong,XiaZhi,XiaoShu,DaShu,
	LiQiu,ChuShu,BaiLu,QiuFen,HanLu,ShuangJiang,
	LiDong,XiaoXue,DaXue,DongZhi,XiaoHan,DaHan
	}

enum Gua { Kun,Gen,Kan,Xun,Zhen,Li,Dui,Qian,NONE }

enum Qi { Balance=0,PartYin=-1,PartYang=1,FullYin=-2,FullYang=2 }



static func gua2Binary(gua:ENUMS.Gua)->String:
	match gua:
		ENUMS.Gua.Kun:	return "000"
		ENUMS.Gua.Gen:	return "001"
		ENUMS.Gua.Kan:	return "010"
		ENUMS.Gua.Xun:	return "011"
		ENUMS.Gua.Zhen:	return "100"
		ENUMS.Gua.Li:	return "101"
		ENUMS.Gua.Dui:	return "110"
		ENUMS.Gua.Qian:	return "111"
		ENUMS.Gua.NONE:	return "none"
		_:return "UnknownGua"

static func gua2Text (gua:ENUMS.Gua)->String:
	match gua:
		ENUMS.Gua.Kun:	return "坤"
		ENUMS.Gua.Gen:	return "艮"
		ENUMS.Gua.Kan:	return "坎"
		ENUMS.Gua.Xun:	return "巽"
		ENUMS.Gua.Zhen:	return "震"
		ENUMS.Gua.Li:	return "离"
		ENUMS.Gua.Dui:	return "兑"
		ENUMS.Gua.Qian:	return "乾"
		ENUMS.Gua.NONE:	return "none"
		_:return "UnknownGua"


static func lunarPhase2Text(lunar_phase:ENUMS.LunarPhase)->String:
	match lunar_phase:
		ENUMS.LunarPhase.NewMoon:			return "新月"
		ENUMS.LunarPhase.WaxingCrescent:	return "蛾眉月"
		ENUMS.LunarPhase.FirstQuarter:		return "上弦月"
		ENUMS.LunarPhase.WaxingGibbous:		return "盈凸月"
		ENUMS.LunarPhase.FullMoon:			return "满月"
		ENUMS.LunarPhase.WaningGibbous:		return "亏凸月"
		ENUMS.LunarPhase.LastQuarter:		return "下弦"
		ENUMS.LunarPhase.WaningCrescent:	return "残月"
		ENUMS.LunarPhase.NONE:				return "none"
		_: return "UnknownLunarPhase"



static func solarTerm2Text(solar_term:ENUMS.SolarTerm)->String:
	match solar_term:
		ENUMS.SolarTerm.LiChun:			return "立春"
		ENUMS.SolarTerm.YuShui:			return "雨水"
		ENUMS.SolarTerm.JingZhe:		return "惊蛰"
		ENUMS.SolarTerm.ChunFen:		return "春分"
		ENUMS.SolarTerm.QingMing:		return "清明"
		ENUMS.SolarTerm.GuYu:			return "谷雨"
		ENUMS.SolarTerm.LiXia:			return "立夏"
		ENUMS.SolarTerm.XiaoMan:		return "小满"
		ENUMS.SolarTerm.MangZhong:		return "芒种"
		ENUMS.SolarTerm.XiaZhi:			return "夏至"
		ENUMS.SolarTerm.XiaoShu:		return "小暑"
		ENUMS.SolarTerm.DaShu:			return "大暑"
		ENUMS.SolarTerm.LiQiu:			return "立秋"
		ENUMS.SolarTerm.ChuShu:			return "处暑"
		ENUMS.SolarTerm.BaiLu:			return "白露"
		ENUMS.SolarTerm.QiuFen:			return "秋分"
		ENUMS.SolarTerm.HanLu:			return "寒露"
		ENUMS.SolarTerm.ShuangJiang:	return "霜降"
		ENUMS.SolarTerm.LiDong:			return "立冬"
		ENUMS.SolarTerm.XiaoXue:		return "小雪"
		ENUMS.SolarTerm.DaXue:			return "大雪"
		ENUMS.SolarTerm.DongZhi:		return "冬至"
		ENUMS.SolarTerm.XiaoHan:		return "小寒"
		ENUMS.SolarTerm.DaHan:			return "大寒"
		_: return "UnknownSoalrPhase"


static func qi2Text(spirit:ENUMS.Qi)->String:
	match spirit:
		ENUMS.Qi.Balance: return "平衡"
		ENUMS.Qi.PartYin: return "偏阴"
		ENUMS.Qi.PartYang: return "偏阳"
		ENUMS.Qi.FullYin: return "满阴"
		ENUMS.Qi.FullYang: return "满阳"
		_: return "UnknownQi"
