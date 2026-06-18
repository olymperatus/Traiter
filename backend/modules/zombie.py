import os, signal, logging

log = logging.getLogger("assistant.zombie")

def guard(pid_file):
    pid_file = str(pid_file)
    if os.path.exists(pid_file):
        try:
            with open(pid_file) as f:
                old_pid = int(f.read().strip())
            os.kill(old_pid, signal.SIGTERM)
            log.warning("Killed zombie PID %s", old_pid)
        except (ProcessLookupError, ValueError):
            pass
        except Exception as e:
            log.error("Failed to kill zombie: %s", e)
        try:
            os.remove(pid_file)
        except OSError:
            pass
    with open(pid_file, "w") as f:
        f.write(str(os.getpid()))
    log.info("PID %s written to %s", os.getpid(), pid_file)

def cleanup(pid_file):
    try:
        if os.path.exists(pid_file):
            with open(pid_file) as f:
                if f.read().strip() == str(os.getpid()):
                    os.remove(pid_file)
    except OSError:
        pass
