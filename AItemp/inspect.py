from PIL import Image
import os, collections

SRC = "E:/godot/ideatest/assets/charas/black"
for name in sorted(os.listdir(SRC)):
    if not name.lower().endswith(".png"):
        continue
    p = os.path.join(SRC, name)
    im = Image.open(p)
    mode = im.mode
    rgba = im.convert("RGBA")
    cols = collections.Counter(rgba.getdata())
    top = cols.most_common(8)
    # 统计：纯黑(RGB=0,0,0)不论alpha；及 alpha>0 的像素数
    black_count = sum(c for (r,g,b,a), c in cols.items() if r==0 and g==0 and b==0)
    opaque_count = sum(c for (r,g,b,a), c in cols.items() if a > 0)
    print(f"{name:12s} size={im.size} mode={mode} totalpx={im.size[0]*im.size[1]} opaque={opaque_count} pureBlack={black_count}")
    print("   top colors (r,g,b,a):count ->", top)
