import logging
from os import PathLike
import pathlib
import subprocess
from typing import Self

log = logging.getLogger(__name__)

class InvalidPath(Exception):
    pass


class InvalidName(Exception):
    pass


def create_image(image_file: str | PathLike, image_name: str = "JULES") -> None:
    """
    Perform a one-time setup for running dockerised JULES.

    This function goes through the following steps:

    1. `udocker install` to set up udocker.
    2. `udocker load` to load an image from `image_file`.
    3. `udocker verify` to check the loaded image isn't corrupted.

    Args:
      image_file: A `.tar` containing the image, created using `docker save`.
      name: A name for the image.
    """
    # NOTE: could use udocker python API directly
    # TODO: handle stdout/stderr
    subprocess.run(
        ["udocker", "load", "-i", image_file, image_name],
    )
    subprocess.run(
        ["udocker", "verify", name],
    )


def create_container(image_name: str, container_name: str) -> None:
    subprocess.run(
        ["udocker", "create", f"--name={name.lower()}", name],
    )
    # If image not available, print
    subprocess.run(
        ["udocker", "images"]
    )



class JulesUdockerRunner:
    def __init__(self, container_name: str) -> None:
        # Check valid name (possibly overkill)
        try:
            subprocess.run(
                ["udocker", "inspect", container],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
                text=True,
                check=True,
            )
        except subprocess.CalledProcessError as exc:
            # If container doesn't exist, run
            subprocess.run(
                ["udocker", "ps"],
            )
            raise InvalidName(exc.stderr) from exc

        self._container_name = container_name

    @property
    def container_name(self) -> str:
        return self._container_name

    def __str__(self) -> str:
        return f"{type(self).__name__}(container_name = {self.container_name})"

    def __call__(self, namelists_dir: str | PathLike, run_dir: str | PathLike | None = None) -> None:
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

        # This is where the cwd will end up in the container filesystem
        mount_point = pathlib.Path("/root/run")

        subprocess.run(
            [
                "udocker",
                "run",
                "-v",
                f"{run_dir}:{mount_point}",
                container,
                "bash",
                "jules.sh",
                "-d",
                mount_point,
                mount_point / namelists_dir.relative_to(run_dir),
            ],
        )

    def teardown(self) -> None:
        # delete container





def run(
    namelists_dir: str | PathLike,
    run_dir: str | PathLike | None = None,
    container: str = "jules",
) -> None:
