from PIL import Image

# 预览：把 white/charas.png 的白色剪影放到深色底上，便于肉眼确认
fg = Image.open("E:/godot/ideatest/assets/charas/white/charas.png").convert("RGBA")
bg = Image.new("RGBA", fg.size, (40, 42, 64, 255))
out = Image.alpha_composite(bg, fg)
out.save("E:/godot/ideatest/AItemp/preview_charas.png", "PNG")
print("preview saved", out.size)

# 确认 black/ 原图未被改动（仍应为纯黑 (0,0,0,255) 形状）
im = Image.open("E:/godot/ideatest/assets/charas/black/charas.png").convert("RGBA")
cols = {}
for p in im.get_flattened_data():
    cols[p] = cols.get(p, 0) + 1
print("black/charas still:", sorted(cols.items(), key=lambda kv: -kv[1])[:3])
