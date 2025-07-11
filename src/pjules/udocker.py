import logging
from os import PathLike
import pathlib
import subprocess

log = logging.getLogger(__name__)


class InvalidPath(Exception):
    pass


class UdockerError(Exception):
    pass


class JulesUdockerRunner:
    """
    Run an existing JULES docker container using udocker.

    Parameters:
      container_name: name of an _existing_ JULES container.
      mount_point: an _absolute_ path in the container for mounting the run directory.

    Notes:
      List the containers udocker knows about using `udocker ps`
    """

    def __init__(
        self, container_name: str, mount_point: str | PathLike = "/root/run"
    ) -> None:
        # Check valid name (possibly overkill)
        try:
            subprocess.run(
                ["udocker", "inspect", container_name],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
                text=True,
                check=True,
            )
        except subprocess.CalledProcessError as exc:
            # If container doesn't exist, run
            subprocess.run(["udocker", "ps"])
            raise UdockerError(exc.stderr) from exc

        mount_point = pathlib.Path(mount_point)
        if not mount_point.is_absolute():
            raise InvalidPath("mount point must be an absolute path")

        self._container_name = container_name
        self._mount_point = mount_point

    @property
    def container_name(self) -> str:
        return self._container_name

    @property
    def mount_point(self) -> pathlib.Path:
        return self._mount_point

    def __str__(self) -> str:
        return f"{type(self).__name__}(container_name={self.container_name}, mount_point={self.mount_point})"

    def __call__(
        self, namelists_dir: str | PathLike, run_dir: str | PathLike | None = None
    ) -> None:
        """
        Run a containerised version of JULES.

        Args:
          namelists_dir: Path to the directory containing the namelists.
          run_dir: Path to the directory in which the jules executable will be run. This must be a parent of `namelists_dir`!
        """
        namelists_dir = pathlib.Path(namelists_dir).resolve()
        run_dir = namelists_dir if run_dir is None else pathlib.Path(run_dir).resolve()

        # We will mount `run_dir` to /root/run. Hence, `namelists_dir` must be a
        # subdirectory of `run_dir` or it will not be mounted.
        if not (namelists_dir.is_relative_to(run_dir)):
            msg = "`namelists_dir` must either be a subdirectory of `run_dir` or the same directory."
            raise InvalidPath(msg)

        subprocess.run(
            [
                "udocker",
                "run",
                "-v",
                f"{run_dir}:{self.mount_point}",
                self.container_name,
                "-d",
                self.mount_point,
                self.mount_point / namelists_dir.relative_to(run_dir),
            ],
        )
