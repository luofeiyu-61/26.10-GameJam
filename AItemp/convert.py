from PIL import Image
import os

SRC = "E:/godot/ideatest/assets/charas/black"
DST = "E:/godot/ideatest/assets/charas/white"
os.makedirs(DST, exist_ok=True)

converted = []
for name in sorted(os.listdir(SRC)):
    if not name.lower().endswith(".png"):
        continue  # 只拷 png 素材；.import 由 Godot 重新生成
    src_path = os.path.join(SRC, name)
    im = Image.open(src_path).convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if r == 0 and g == 0 and b == 0:   # 黑色像素 -> 白色（保留 alpha）
                px[x, y] = (255, 255, 255, a)
    out_path = os.path.join(DST, name)
    im.save(out_path, "PNG")
    converted.append(name)

print("converted:", converted)

# ---- 校验 ----
print("\n=== verify white/ ===")
for name in converted:
    im = Image.open(os.path.join(DST, name)).convert("RGBA")
    cols = {}
    for p in im.get_flattened_data():
        cols[p] = cols.get(p, 0) + 1
    top = sorted(cols.items(), key=lambda kv: -kv[1])[:4]
    print(f"{name:12s} size={im.size} mode={im.mode} top={top}")
