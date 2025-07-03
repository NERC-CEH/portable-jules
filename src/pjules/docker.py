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
        ["udocker", "-D", "install"],
    )

    subprocess.run(
        ["udocker", "--allow-root", "load", "-i", image_file, name],
    )

    subprocess.run(
        ["udocker", "verify", name],
    )

class InvalidPath(Exception):
    pass

class InvalidName(Exception):
    pass

def run(run_dir: str | PathLike, namelists_dir: str | PathLike | None = None, container_name: str = "JULES") -> None:
    """
    Run a containerised version of JULES.

    Must run `pyjules.setup` first.

    Args:
      run_dir: Path to the directory in which the jules executable will be run.
      namelists_dir: Path to the directory containing the namelists.
      container_name: The name of the container to be run.
    """
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
        raise InvalidName(exc.stderr) from exc

    cwd = pathlib.Path.cwd()
    run_dir = pathlib.Path(run_dir).resolve()
    namelists_dir = run_dir if namelists_dir is None else pathlib.Path(namelists_dir).resolve()

    # We will mount the cwd when running the container. Hence, run_dir and
    # namelists_dir must be subdirectories of cwd!
    if not (run_dir.is_relative_to(cwd) and namelists_dir.is_relative_to(cwd)):
        msg = f"Both `run_dir` and `namelists_dir` must be subdirectories of the current working directory, {cwd}!"
        raise InvalidPath(msg)
    
    run_dir = run_dir.relative_to(cwd)
    namelists_dir = namelists_dir.relative_to(cwd)

    # This is where the cwd will end up in the container filesystem
    mount_point = pathlib.Path("/run")

    subprocess.run(
        [
            "udocker",
            "run",
            "-v",
            f"{cwd}:{mount_point}",
            container_name,
            "-d",
            mount_point / run_dir,
            mount_point / namelists_dir
        ],
    )
