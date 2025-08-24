import logging
import subprocess
import sys

logging.basicConfig(level=logging.INFO)

revset = sys.argv[1]


def run(cmd):
    """Run a shell command and return stdout as text."""
    return subprocess.check_output(cmd, text=True).strip()


JJ_GET_COMMIT_CMD = [
    "jj",
    "log",
    "-r",
    revset,
    "-T",
    'commit_id.short()++"\n"',
    "--no-graph",
    "--reversed",
]

BENCH_GEN_CMD = ["zig", "build", "gen-bench-encode"]

commit_ids = run(JJ_GET_COMMIT_CMD).splitlines()

logging.info("Commits that will be processed:")
for cid in commit_ids:
    logging.info(cid)

for cid in commit_ids:
    run(["jj", "new", cid])
    run(BENCH_GEN_CMD)
    run(
        [
            "mv",
            "zig-out/bin/bench-encode-random-uuids",
            f"zig-out/bin/bench-encode-random-uuids-{cid}",
        ]
    )

msg = ""
msg += "The following command can give you the incremental benchmarks:\n\n"

msg += "sudo poop \\\n"
for cid in commit_ids:
    msg += f"\tzig-out/bin/benchmark_random_uuids-{cid} \\\n"

print(msg)
