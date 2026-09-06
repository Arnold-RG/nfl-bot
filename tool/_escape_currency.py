from pathlib import Path
import re

p = Path(r"c:\flutter_windows_3.29.3-stable\flutter\nfbot_app\lib\core\data\world_currencies.dart")
text = p.read_text(encoding="utf-8")

def fix(match: re.Match[str]) -> str:
    inner = match.group(1).replace(r"\$", "$").replace("$", r"\$")
    return f'symbol: "{inner}"'

text = re.sub(r'symbol: "([^"]*)"', fix, text)
p.write_text(text, encoding="utf-8")
print("escaped all $ in symbols")
