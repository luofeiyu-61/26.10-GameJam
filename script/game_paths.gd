extends RefCounted
class_name GamePaths

#绿色版路径约定（2026-10-18）
#  · 编辑器里   → res://（工程目录，调试/策划改数值方便，和以前完全一致）
#  · 导出成 exe → exe 所在目录（不使用 user://，绝不往 C 盘写）
#
# 导出版解压后长这样：
#   GameJam/
#     GameJam.exe
#     GameJam.pck
#     saves/          ← 首次新建存档时自动创建
#     settings.cfg    ← 首次保存设置时创建
#
# 注意：绿色版必须放在非受保护目录（桌面 / D 盘 / E 盘…）。
#      放在 C:\Program Files 下会因为 UAC 没有写权限，存档会失败。

#游戏数据根目录（末尾带 /）
static func gameDir() -> String:
	if OS.has_feature("editor"):
		return "res://"
	return OS.get_executable_path().get_base_dir() + "/"


#存档目录（save_1.tres / save_2.tres ...）
static func saveDir() -> String:
	return gameDir() + "saves/"


#设置文件（音量、窗口大小等）
#编辑器里仍用 user://，避免在工程根目录多出一个 settings.cfg（也免得被打进导出包）
static func settingsFile() -> String:
	if OS.has_feature("editor"):
		return "user://settings.cfg"
	return gameDir() + "settings.cfg"
