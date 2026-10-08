extends Node
class_name ENUMS

#region 事件卡片相关

enum TimeLength {Short,Normal,Long}

enum TriggerType {Fixed=0,Condition=1,Random=2}

enum EventLevel {common,heavy,story}

enum EventType {Good,Bad}

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
	WaningCrescent		#残月
	}

enum SolarTerm {
	LiChun,YuShui,JingZhe,ChunFen,QingMing,GuYu,
	LiXia,XiaoMan,MangZhong,XiaZhi,XiaoShu,DaShu,
	LiQiu,ChuShu,BaiLu,QiuFen,HanLu,ShuangJiang,
	LiDong,XiaoXue,DaXue,DongZhi,XiaoHan,DaHan
	}

enum Gua { Kun,Gen,Kan,Xun,Zhen,Li,Dui,Qian }

enum Qi { Balance=0,PartYin=-1,PartYang=1,FullYin=-2,FullYang=2 }
