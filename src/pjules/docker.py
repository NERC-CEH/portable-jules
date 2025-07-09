from os import PathLike
import pathlib
import subprocess

def setup(image_file: str | PathLike, name: str = "JULES") -> None:
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
        ["udocker", "-D", "install", "--force"],
    )

    subprocess.run(
        ["udocker", "load", "-i", image_file, name],
    )

    subprocess.run(
        ["udocker", "verify", name],
    )

    subprocess.run(
        ["udocker", "create", f"--name={name.lower()}", name],
    )

    subprocess.run(
        ["udocker", "ps"],
    )

class InvalidPath(Exception):
    pass

class InvalidName(Exception):
    pass

def run(namelists_dir: str | PathLike, run_dir: str | PathLike | None = None, container: str = "jules") -> None:
    """
    Run a containerised version of JULES.

    Must run `pyjules.setup` first.

    Args:
      namelists_dir: Path to the directory containing the namelists.
      run_dir: Path to the directory in which the jules executable will be run.
               (Must be a parent of `namelists_dir`!)
      container: The name of the container to be run.
    """
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
        raise InvalidName(exc.stderr) from exc

    namelists_dir = pathlib.Path(namelists_dir).resolve()
    run_dir = namelists_dir if run_dir is None else pathlib.Path(run_dir).resolve()

    # We will mount `run_dir` to /root/run. Hence, `namelists_dir` must be a
    # subdirectory of `run_dir` or it will not be mounted.
    if not (namelists_dir.is_relative_to(run_dir)):
        msg = f"`namelists_dir` must either be a subdirectory of `run_dir` or the same directory."
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
            mount_point / namelists_dir.relative_to(run_dir)
        ],
    )
