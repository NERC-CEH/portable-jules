import os
from os import PathLike
import pathlib
import shutil
import subprocess

class InvalidExecutable(Exception):
    pass

class InvalidPath(Exception):
    pass

class InvalidName(Exception):
    pass

def run(namelists_dir: str | PathLike, run_dir: str | PathLike | None = None, jules_exe: str | PathLike | None = None) -> None:
    """
    Runs a JULES binary executable in a shell subprocess.

    Args:
      namelists_dir: Path to the directory containing the namelists.
      run_dir: Path to the directory in which the jules executable will be run.
               (Must be a parent of `namelists_dir`!)
      jules_exe: Path to a jules executable.
    """
    if jules_exe is not None:
        jules_exe = pathlib.Path(jules_exe).resolve()
        if not jules_exe.is_file():
            raise FileNotFoundError(f"Provided path '{jules_exe}' is not a file")
        if not os.access(jules_exe, os.X_OK):
            raise PermissionError(f"Provided file '{jules_exe}' is not executable")
    else:
        jules_exe = shutil.which("jules.exe")
        if jules_exe is None:
            raise Exception("jules.exe was not found in PATH")

    namelists_dir = pathlib.Path(namelists_dir).resolve()
    run_dir = namelists_dir if run_dir is None else pathlib.Path(run_dir).resolve()

    # We will mount `run_dir` to /root/run. Hence, `namelists_dir` must be a
    # subdirectory of `run_dir` or it will not be mounted.
    if not (namelists_dir.is_relative_to(run_dir)):
        msg = f"`namelists_dir` must either be a subdirectory of `run_dir` or the same directory."
        raise InvalidPath(msg)

    with switch_dir(run_dir):
        subprocess.run(
            [
                jules_exe,
                namelists_dir.relative_to(run_dir),
            ]
        )
