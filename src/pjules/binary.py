import logging
import os
from os import PathLike
import pathlib
import shutil
import subprocess

from .utils import switch_dir

log = logging.getLogger(__name__)


class JulesRuntimeError(Exception):
    pass


class JulesExeRunner:
    """
    Run a JULES binary executable in a shell subprocess.

    Parameters:
      jules_exe: Path to a jules executable.
    """

    def __init__(self, jules_exe: str | PathLike | None = None) -> None:
        # If path to executable provided, check it exists, is a file, and is executable
        if jules_exe is not None:
            jules_exe = pathlib.Path(jules_exe).resolve()
            if not jules_exe.is_file():
                raise FileNotFoundError(f"Provided path '{jules_exe}' is not a file")
            if not os.access(jules_exe, os.X_OK):
                raise PermissionError(f"Provided file '{jules_exe}' is not executable")

        # If path to executable not provided, attempt to locate it in $PATH
        else:
            jules_exe = shutil.which("jules.exe")
            if jules_exe is None:
                raise FileNotFoundError(
                    "Jules executable `jules.exe` was not found in PATH"
                )
            jules_exe = pathlib.Path(jules_exe).resolve()

        self._jules_exe = jules_exe

    @property
    def jules_exe(self) -> pathlib.Path:
        return self._jules_exe

    def __str__(self) -> str:
        return f"{type(self).__name__}(jules_exe={self.jules_exe})"

    def __call__(
        self, namelists_dir: str | PathLike, run_dir: str | PathLike | None = None
    ) -> None:
        """
        Run the JULES binary.

        Args:
          namelists_dir: Path to the directory containing the namelists.
          run_dir: Path to the directory in which the jules executable will be run.
        """
        namelists_dir = pathlib.Path(namelists_dir).resolve()
        run_dir = namelists_dir if run_dir is None else pathlib.Path(run_dir).resolve()

        # TODO: read output namelist and automatically create output directory
        # See jules_pytk.run

        with switch_dir(run_dir, verbose=True):
            stdout_file = "stdout.log"
            stderr_file = "stderr.log"

            log.info("Logging to %s and %s" % (stdout_file, stderr_file))

            with open(stdout_file, "w") as outfile, open(stderr_file, "w") as errfile:
                log.info("Running %s %s" % (self.jules_exe, namelists_dir))

                try:
                    subprocess.run(
                        args=[self.jules_exe, namelists_dir],
                        stdout=outfile,
                        stderr=errfile,
                        text=True,
                        check=True,
                    )

                except subprocess.CalledProcessError as exc:
                    log.error(
                        "An error was thrown by the subprocess. Reading details from %s."
                        % stderr_file
                    )
                    errfile_contents = errfile.read()
                    raise JulesRuntimeError(errfile_contents) from exc
