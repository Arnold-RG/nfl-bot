from pathlib import Path

p = Path(r"c:\flutter_windows_3.29.3-stable\flutter\nfbot_app\tool\gen_world_data.py")
lines = p.read_text(encoding="utf-8").splitlines()
out = []
for line in lines:
    if '"oj"' in line and "Occitan" in line:
        out.append(
            '    ("ny", "Chichewa", "Chichewa"), ("oc", "Occitan", "Occitan"), ("oj", "Ojibwa", "Ojibwe"),'
        )
    else:
        out.append(line)
p.write_text("\n".join(out) + "\n", encoding="utf-8")
print("fixed")
