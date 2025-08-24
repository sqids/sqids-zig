import datetime
import pathlib
import random
import uuid

rd = random.Random()
rd.seed(0xF00DBABE)

N = 1000
ids = [uuid.UUID(int=rd.getrandbits(128), version=4) for _ in range(N)]

numbers = []
for id in ids:
    ns = [int(x, 16) for x in str(id).split("-")]
    numbers.append(ns)

content = ""
content += f"// generated {datetime.datetime.now(tz=datetime.timezone.utc)}\n\n"
content += "pub const numbers = [_][5]u64{\n"

for ns in numbers:
    content += "    .{ " + ", ".join(str(n) for n in ns) + " },\n"
content += "};\n"

pathlib.Path("numbers.zig").write_text(content)
