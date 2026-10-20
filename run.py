import argparse
import os
import signal
import time
from pathlib import Path
import subprocess
import sys

from app import create_app

app = create_app()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run the Agent Safety preview server.")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--background", action="store_true", help="Run independently of the terminal; write logs to logs/server.log.")
    mode.add_argument("--restart", action="store_true", help="Restart the recorded background server.")
    args = parser.parse_args()
    if args.background or args.restart:
        root = Path(__file__).resolve().parent
        log_dir = root / "logs"
        log_dir.mkdir(exist_ok=True)
        if args.restart and (log_dir / "server.pid").exists():
            pid = int((log_dir / "server.pid").read_text().strip())
            process_path = Path("/proc/{}/cmdline".format(pid))
            if process_path.exists():
                command = process_path.read_bytes().split(b"\x00")
                if os.fsencode(str(root / "run.py")) not in command:
                    raise SystemExit("Recorded PID does not belong to this server; refusing to stop it.")
                os.kill(pid, signal.SIGTERM)
                for _ in range(30):
                    status = Path("/proc/{}/stat".format(pid))
                    if not status.exists() or status.read_text().split(")", 1)[1].strip().startswith("Z"):
                        break
                    time.sleep(0.1)
        with (log_dir / "server.log").open("a", encoding="utf-8") as log:
            process = subprocess.Popen(
                [sys.executable, "-u", str(root / "run.py")],
                cwd=str(root),
                stdin=subprocess.DEVNULL,
                stdout=log,
                stderr=subprocess.STDOUT,
                start_new_session=True,
            )
        try:
            exit_code = process.wait(timeout=0.5)
        except subprocess.TimeoutExpired:
            pass
        else:
            raise SystemExit("Server exited with code {}. See logs/server.log.".format(exit_code))
        (log_dir / "server.pid").write_text(str(process.pid) + "\n", encoding="utf-8")
        print("Started background server PID {}. Log: {}".format(process.pid, log_dir / "server.log"))
    else:
        app.run(
            host=os.environ.get("HOST", "0.0.0.0"),
            port=int(os.environ.get("PORT", "6700")),
            debug=False,
        )
